#include <stdio.h>
#include <functional>
#include <iostream>
#include <string>
#include "src/socketclient.h"

using namespace std;
using namespace xcomet;

int main(int argc, char* argv[]) {
  if (argc != 5) {
    cerr << "usage: " << argv[0] << "<host> <port> <user> <password>\n";
    return -1;
  }
  const char* host = argv[1];
  const int port = std::stoi(argv[2]);
  const char* user= argv[3];
  const char* password = argv[4];

  ClientOption option;
  option.host = host;
  option.port = port;
  option.username = user;
  option.password = password;

  SocketClient client(option);
  client.SetConnectCallback([]() {
    cout << "connected" << endl;
  });
  client.SetDisconnectCallback([]() {
    cout << "disconnected" << endl;
  });
  client.SetMessageCallback([](const std::string& msg) {
    cout << "receive message: " << msg << endl;
  });
  client.SetErrorCallback([](const std::string& error) {
    cout << "error: " << error << endl;
  });
  cout << "print any key to close ..." << endl;
  client.SetKeepaliveInterval(30);
  client.Connect();
  getchar();
  client.Close();
  cout << "print any key to exit ..." << endl;
  getchar();
}
