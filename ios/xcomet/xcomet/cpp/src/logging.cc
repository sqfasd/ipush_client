#include "logging.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

namespace xcomet {

void DefaultPrintFunc(int level, const char* str) {
  ::fwrite(str, 1, ::strlen(str), stderr);
  if (level == LOG_FATAL) {
    ::fflush(stderr);
    ::abort();
  }
}

PrintFunc SimpleLogger::s_print_func_ = DefaultPrintFunc;
int SimpleLogger::s_log_level_ = xcomet::LOG_INFO;
int SimpleLogger::s_log_verbose_level_ = 3;

}  // namespace xcomet
