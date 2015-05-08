//#include <stdio.h>
//#include <functional>
//#include <iostream>
//#include <string>
//#include "socketclient.h"
//
//using namespace std;
//using namespace xcomet;
//
//int main(int argc, char* argv[]) {
//  const char* host = "182.92.113.188";
//  const int port = 9000;
//  const char* user= "user520";
//  const char* password = "pwd520";
//
//  ClientOption option;
//  option.host = host;
//  option.port = port;
//  option.username= user;
//  option.password = password;
//
//  SocketClient client(option);
//  client.SetConnectCallback([]() {
//    cout << "connected" << endl;
//  });
//  client.SetDisconnectCallback([]() {
//    cout << "disconnected" << endl;
//  });
//  client.SetMessageCallback([](const std::string& msg) {
//    cout << "receive message: " << msg << endl;
//  });
//  client.SetErrorCallback([](const std::string& error) {
//    cout << "error: " << error << endl;
//  });
//  cout << "print any key to close ..." << endl;
//    client.SetKeepaliveInterval(30);
//  client.Connect();
//  getchar();
//  client.Close();
//  cout << "print any key to exit ..." << endl;
//  getchar();
//}
