#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <fcntl.h>
#include <ctype.h>
#include <stdlib.h>
#include <string>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "deps/jsoncpp/include/json/json.h"

namespace xcomet {

inline void SetNonblock(int fd) {
  int flags;
  flags = ::fcntl(fd, F_GETFL);
  flags |= O_NONBLOCK;
  fcntl(fd, F_SETFL, flags);
  // TODO check ret != -1
}

inline bool IsIp(const std::string& ip) {
  in_addr a;
  return ::inet_aton(ip.c_str(), &a) != 0;
}

inline bool GetHostIp(const std::string& host, std::string& ip) {
  struct hostent* hptr;
  if ((hptr = ::gethostbyname(host.c_str())) == NULL) {
    return false;
  }
  char buf[32] = {0};
  if (inet_ntop(hptr->h_addrtype, hptr->h_addr, buf, sizeof(buf)) == NULL) {
    return false;
  }
  ip.assign(buf);
  return true;
}

inline void SerializeJson(const Json::Value& json, string& data) {
  data = Json::FastWriter().write(json);
}

inline bool ParseIpPort(const string& addr, string& ip, int& port) {
  int ip_start = addr.find("//") + 2;
  int port_start = addr.find(":", ip_start);
  int port_end = addr.find("/", port_start);
  if (ip_start == string::npos || port_start == string::npos ||
      port_end == string::npos) {
    return false;
  }
  ip = addr.substr(ip_start, port_start-ip_start);
  port = ::atoi(addr.substr(port_start+1, port_end-port_start).c_str());
  return true;
}

}
#endif
