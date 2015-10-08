#ifndef SRC_SOCKETCLIENT_H_
#define SRC_SOCKETCLIENT_H_

#include <iostream>
#include <string>
#include <functional>
#include <atomic>
#include <string>
#include <thread>
#include <memory>
#include "blocking_queue.h"
#include "message.h"

namespace xcomet {

struct ClientOption {
  std::string host;
  int port;
  std::string username;
  std::string password;
};

inline ostream& operator<<(ostream& os, const ClientOption& co) {
  os << "ClientOption(host: " << co.host << ","
     << "port: " << co.port << ","
     << "username: " << co.username << ","
     << "password: " << co.password;
  return os;
}

const int MAX_BUFFER_SIZE = 1024;

class BufferReader {
 public:
  BufferReader();
  ~BufferReader();
  int Read(int fd, char* addr, int len);
  int ReadLine(int fd, char* addr);
  int Size() {return end_ - start_;}
  void AddToBuffer(const char* ptr, int len);

 private:
  int Read(int fd);
  void Shrink();
  int FindCRLF();
  char buf_[MAX_BUFFER_SIZE];
  int start_;
  int end_;
};

class Packet {
 public:
  Packet();
  ~Packet();
  int Read(int fd);
  int Write(int fd);
  void SetContent(std::string& str) {
    content_.swap(str);
    content_.append("\r\n");
    len_ = content_.size();
  }
  int Size() const {
    return len_;
  }
  std::string& Content() {
    return content_;
  }
  void Reset() {
    len_ = 0;
    left_ = 0;
    content_.clear();
    state_ = NONE;
    ::memset(data_len_buf_, 0, sizeof(data_len_buf_));
    buf_start_ = 0;
    rstate_ = RS_HEADER;
  }
  void AddToBuffer(const char* ptr, int len) {
    reader_.AddToBuffer(ptr, len);
  }

 private:
  int ReadDataLen(int fd);

  enum ReadState {
    RS_HEADER,
    RS_BODY,
  } rstate_;
  BufferReader reader_;

  int len_;
  int left_;
  // int type_;
  std::string content_;
  enum WriteState {
    NONE,
    DATA_LEN,
    DATA_BODY,
  };
  WriteState state_;
  static const int MAX_DATA_LEN = 20;
  char data_len_buf_[MAX_DATA_LEN];
  int buf_start_;
};

typedef std::function<void ()> ConnectCallback;
typedef std::function<void ()> DisconnectCallback;
typedef std::function<void (const std::string&)> MessageCallback;
typedef std::function<void (const std::string&)> ErrorCallback;

class SocketClient : public NonCopyable {
 public:
  SocketClient(const ClientOption& option);
  ~SocketClient();

  void SetConnectCallback(const ConnectCallback& cb) {
    connect_cb_ = cb;
  }
  void SetDisconnectCallback(const DisconnectCallback& cb) {
    disconnect_cb_ = cb;
  }
  void SetMessageCallback(const MessageCallback& cb) {
    message_cb_ = cb;
  }
  void SetErrorCallback(const ErrorCallback& cb) {
    error_cb_ = cb;
  }

  void SetHost(const std::string& host) {
    option_.host = host;
  }

  void SetPort(int port) {
    option_.port = port;
  }

  void SetUserName(const std::string& username) {
    option_.username = username;
  }

  void SetPassword(const std::string& password) {
    option_.password = password;
  }

  void SetKeepAliveIntervalSec(int interval_sec) {
    keepalive_interval_sec_ = interval_sec;
  }

  int Connect();
  int Subscribe(const std::string& channel);
  int Unsubscribe(const std::string& channel);
  int Publish(const std::string& channel, const std::string& message);
  int Send(const std::string& to, const std::string& message);
  void Close();
  void WaitForClose();
  bool isConnected() {
    return is_connected_;
  }

 private:
  void Reconnect();
  void Loop();
  bool HandleRead();
  bool HandleWrite();
  void Notify();
  void SendMessage(const Message& msg);
  int SendHeartbeat();
  int SendAck();

  int sock_fd_;
  std::thread worker_thread_;
  ClientOption option_;
  std::atomic<bool> is_connected_;

  ConnectCallback connect_cb_;
  DisconnectCallback disconnect_cb_;
  MessageCallback message_cb_;
  ErrorCallback error_cb_;

  typedef std::shared_ptr<Packet> PacketPtr;
  BlockingQueue<PacketPtr> write_queue_;
  PacketPtr current_read_packet_;

  int pipe_[2];
  int keepalive_interval_sec_;
  int last_seq_;
};
}

#endif  // SRC_SOCKETCLIENT_H_
