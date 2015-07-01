/**
 * In order to provide fast and flexible logging, this project uses Cocoa Lumberjack.
 * 
 * The GitHub project page has a wealth of documentation if you have any questions.
 * https://github.com/robbiehanson/CocoaLumberjack
 * 
 * Here's what you need to know concerning how logging is setup for XMPPFramework:
 * 
 * There are 4 log levels:
 * - Error
 * - Warning
 * - Info
 * - Verbose
 * 
 * In addition to this, there is a Trace flag that can be enabled.
 * When tracing is enabled, it spits out the methods that are being called.
 * 
 * Please note that tracing is separate from the log levels.
 * For example, one could set the log level to warning, and enable tracing.
 * 
 * All logging is asynchronous, except errors.
 * To use logging within your own custom files, follow the steps below.
 * 
 * Step 1:
 * Import this header in your implementation file:
 * 
 * #import "XCLogging.h"
 * 
 * Step 2:
 * Define your logging level in your implementation file:
 * 
 * // Log levels: off, error, warn, info, verbose
 * static const int XCLogLevel = XC_LOG_LEVEL_VERBOSE;
 * 
 * If you wish to enable tracing, you could do something like this:
 * 
 * // Log levels: off, error, warn, info, verbose
 * static const int XCLogLevel = XC_LOG_LEVEL_INFO | XC_LOG_FLAG_TRACE;
 * 
 * Step 3:
 * Replace your NSLog statements with XCLog statements according to the severity of the message.
 * 
 * NSLog(@"Fatal error, no dohickey found!"); -> XCLogError(@"Fatal error, no dohickey found!");
 * 
 * XCLog has the same syntax as NSLog.
 * This means you can pass it multiple variables just like NSLog.
 * 
 * You may optionally choose to define different log levels for debug and release builds.
 * You can do so like this:
 * 
 * // Log levels: off, error, warn, info, verbose
 * #if DEBUG
 *   static const int XCLogLevel = XC_LOG_LEVEL_VERBOSE;
 * #else
 *   static const int XCLogLevel = XC_LOG_LEVEL_WARN;
 * #endif
 * 
 * Xcode projects created with Xcode 4 automatically define DEBUG via the project's preprocessor macros.
 * If you created your project with a previous version of Xcode, you may need to add the DEBUG macro manually.
**/

//#import "DDLog.h"
#import <DDLog.h>
// Global flag to enable/disable logging throughout the entire xmpp framework.

#ifndef XC_LOGGING_ENABLED
#define XC_LOGGING_ENABLED 0
#endif

// Define logging context for every log message coming from the XMPP framework.
// The logging context can be extracted from the DDLogMessage from within the logging framework.
// This gives loggers, formatters, and filters the ability to optionally process them differently.

#define XC_LOG_CONTEXT 5222

// Configure log levels.

#define XC_LOG_FLAG_ERROR   (1 << 0) // 0...00001
#define XC_LOG_FLAG_WARN    (1 << 1) // 0...00010
#define XC_LOG_FLAG_INFO    (1 << 2) // 0...00100
#define XC_LOG_FLAG_VERBOSE (1 << 3) // 0...01000

#define XC_LOG_LEVEL_OFF     0                                              // 0...00000
#define XC_LOG_LEVEL_ERROR   (XC_LOG_LEVEL_OFF   | XC_LOG_FLAG_ERROR)   // 0...00001
#define XC_LOG_LEVEL_WARN    (XC_LOG_LEVEL_ERROR | XC_LOG_FLAG_WARN)    // 0...00011
#define XC_LOG_LEVEL_INFO    (XC_LOG_LEVEL_WARN  | XC_LOG_FLAG_INFO)    // 0...00111
#define XC_LOG_LEVEL_VERBOSE (XC_LOG_LEVEL_INFO  | XC_LOG_FLAG_VERBOSE) // 0...01111

// Setup fine grained logging.
// The first 4 bits are being used by the standard log levels (0 - 3)
// 
// We're going to add tracing, but NOT as a log level.
// Tracing can be turned on and off independently of log level.

#define XC_LOG_FLAG_TRACE     (1 << 4) // 0...10000

// Setup the usual boolean macros.

#define XC_LOG_ERROR   (XCLogLevel & XC_LOG_FLAG_ERROR)
#define XC_LOG_WARN    (XCLogLevel & XC_LOG_FLAG_WARN)
#define XC_LOG_INFO    (XCLogLevel & XC_LOG_FLAG_INFO)
#define XC_LOG_VERBOSE (XCLogLevel & XC_LOG_FLAG_VERBOSE)
#define XC_LOG_TRACE   (XCLogLevel & XC_LOG_FLAG_TRACE)

// Configure asynchronous logging.
// We follow the default configuration,
// but we reserve a special macro to easily disable asynchronous logging for debugging purposes.

#if DEBUG
#define XC_LOG_ASYNC_ENABLED  NO
#else
#define XC_LOG_ASYNC_ENABLED  YES
#endif

#define XC_LOG_ASYNC_ERROR     ( NO && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_WARN      (YES && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_INFO      (YES && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_VERBOSE   (YES && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_TRACE     (YES && XC_LOG_ASYNC_ENABLED)

// Define logging primitives.
// These are primarily wrappers around the macros defined in Lumberjack's DDLog.h header file.

#define XC_LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
    do{ if(XC_LOGGING_ENABLED) LOG_MAYBE(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__); } while(0)

#define XC_LOG_C_MAYBE(async, lvl, flg, ctx, frmt, ...) \
    do{ if(XC_LOGGING_ENABLED) LOG_MAYBE(async, lvl, flg, ctx, __FUNCTION__, frmt, ##__VA_ARGS__); } while(0)


#define XCLogError(frmt, ...)    XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_ERROR,   XCLogLevel, XC_LOG_FLAG_ERROR,  \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogWarn(frmt, ...)     XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_WARN,    XCLogLevel, XC_LOG_FLAG_WARN,   \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogInfo(frmt, ...)     XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_INFO,    XCLogLevel, XC_LOG_FLAG_INFO,    \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogVerbose(frmt, ...)  XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_VERBOSE, XCLogLevel, XC_LOG_FLAG_VERBOSE, \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogTrace()             XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_TRACE,   XCLogLevel, XC_LOG_FLAG_TRACE, \
                                                  XC_LOG_CONTEXT, @"%@: %@", THIS_FILE, THIS_METHOD)

#define XCLogTrace2(frmt, ...)   XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_TRACE,   XCLogLevel, XC_LOG_FLAG_TRACE, \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)


#define XCLogCError(frmt, ...)      XC_LOG_C_MAYBE(XC_LOG_ASYNC_ERROR,   XCLogLevel, XC_LOG_FLAG_ERROR,   \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogCWarn(frmt, ...)       XC_LOG_C_MAYBE(XC_LOG_ASYNC_WARN,    XCLogLevel, XC_LOG_FLAG_WARN,    \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogCInfo(frmt, ...)       XC_LOG_C_MAYBE(XC_LOG_ASYNC_INFO,    XCLogLevel, XC_LOG_FLAG_INFO,    \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogCVerbose(frmt, ...)    XC_LOG_C_MAYBE(XC_LOG_ASYNC_VERBOSE, XCLogLevel, XC_LOG_FLAG_VERBOSE, \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

#define XCLogCTrace()               XC_LOG_C_MAYBE(XC_LOG_ASYNC_TRACE,   XCLogLevel, XC_LOG_FLAG_TRACE, \
                                                  XC_LOG_CONTEXT, @"%@: %s", THIS_FILE, __FUNCTION__)

#define XCLogCTrace2(frmt, ...)     XC_LOG_C_MAYBE(XC_LOG_ASYNC_TRACE,   XCLogLevel, XC_LOG_FLAG_TRACE, \
                                                  XC_LOG_CONTEXT, frmt, ##__VA_ARGS__)

// Setup logging for XMPPStream (and subclasses such as XMPPStreamFacebook)

#define XC_LOG_FLAG_SEND      (1 << 5)
#define XC_LOG_FLAG_RECV_PRE  (1 << 6) // Prints data before it goes to the parser
#define XC_LOG_FLAG_RECV_POST (1 << 7) // Prints data as it comes out of the parser

#define XC_LOG_FLAG_SEND_RECV (XC_LOG_FLAG_SEND | XC_LOG_FLAG_RECV_POST)

#define XC_LOG_SEND      (XCLogLevel & XC_LOG_FLAG_SEND)
#define XC_LOG_RECV_PRE  (XCLogLevel & XC_LOG_FLAG_RECV_PRE)
#define XC_LOG_RECV_POST (XCLogLevel & XC_LOG_FLAG_RECV_POST)

#define XC_LOG_ASYNC_SEND      (YES && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_RECV_PRE  (YES && XC_LOG_ASYNC_ENABLED)
#define XC_LOG_ASYNC_RECV_POST (YES && XC_LOG_ASYNC_ENABLED)

#define XCLogSend(format, ...)     XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_SEND, XCLogLevel, \
                                                XC_LOG_FLAG_SEND, XC_LOG_CONTEXT, format, ##__VA_ARGS__)

#define XCLogRecvPre(format, ...)  XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_RECV_PRE, XCLogLevel, \
                                                XC_LOG_FLAG_RECV_PRE, XC_LOG_CONTEXT, format, ##__VA_ARGS__)

#define XCLogRecvPost(format, ...) XC_LOG_OBJC_MAYBE(XC_LOG_ASYNC_RECV_POST, XCLogLevel, \
                                                XC_LOG_FLAG_RECV_POST, XC_LOG_CONTEXT, format, ##__VA_ARGS__)
