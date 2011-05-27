//
//  DaemonController.h
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import <Cocoa/Cocoa.h>

typedef void (^DaemonStarted)(NSNumber *);
typedef void (^DaemonStopped)();
typedef void (^DaemonNotRunning)();
typedef void (^DaemonIsStarting)();
typedef void (^DaemonIsStopping)();
typedef void (^DaemonFailedToStart)(NSString *);
typedef void (^DaemonFailedToStop)(NSString *);

@interface DaemonController : NSObject {
  NSArray  *argumentsToStart;
  NSArray  *argumentsToStop;
  NSString *launchPath;

  DaemonStarted daemonStartedCallback;
  DaemonStopped daemonStoppedCallback;
  DaemonIsStarting daemonIsStartingCallback;
  DaemonIsStopping daemonIsStoppingCallback;
  DaemonFailedToStart daemonFailedToStartCallback;
  DaemonFailedToStop daemonFailedToStopCallback;

@private
  NSString *binaryName;
  NSTask	 *daemonTask;
  NSTimer  *pollTimer;
  NSTimer  *checkStartupStatusTimer;
  pid_t	    pid;
  CFFileDescriptorRef fdref;
}

@property (nonatomic, retain) NSArray *argumentsToStart;
@property (nonatomic, retain) NSArray *argumentsToStop;
@property (nonatomic, retain) NSString *launchPath;

@property (readonly, getter = pid) NSNumber *pid;
@property (readonly, getter = running) BOOL isRunning;

@property (readwrite, copy) DaemonStarted daemonStartedCallback;
@property (readwrite, copy) DaemonStopped daemonStoppedCallback;
@property (readwrite, copy) DaemonIsStarting daemonIsStartingCallback;
@property (readwrite, copy) DaemonIsStopping daemonIsStoppingCallback;
@property (readwrite, copy) DaemonFailedToStart daemonFailedToStartCallback;
@property (readwrite, copy) DaemonFailedToStop daemonFailedToStopCallback;

- (void)start;
- (void)stop;

- (BOOL)running;
- (NSNumber *)pid;

@end
