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

#include "deps/jsoncpp/include/json/json.h"
#include "logging.h"

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
    ret = ::read(sock_fd_, p, 1);
    total++;
    p++;
  } while (ret == 1 && *p != '\r' && total < MAX_DATA_LEN);
  if (ret != 1) {
    return ret;
  } else if (total < MAX_DATA_LEN) {
    return -2;
  } else {
    ret = ::read(sock_fd_, p, 1);
    if (ret != 1) {
      return ret;
    } else {
      return ::atoi(buf);
    }
  }
}

int Packet::Read(int fd) {
  int n;
  if (left_ == 0) {
    n = ReadDataLen();
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
    int max_read_len = left_len_ > BUFFER_LEN ? BUFFER_LEN : left_len_;
    n = ::read(fd, buf, max_read_len);
    if (n > 0) {
      len_ -= n;
      content_.append(buf, n);
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
  int n = ::snprintf(buf, MAX_DATA_LEN, "%x\r\n", content_.size());
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
      current_read_packet_(new Packet()) {
  CHECK(::socketpair(AF_UNIX, SOCK_STREAM, 0, pipe_) == 0);
  SetNonblock(pipe_[1]);
}

SocketClient::~SocketClient() {
  Close();
  ::close(pipe_[0]);
  ::close(pipe_[1]);
}

int SocketClient::Connect() {
  worker_thread_ = std::thread(&SocketClient::WorkerThread, this);
  return OK;
}

void SocketClient::WorkerThread() {
  string ip;
  if (IsIp(option_.host)) {
    ip = option_.host;
  } else {
    if (!GetHostIp(option_.host, ip)) {
      error_cb_(E_INVALID_HOST);
      return;
    }
  }
  sock_fd_ = ::socket(AF_INET, SOCKET_STREAM, 0);
  if (p_->sock_fd_== -1) {
    error_cb_(E_SOCKET);
    return;
  }
  
  struct sockaddr_in server_addr;
  ::memset(&server_addr, 0, sizeof(server_addr));
  server_addr.sin_family = AF_INET;
  server_addr.sin_addr.s_addr = ::inet_addr(ip.c_str());
  server_addr.sin_port = ::htons(option_.port);
  if (::connect(sock_fd_,
                (struct sockaddr*)&server_addr,
                sizeof(struct sockaddr)) == -1) {
    error_cb_(E_CONNECT);
    return;
  }
  char buffer[1024] = {0};
  int size = ::snprintf(
      buffer,
      "GET /sub?seq=-1&username=%s&password=%s HTTP/1.1\r\n"
      "User-Agent: mobile_socket_client/0.1.0\r\n"
      "Accept: */*\r\n"
      "\r\n",
      option_.user_name.c_str(),
      option_.password.c_str(),
      sizeof(http_header));
  if (::send(sock_fd_, http_header, size, 0) < 0) {
    error_cb_(E_SEND_HTTP_HEADER);
    return;
  }
  ::memset(buffer, 0, sizeof(buffer));
  if (::recv(sock_fd_, buffer, sizeof(buffer), 0) < 0) {
    error_cb_(E_RECV);
    return;
  }
  if (::strstr(buffer, "HTTP/1.1 200") == NULL) {
    error_cb_(E_CONNECT_FAILED);
    return;
  }

  SetNonblock(sock_fd_);
  is_connected_ = true;
  connect_cb_();

  while (is_connected_) {
    struct pollfd pfds[2];
    pfds[0].fd = sock_fd_;
    pfds[0].revents = 0;
    pfds[0].events = POLLIN | POLLPRI;
    if (!write_queue_.empty()) {
      pfds[0].events |= POLLOUT;
    }
    pfds[1].fd = pipe_[1];
    pfds[1].revents = 0;
    pfds[1].events = POLLIN;

    static const int ONE_SECOND = 1000;
    static const int TIMEOUT_MS = 30 * ONE_SECOND;
    int ret = ::poll(pfds, 2, TIMEOUT_MS);
    if (ret == 0) {
      // no events
      // SendHeartBeat();
    } else if (ret > 0) {
      // events come
      if (pfds[0].revents & POLLIN) {
        HandleRead();
      }
      if (pfds[0].revents & POLLOUT) {
        HandleWrite();
      }
      if (pfds[1].revents & POLLIN) {
        LOG(INFO) << "pipe notify received";
        char c;
        while (::read(sock_fd_, &c, 1) == 1);
      }
    } else {
      // handle error
      error_cb_(1);
      Close();
    }
  }

  // clean work
  CHECK(is_connected_ == false);
  ::shutdown(sock_fd_, SHUT_RDWR);
  write_queue_.Clear();
  disconnect_cb_();
}

void SocketClient::HandleRead() {
  // CHECK sock_fd_
  int ret = current_read_packet_->Read(sock_fd_);
  if (ret == 0) {
    Close();
    return;
  } else if (current_read_packet_->HasReadAll()) {
    Json::Reader reader;
    Json::Value json;
    try {
      reader.parse(current_read_packet_->Content(), json);
    } catch (std::exception e) {
      error_cb_(E_RECV_JSON_FORMAT);
      Close();
      return;
    }
    // CHECK(json.isMember("content") &&
    //       json.isMember("topic") &&
    //       json.isMember("to") &&
    //       json["to"] == option_.user_name);
    message_cb_(json["content"]);
    current_read_packet_->Reset();
  }
}

void SocketClient::HandleWrite() {
  while (!write_queue_.empty()) {
    PacketPtr pkt;
    write_queue_.Pop(pkt);
    int ret = pkt->Write(sock_fd_);
    if (ret != pkt->Size()) {
      // TODO deal with uncomplete write, wirte left bytes next time
    }
  }
}

int SocketClient::Publish(const string& topic, const string& message) {
  Json::Value json;
  json["seq"] = 0;
  json["sender"] = option_.user_name;
  json["topic"] = topic;
  json["content"] = message;
  PacketPtr packet(new Packet());
  Json::FastWriter writer;
  packet->SetContent(writer.write(json));
  write_queue_.Push(packet);

  Notify();
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

}
