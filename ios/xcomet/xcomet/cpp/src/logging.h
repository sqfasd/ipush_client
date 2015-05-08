#ifndef SRC_LOGGING_H_
#define SRC_LOGGING_H_

#include <time.h>
#include <stdio.h>
#include <string.h>
#include <sstream>
#include <thread>

#define LOG(severity) \
  if (xcomet::SimpleLogger::LogLevel() <= xcomet::LOG_##severity) \
    xcomet::SimpleLogger(__FILE__, __LINE__, #severity, \
        xcomet::LOG_##severity).Stream()

#define VLOG(v) \
  if (xcomet::SimpleLogger::LogVerboseLevel() >= v) LOG(INFO)

#define CHECK(condition) \
  if (!(condition)) \
    LOG(FATAL) << "check condition [" << #condition << "] failed: "

namespace xcomet {

const int LOG_INFO = 0;
const int LOG_WARNING = 1;
const int LOG_ERROR = 2;
const int LOG_ERROR_REPORT = 3;
const int LOG_FATAL = 4;

typedef void(*PrintFunc)(int level, const char*);

class SimpleLogger {
 public:
  static void SetPrintFunc(PrintFunc func) {
    s_print_func_ = func;
  }

  static void SetLogLevel(int n) {
    s_log_level_ = n;
  }

  static int LogLevel() {
    return s_log_level_;
  }

  static void SetLogVerboseLevel(int n) {
    s_log_verbose_level_ = n;
  }

  static int LogVerboseLevel() {
    return s_log_verbose_level_;
  }

  SimpleLogger(const char* file, int line, const char* level_str, int level)
      : level_(level) {
    time_t t = ::time(nullptr);
    struct tm* tm = ::localtime(&t);
    char time_buf[20] = {0};
    snprintf(time_buf, sizeof(time_buf), "%d%02d%02d:%02d%02d%02d",
        1900 + tm->tm_year,
        tm->tm_mon + 1,
        tm->tm_mday,
        tm->tm_hour,
        tm->tm_min,
        tm->tm_sec);
    stream_ << std::this_thread::get_id() << ':'
            << time_buf << ':'
            << level_str << ':'
            << file << ':'
            << line << "| ";
  }
  ~SimpleLogger() {
    stream_ << '\n';
    s_print_func_(level_, stream_.str().c_str());
  }
  std::ostream& Stream() { return stream_; }

 private:
  std::ostringstream stream_;
  int level_;

  static PrintFunc s_print_func_;
  static int s_log_level_;
  static int s_log_verbose_level_;
};
}
#endif  // SRC_LOGGING_H_
