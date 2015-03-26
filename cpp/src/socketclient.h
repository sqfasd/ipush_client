#ifndef SRC_SOCKETCLIENT_H_
#define SRC_SOCKETCLIENT_H_

#include <string>
#include <functional>
#include <atomic>
#include <string>
#include <thread>
#include <memory>
#include "blocking_queue.h"
#include "deps/jsoncpp/include/json/json.h"

namespace xcomet {

struct ClientOption {
  std::string host;
  int port;
  std::string username;
  std::string password;
  int keepalive_interval;
};

class Packet {
 public:
  Packet();
  ~Packet();
  int Read(int fd);
  int Write(int fd);
  bool HasReadAll() const {
    return content_.size() == len_;
  }
  void SetContent(std::string str) {
    content_.swap(str);
    len_ = content_.size();
  }
  int Size() const {
    return len_;
  }
  const std::string& Content() const {
    return content_;
  }
  void Reset() {
    len_ = 0;
    left_ = 0;
    content_.clear();
  }

 private:
  int ReadDataLen(int fd);

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

  void SetKeepaliveInterval(int interval_sec) {
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
  void Loop();
  bool HandleRead();
  bool HandleWrite();
  void Notify();
  void SendJson(const Json::Value& value);
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
