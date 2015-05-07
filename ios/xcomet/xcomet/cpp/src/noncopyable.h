#ifndef SRC_NONCOPYABLE_H_
#define SRC_NONCOPYABLE_H_

namespace xcomet {

class NonCopyable {
 public:
  NonCopyable& operator=(const NonCopyable&) = delete;
  NonCopyable(const NonCopyable&) = delete;

 protected:
  NonCopyable() = default;
  ~NonCopyable() = default;
};
}

#endif  // SRC_NONCOPYABLE_H_
