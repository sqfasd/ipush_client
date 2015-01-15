#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <fcntl.h>
#include <ctype.h>
#include <string>

namespace xcomet {

inline void SetNonblock(int fd) {
  int flags;
  flags = ::fcntl(fd, F_GETFL);
  flags |= O_NONBLOCK;
  fcntl(fd, F_SETFL, flags);
  // TODO check ret != -1
}

inline bool IsIp(const std::string& ip) {
  // TODO impl
  return ::isdigit(ip[0]);
}

inline bool GetHostIp(const std::string& host, std::string& ip) {
  // TODO impl
  ip = "127.0.0.1";
  return true;
}

}
#endif
