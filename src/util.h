#ifndef SRC_UTIL_H_
#define SRC_UTIL_H_

#include <fcntl.h>

namespace xcomet {

static void SetNonblock(int fd) {
  int flags;
  flags = ::fcntl(fd, F_GETFL);
  flags |= O_NONBLOCK;
  fcntl(fd, F_SETFL, flags);
  // check ret != -1
}

}
#endif
