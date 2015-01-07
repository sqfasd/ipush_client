#ifndef SRC_SOCKETCLIENT_H_
#define SRC_SOCKETCLIENT_H_

#include <string>
#include <functional>
#include <atomic>
#include <string>
#include <thread>
#include <memory>
#include "blocking_queue.h"

namespace xcomet {

struct ClientOption {
  std::string host;
  int port;
  std::string user_name;
  std::string password;
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
  void SetContent(const std::string& str) {
    content_ = str;
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
};

typedef std::function<void ()> ConnectCallback;
typedef std::function<void ()> DisconnectCallback;
typedef std::function<void (const std::string&)> MessageCallback;
typedef std::function<void (ClientErrorCode)> ErrorCallback;

class SocketClient : public NonCopyable {
 public:
  enum ErrorCode {
    OK = 0,
  }
  SocketClient(const ClientOption option);
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
  bool IsConnected() {
    return is_connected_;
  }

  int Connect();
  int Subscribe(const string& topic);
  int Publish(const string& topic, const string& message);
  void Close();

 private:
  void WorkerThread();
  void HandleRead();
  void HandleWrite();
  void Notify();

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
};
}

#endif  // SRC_SOCKETCLIENT_H_
