#include <stdio.h>
#include <functional>
#include <iostream>
#include <string>
#include "src/socketclient.h"

using namespace std;
using namespace xcomet;

int main(int argc, char* argv[]) {
  const char* host = "127.0.0.1";
  const int port = 9000;
  const char* user_name = "user1";
  const char* password = "pwd111";

  ClientOption option;
  option.host = host;
  option.port = port;
  option.user_name = user_name;
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
  client.Connect();
  getchar();
  client.Close();
  cout << "print any key to exit ..." << endl;
  getchar();
}
