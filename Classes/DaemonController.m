//
//  <!-- DaemonController -->
//  Based in the one by [Max Howell](http://github.com/mxcl/playdar.prefpane).
//

// **DaemonController** is a tool to monit daemons using Objective C, that are
// running in the system. The idea is to keep it simple, and provide methods to
// start, and stop a given daemon. It also watches for the PID, in order to give
// feedback about when the process is stopped by an external tool.
//
// ## Usage
//
// Just include the DaemonController.h file in your Class:
//
//     include "DaemonController.h";
//
// Then, create an instance of it
//
//     DaemonController *daemonController = [[DaemonController alloc]
//       init];
//
// Set the launch path for the Daemon to watch:
//
//     daemonController.launchPath =
//       @"/usr/local/Cellar/mysql/5.1.56/libexec/mysqld";
//
// Set the initialization arguments, if any:
//
//     daemonController.startArguments = [NSArray arrayWithObjects:
//       @"--basedir=/usr/local/Cellar/mysql/5.1.56",
//       @"--datadir=/usr/local/var/mysql",
//       @"--log-error=/usr/local/var/mysql/localjost.local.err",
//       @"--pid-file=/usr/local/var/mysql/localjost.local.pid", nil];
//
// Finally,  there's an especial list of arguments in order to stop the daemon:
//
//     daemonController.stopArguments = [NSArrary arrayWithObjects:
//       @"stop", nil];
//
// That's it. In order to get notifications about the status of the process, just set the
// block callbacks for any operation you need. Please refer to the [Callbacks][cbs]
// section in order to get more information on how to add them.
//
// To control the daemon, there are two simple tasks, start and stop. Please refer to the 
// [Control Tasks][dct] for more information.
//
// [cbs]: #section-Callbacks
// [dct]: #section-Control_Task

#import <sys/sysctl.h>
#import "DaemonController.h"

// ## Hidden Methods
// Here are the instance variables and methods used internally to control the Daemon.
//
// The binary name is stored in order to get the PID of the daemon.
//
// There's a reference to a poll timer, if it is not running yet, it will poll for it
// until there's a running process of it.
//
// The daemon task holds the active task, in case that the daemon was initialized by us.
//
@interface DaemonController(/* Hidden Methods */)
@property (nonatomic, retain) NSString *binaryName;
@property (nonatomic, retain) NSTimer  *pollTimer;
@property (nonatomic, retain) NSTask   *daemonTask;

- (void)startPoll;
- (void)daemonTerminatedFromQueue;
- (void)daemonTerminated:(NSNotification*)notification;
- (void)initDaemonTask;
- (void)poll:(NSTimer*)timer;
- (void)failedToStartDaemonTask:(NSString *)reason;
- (void)checkIfDaemonIsRunning;
@end

// ## C Methods
//
// Checks for the PID of a given daemon. If it's running, it will return the
// PID. If not, it will return 0.
static pid_t daemon_pid(const char *binary) {
  int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
  struct kinfo_proc *info;
  size_t totalTasks;
  pid_t pid = 0;

  // Means that there are no running tasks. Very unlikely.
  if (sysctl(mib, 3, NULL, &totalTasks, NULL, 0) < 0)
    return 0;
  // Not able to allocate the memory. Unlikey.
  if (!(info = NSZoneMalloc(NULL, totalTasks)))
    return 0;
  if (sysctl(mib, 3, info, &totalTasks, NULL, 0) >= 0) {
    // Search for the process id that matches the name of our daemon.
    totalTasks = totalTasks / sizeof(struct kinfo_proc);
    for(size_t i = 0; i < totalTasks; i++)
      // If found, store it in pid.
      if(strcmp(info[i].kp_proc.p_comm, binary) == 0) {
        pid = info[i].kp_proc.p_pid;
        break;
      }
  }

  NSZoneFree(NULL, info);
  return pid;
}

// Watches for termination of the process, doing a watch in its kernel event.
// Calls daemonTerminatedFromQueue whenever it happens, as a CFFileDescriptor
// provides just one callback, the call invalidates the current one.
static void kqueue_termination_callback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void *self) {
  [(id)self performSelector:@selector(daemonTerminatedFromQueue)];
}

// Returns a CFFileDescriptor that is the reference for the callback whenever the status of
// the process has changed.
static inline CFFileDescriptorRef kqueue_watch_pid(pid_t pid, id self) {
  int                     kq;
  struct kevent           changes;
  CFFileDescriptorContext context = {0, self, NULL, NULL, NULL};
  CFRunLoopSourceRef      rls;

  // Create the kqueue and set it up to watch for SIGCHLD. Use the
  // new-in-10.5 EV_RECEIPT flag to ensure that we get what we expect.
  kq = kqueue();

  // Sets the kernel event watcher, to use the process id, and to notify when the
  // process exits.
  EV_SET(&changes, pid, EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
  (void)kevent(kq, &changes, 1, &changes, 1, NULL);

  // Wrap the kqueue in a CFFileDescriptor (new in Mac OS X 10.5!). Then
  // create a run-loop source from the CFFileDescriptor and add that to the
  // runloop.
  CFFileDescriptorRef ref;
  ref = CFFileDescriptorCreate(NULL, kq, true, kqueue_termination_callback, &context);
  rls = CFFileDescriptorCreateRunLoopSource(NULL, ref, 0);
  CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
  CFRelease(rls);

  // Enable the callback, and return the created CFFileDescriptor.
  CFFileDescriptorEnableCallBacks(ref, kCFFileDescriptorReadCallBack);
  return ref;
}

// ## Public properties
// 
@implementation DaemonController
@synthesize startArguments;
@synthesize stopArguments;
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
    if (startArguments)
      daemonTask.arguments = startArguments;
    else
      daemonTask.arguments = [NSArray array];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(daemonTerminated:) name:NSTaskDidTerminateNotification object:daemonTask];
    [daemonTask launch];
    pid = daemonTask.processIdentifier;

    [self performSelector:@selector(checkIfDaemonIsRunning) withObject:nil afterDelay:0.2];
  } @catch (NSException *exception) {
    [self failedToStartDaemonTask:exception.reason];
  }
}

- (void)stop {
  if (stopArguments) {
    NSTask *task = [[[NSTask alloc] init] autorelease];
    task.launchPath = launchPath;
    // try to remove service first
    task.arguments = stopArguments;

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

- (void)daemonTerminatedFromQueue {
  fdref = nil;
  [self daemonTerminated:nil];
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

- (void)checkIfDaemonIsRunning {
  if ((pid = daemon_pid([binaryName UTF8String])) == 0)
    [self performSelector:@selector(checkIfDaemonIsRunning) withObject:nil afterDelay:0.2];
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
  [startArguments release];
  [stopArguments release];
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
