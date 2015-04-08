#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <fcntl.h>
#include <ctype.h>
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

}
#endif
