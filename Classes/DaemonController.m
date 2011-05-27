//
//  DaemonController.m
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import <sys/sysctl.h>
#import "DaemonController.h"

@interface DaemonController(/* Hidden Methods */)
@property (nonatomic, retain) NSString *binaryName;
@property (nonatomic, retain) NSTimer  *pollTimer;
@property (nonatomic, retain) NSTask   *daemonTask;

- (void)startPoll;
- (void)daemonTerminated:(NSNotification*)notification;
- (void)initDaemonTask;
- (void)poll:(NSTimer*)timer;
- (void)failedToStartDaemonTask:(NSString *)reason;
- (void)checkReadyForDaemon;
@end

/** returns the pid of the running playdar instance, or 0 if not found */
static pid_t daemon_pid(const char *binary) {
  int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
  struct kinfo_proc *info;
  size_t N;
  pid_t pid = 0;

  if (sysctl(mib, 3, NULL, &N, NULL, 0) < 0)
    return 0; //wrong but unlikely
  if (!(info = NSZoneMalloc(NULL, N)))
    return 0; //wrong but unlikely
  if (sysctl(mib, 3, info, &N, NULL, 0) >= 0) {
    N = N / sizeof(struct kinfo_proc);
    for(size_t i = 0; i < N; i++)
      if(strcmp(info[i].kp_proc.p_comm, binary) == 0) {
        pid = info[i].kp_proc.p_pid;
        break;
      }
  }

  NSZoneFree(NULL, info);
  return pid;
}

static void kqueue_termination_callback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void *self) {
  [(id)self performSelector:@selector(daemonTerminated:)];
}

static inline CFFileDescriptorRef kqueue_watch_pid(pid_t pid, id self) {
  int                     kq;
  struct kevent           changes;
  CFFileDescriptorContext context = {0, self, NULL, NULL, NULL};
  CFRunLoopSourceRef      rls;

  // Create the kqueue and set it up to watch for SIGCHLD. Use the
  // new-in-10.5 EV_RECEIPT flag to ensure that we get what we expect.

  kq = kqueue();

  EV_SET(&changes, pid, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
  (void) kevent(kq, &changes, 1, &changes, 1, NULL);

  // Wrap the kqueue in a CFFileDescriptor (new in Mac OS X 10.5!). Then
  // create a run-loop source from the CFFileDescriptor and add that to the
  // runloop.

  CFFileDescriptorRef ref;
  ref = CFFileDescriptorCreate(NULL, kq, true, kqueue_termination_callback, &context);
  rls = CFFileDescriptorCreateRunLoopSource(NULL, ref, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
  CFRelease(rls);

  CFFileDescriptorEnableCallBacks(ref, kCFFileDescriptorReadCallBack);
  return ref;
}

@implementation DaemonController
@synthesize argumentsToStart;
@synthesize argumentsToStop;
@synthesize launchPath;

@synthesize binaryName;
@synthesize pollTimer;
@synthesize daemonTask;

@synthesize daemonStartedCallback;
@synthesize daemonStoppedCallback;
@synthesize daemonIsStartingCallback;
@synthesize daemonIsStoppingCallback;
@synthesize daemonFailedToStartCallback;
@synthesize daemonFailedToStopCallback;

#pragma mark - Daemon control tasks

- (void)start {
  @try {
    [self initDaemonTask];
    daemonTask.launchPath = launchPath;
    if (argumentsToStart)
      daemonTask.arguments = argumentsToStart;
    else
      daemonTask.arguments = [NSArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(daemonTerminated:) name:NSTaskDidTerminateNotification object:daemonTask];
    [daemonTask launch];
    pid = daemonTask.processIdentifier;

    [self performSelector:@selector(checkReadyForDaemon) withObject:nil afterDelay:0.2];
  } @catch (NSException *exception) {
    [self failedToStartDaemonTask:exception.reason];
  }
}

- (void)stop {
  if (argumentsToStop) {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    task.launchPath = launchPath;
    // try to remove service first
    task.arguments = argumentsToStop;

    [task launch];
    [task waitUntilExit];

    // the kqueue event will tell us when the process exits
    if (task.terminationStatus == 0) {
      if (daemonIsStoppingCallback)
        daemonIsStoppingCallback();

      return;
    }
  }

  // if we have it running, then terminate the daemon
  if (daemonTask) {
    [daemonTask terminate];

    if (daemonIsStoppingCallback)
      daemonIsStoppingCallback();
  } else {
    pid = daemon_pid([binaryName UTF8String]);
    if ((pid = daemon_pid([binaryName UTF8String])) == 0) {
      // actually we weren't even running in the first place
      [self startPoll];
      if (daemonStoppedCallback)
        daemonStoppedCallback();
    } else {
      if (kill(pid, SIGTERM) == -1 && errno != ESRCH)
        if (daemonFailedToStopCallback)
          daemonFailedToStopCallback(@"Failed to stop and kill the daemon.");
    }
  }
}

- (NSNumber *)pid {
  return [NSNumber numberWithInt:pid];
}

- (BOOL)running {
  return [[self pid] boolValue];
}

#pragma mark - Internal Daemon Tasks

- (void)initDaemonTask {
  [pollTimer invalidate];
  self.pollTimer = nil;

  if (daemonIsStartingCallback)
    daemonIsStartingCallback();

  NSTask *task = [[NSTask alloc] init];
  self.daemonTask = task;
  [task release];
}

- (void)daemonTerminated:(NSNotification*)notification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:daemonTask];

  self.daemonTask = nil;
  pid = 0;

  [self startPoll];
  if (daemonStoppedCallback)
    daemonStoppedCallback();
}

- (void)failedToStartDaemonTask:(NSString *)reason {
  if (daemonFailedToStartCallback)
    daemonFailedToStartCallback(reason);

  self.daemonTask = nil;
}

- (void)checkReadyForDaemon {
  if ((pid = daemon_pid([binaryName UTF8String])) == 0)
    [self performSelector:@selector(checkReadyForDaemon) withObject:nil afterDelay:0.2];
  else if (daemonStartedCallback)
    daemonStartedCallback(self.pid);
}

- (void)startPoll {
  if (pollTimer)
    [pollTimer invalidate];

  self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(poll:) userInfo:nil repeats:true];
}

- (void)poll:(NSTimer*)timer {
  if ((pid = daemon_pid([binaryName UTF8String])) == 0)
    return;

  if (daemonStartedCallback)
    daemonStartedCallback(self.pid);

  [pollTimer invalidate];
  self.pollTimer = nil;
  fdref = kqueue_watch_pid(pid, self);
}

#pragma mark - Custom Setters and Getters

- (void)setLaunchPath:(NSString *)theLaunchPath {
  if (launchPath != theLaunchPath) {
    if (pollTimer)
      [pollTimer invalidate];
    if (fdref != NULL)
      CFFileDescriptorDisableCallBacks(fdref, kCFFileDescriptorReadCallBack);

    [launchPath release];
    launchPath = [theLaunchPath retain];
    self.binaryName = [launchPath lastPathComponent];

    if (launchPath)
      [self startPoll];
  }
}

#pragma mark - Memory Management

- (void)dealloc {
  [argumentsToStart release];
  [argumentsToStop release];
  [launchPath release];

  [binaryName release];
  [pollTimer release];
  [daemonTask release];

  [daemonStartedCallback release];
  [daemonStoppedCallback release];
  [daemonIsStartingCallback release];
  [daemonFailedToStartCallback release];
  [daemonIsStoppingCallback release];
  [daemonFailedToStopCallback release];

  [super dealloc];
}

@end
