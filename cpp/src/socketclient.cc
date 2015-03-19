#include "socketclient.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "basictypes.h"
#include "logging.h"
#include "util.h"

using std::string;

const int DEFAULT_KEEPALIVE_INTERVAL_SEC = 28 * 60L;

#define CERROR(msg) string(msg) + ": " + ::strerror(errno)

namespace xcomet {

static const int MAX_DATA_LEN = 20;

Packet::Packet()
    : len_(0), left_(0) {
}

Packet::~Packet() {
}

int Packet::ReadDataLen(int fd) {
  char buf[MAX_DATA_LEN] = {0};
  char* p = buf;
  int ret;
  int total = 0;
  do {
    ret = ::read(fd, p, 1);
    total++;
  } while (ret == 1 && *p++ != '\r' && total < MAX_DATA_LEN);
  if (ret != 1) {
    return ret;
  } else if (total >= MAX_DATA_LEN) {
    return -2;
  } else {
    ret = ::read(fd, p, 1);
    if (ret != 1) {
      return ret;
    } else {
      // 2 is crlf '\r\n'
      return ::strtol(buf, NULL, 16) + 2;
    }
  }
}

int Packet::Read(int fd) {
  int n;
  if (left_ == 0) {
    n = ReadDataLen(fd);
    if (n <= 0) {
      return n;
    }
    len_ = n;
    left_ = len_;
  }

  static const int BUFFER_LEN = 1024;
  char buf[BUFFER_LEN] = {0};
  int total = 0;
  do {
    int max_read_len = left_ > BUFFER_LEN ? BUFFER_LEN : left_;
    n = ::read(fd, buf, max_read_len);
    if (n > 0) {
      content_.append(buf, n);
      left_ -= n;
      total += n;
    }
  } while (n > 0 && left_ > 0);
  if (n <= 0) {
    return n;
  }
  return total;
}

int Packet::Write(int fd) {
  CHECK(len_ > 0);
  char buf[MAX_DATA_LEN] = {0};
  int n = ::snprintf(buf, MAX_DATA_LEN, "%x\r\n", (uint32)content_.size());
  CHECK(n < MAX_DATA_LEN + 2);
  int ret = ::write(fd, buf, n);
  CHECK(ret == n);
  ret = ::write(fd, content_.c_str(), content_.size());
  return ret;
}

SocketClient::SocketClient(const ClientOption option)
    : sock_fd_(-1),
      option_(option),
      is_connected_(false),
      current_read_packet_(new Packet()),
      keepalive_interval_sec_(DEFAULT_KEEPALIVE_INTERVAL_SEC) {
  CHECK(::socketpair(AF_UNIX, SOCK_STREAM, 0, pipe_) == 0);
  SetNonblock(pipe_[1]);
}

SocketClient::~SocketClient() {
  WaitForClose();
  ::close(pipe_[0]);
  ::close(pipe_[1]);
}

int SocketClient::Connect() {
  if (option_.host.empty() ||
      option_.port <= 0 ||
      option_.username.empty() ||
      option_.password.empty()) {
    LOG(ERROR) << "invalid client option";
    return -1;
  }

  string ip;
  if (IsIp(option_.host)) {
    ip = option_.host;
  } else {
    if (!GetHostIp(option_.host, ip)) {
      LOG(ERROR) << "invalid host";
      return -2;
    }
  }
  sock_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
  if (sock_fd_== -1) {
    LOG(ERROR) << CERROR("socket error");
    return -3;
  }

  char buffer[1024] = {0};
  struct sockaddr_in server_addr;
  ::memset(&server_addr, 0, sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = ::inet_addr(ip.c_str());
  server_addr.sin_port = htons(option_.port);

  if (::connect(sock_fd_,
                (struct sockaddr*)&server_addr,
                sizeof(struct sockaddr)) == -1) {
    LOG(ERROR) << CERROR("connect error");
    return -4;
  }
  int size = ::snprintf(
      buffer,
      sizeof(buffer),
      "GET /connect?seq=-1&uid=%s&password=%s HTTP/1.1\r\n"
      "User-Agent: mobile_socket_client/0.1.0\r\n"
      "Accept: */*\r\n"
      "\r\n",
      option_.username.c_str(),
      option_.password.c_str());
  if (::send(sock_fd_, buffer, size, 0) < 0) {
    LOG(ERROR) << CERROR("send error");
    return -5;
  }
  ::memset(buffer, 0, sizeof(buffer));
  if (::recv(sock_fd_, buffer, sizeof(buffer), 0) < 0) {
    LOG(ERROR) << CERROR("receive error");
    return -6;
  }
  if (::strstr(buffer, "HTTP/1.1 200") == NULL) {
    LOG(INFO) << (string("connect failed: ") + buffer);
    return -7;
  }

  SetNonblock(sock_fd_);
  
  if (worker_thread_.joinable()) {
    LOG(INFO) << "join previous worker thread";
    worker_thread_.join();
  }
  worker_thread_ = std::thread(&SocketClient::Loop, this);
  return 0;
}

void SocketClient::Loop() {
  is_connected_ = true;
  connect_cb_();
  while (is_connected_) {
    struct pollfd pfds[2];
    pfds[0].fd = sock_fd_;
    pfds[0].revents = 0;
    pfds[0].events = POLLIN | POLLPRI;
    if (!write_queue_.Empty()) {
      pfds[0].events |= POLLOUT;
    }
    pfds[1].fd = pipe_[1];
    pfds[1].revents = 0;
    pfds[1].events = POLLIN;

    CHECK(keepalive_interval_sec_ >= 1) << "keepalive less than 30s";
    static const int ONE_SECOND = 1000;
    int timeout_ms = keepalive_interval_sec_ * ONE_SECOND;
    int ret = ::poll(pfds, 2, timeout_ms);
    if (ret == 0) {
      // no events
      SendHeartbeat();
    } else if (ret > 0) {
      // events come
      if (pfds[0].revents & POLLIN) {
        if (!HandleRead()) {
          break;
        }
      }
      if (pfds[0].revents & POLLOUT) {
        if (!HandleWrite()) {
          break;
        }
      }
      if (pfds[1].revents & POLLIN) {
        VLOG(2) << "pipe notify received";
        char c;
        while (::read(sock_fd_, &c, 1) == 1);
      }
    } else {
      // handle error
      error_cb_(CERROR("poll error"));
      break;
    }
  }

  is_connected_ = false;
  LOG(INFO) << "will clean and exit";
  ::shutdown(sock_fd_, SHUT_RDWR);
  write_queue_.Clear();
  disconnect_cb_();
  LOG(INFO) << "work thread exited";
}

bool SocketClient::HandleRead() {
  // CHECK sock_fd_
  int ret = current_read_packet_->Read(sock_fd_);
  if (ret == 0) {
    LOG(ERROR) << "read nothing";
    return false;
  } else if (current_read_packet_->HasReadAll()) {
    // Json::Reader reader;
    // Json::Value json;
    // try {
    //   reader.parse(current_read_packet_->Content(), json);
    // } catch (std::exception e) {
    //   LOG(ERROR) << (string("json format error: ") + e.what());
    //   return false;
    // }
    // CHECK(json.isMember("content") &&
    //       json.isMember("topic") &&
    //       json.isMember("to") &&
    //       json["to"] == option_.username);
    message_cb_(current_read_packet_->Content());
    current_read_packet_->Reset();
  }
  return true;
}

bool SocketClient::HandleWrite() {
  while (!write_queue_.Empty()) {
    PacketPtr pkt;
    write_queue_.Pop(pkt);
    int ret = pkt->Write(sock_fd_);
    if (ret != pkt->Size()) {
      // TODO deal with uncomplete write, wirte left bytes next time
      LOG(INFO) << "write size error: " << ret;
      return false;
    }
  }
  return true;
}

int SocketClient::Publish(const string& channel, const string& message) {
  Json::Value json;
  json["seq"] = 0;
  // json["from"] = option_.username;
  json["to"] = channel;
  json["type"] = "channel";
  json["content"] = message;
  SendJson(json);
  return 0;
}

void SocketClient::Notify() {
  // notify through socket pipe
  static const char PIPE_DATA = '0';
  ::send(pipe_[0], &PIPE_DATA, 1, 0);
}

void SocketClient::Close() {
  is_connected_ = false;
  Notify();
}

void SocketClient::WaitForClose() {
  if (is_connected_) {
    Close();
  }
  if (worker_thread_.joinable()) {
    worker_thread_.join();
  }
}

int SocketClient::Subscribe(const std::string& channel) {
  Json::Value json;
  // json["uid"] = option_.username;
  json["channel_id"] = channel;
  json["type"] = "sub";
  SendJson(json);
  return 0;
}

int SocketClient::Unsubscribe(const std::string& channel) {
  Json::Value json;
  // json["uid"] = option_.username;
  json["channel_id"] = channel;
  json["type"] = "unsub";
  SendJson(json);
  return 0;
}

int SocketClient::Send(const std::string& user, const std::string& message) {
  Json::Value json;
  // json["from"] = option_.username;
  json["to"] = user;
  json["type"] = "send";
  json["content"] = message;
  SendJson(json);
  return 0;
}

int SocketClient::SendHeartbeat() {
  LOG(INFO) << "SendHeartbeat";
  Json::Value json;
  json["type"] = "noop";
  
  PacketPtr packet(new Packet());
  Json::FastWriter writer;
  packet->SetContent(writer.write(json));
  write_queue_.Push(packet);
  HandleWrite();
  return 0;
}

void SocketClient::SendJson(const Json::Value& json) {
  PacketPtr packet(new Packet());
  Json::FastWriter writer;
  packet->SetContent(writer.write(json));
  write_queue_.Push(packet);

  Notify();
}

}
