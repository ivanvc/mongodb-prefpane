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

static void kqueue_termination_callback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void* self) {
  [(id)self performSelector:@selector(daemonStopped)];
}

static inline void kqueue_watch_pid(pid_t pid, id self) {
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
}

@implementation DaemonController
@synthesize arguments;
@synthesize location;
@synthesize launchAgentPath;
@synthesize delegate;

@synthesize binaryName;
@synthesize pollTimer;
@synthesize daemonTask;

- (id)initWithDelegate:(id)theDelegate {
  if ((self = [super init])) {
    self.delegate = theDelegate;
  }

  return self;
}

- (BOOL)isRunning {
  return ((pid = daemon_pid([binaryName UTF8String])) != 0);
}

- (void)daemonTerminated:(NSNotification*)notification {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:daemonTask];

  self.daemonTask = nil;
  pid = 0;

  [self startPoll];
  [delegate performSelector:@selector(daemonStopped)];
}

- (void)stop {
  if (launchAgentPath) {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    // try to remove service first
    task.arguments = [NSArray arrayWithObjects:@"launchctl", @"unload", [launchAgentPath stringByExpandingTildeInPath], nil];

    [delegate performSelector:@selector(daemonStopped)];

    [task launch];
    [task waitUntilExit];
    [task release];
  }

  // if we have it running, then terminate the daemon
  if (daemonTask)
    [daemonTask terminate];
  else {
    pid = daemon_pid([location UTF8String]);
    if (pid == 0) {
      // actually we weren't even running in the first place
      [self startPoll];
      [delegate performSelector:@selector(daemonStopped)];
    } else {
      if (kill(pid, SIGHUP) == -1 && errno != ESRCH)
        [delegate performSelector:@selector(daemonStarted)];
      else
        [delegate performSelector:@selector(daemonStopped)];
    }
  }
}

-(void)initDaemonTask {
  [pollTimer invalidate];
  self.pollTimer = nil;

  [delegate performSelector:@selector(daemonStarted)];

  NSTask *task = [[NSTask alloc] init];
  self.daemonTask = task;
  [task release];
}

- (void)failedToStartDaemonTask {
  //NSString *message = [NSString stringWithFormat:@"The file at \"%@\" could not be executed." daemonTask.launchPath];
  [delegate performSelector:@selector(daemonStopped)];

  self.daemonTask = nil;
}

- (void)start {
  @try {
    [self initDaemonTask];
    daemonTask.launchPath = location;
    daemonTask.arguments = arguments;

    [daemonTask launch];
    [self startPoll];
  } @catch (NSException *exception) {
    NSLog(@"Exception %@", [exception reason]);
    [self failedToStartDaemonTask];
  }
}

- (void)checkReadyForScan {
  if (!pid) // started via Terminal route perhaps
    kqueue_watch_pid(pid = daemon_pid([location UTF8String]), self);
  [delegate performSelector:@selector(daemonStarted)];
}

- (void)poll:(NSTimer*)t {
  if ((pid = daemon_pid([location UTF8String])) == 0) {
    [delegate performSelector:@selector(daemonStopped)];
    return;
  }

  [delegate performSelector:@selector(daemonStarted)];
  [pollTimer invalidate];
  self.pollTimer = nil;
  kqueue_watch_pid(pid, self);
  [self checkReadyForScan];
}

/////////////////////////////////////////////////////////////////////////// misc
//-(int)numFiles
//{
//    NSTask* task = [[NSTask alloc] init];
//    [task setLaunchPath:[self playdarctl]];
//    [task setArguments:[NSArray arrayWithObject:@"numfiles"]];
//    [task setStandardOutput:[NSPipe pipe]];
//    [task launch];
//    [task waitUntilExit];
//
//    // if not zero then we library module isn't ready yet
//    if (task.terminationStatus != 0)
//        return -1;
//
//    NSData* data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
//    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] intValue];
//}

- (BOOL)locateBinary {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![location isEqualTo:nil] && ![location isEqualToString:@""]) {
        return YES;
    }
    if([fileManager fileExistsAtPath:@"/usr/local/bin/mongod"]) {
        location = @"/usr/local/bin/mongod";
    } else if ([fileManager fileExistsAtPath:@"/usr/bin/mongod"]) {
        location = @"/usr/bin/mongod";
    } else if ([fileManager fileExistsAtPath:@"/bin/mongod"]) {
        location = @"/bin/mongod";
    } else if ([fileManager fileExistsAtPath:@"/opt/bin/mongod"]) {
        location = @"/opt/bin/mongod";
    } else if ([fileManager fileExistsAtPath:MONGOD_LOCATION]) {
        location = MONGOD_LOCATION;
    } else {
        return NO;
    }
    return YES;
}

- (void)startPoll {
  self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(poll:) userInfo:nil repeats:true];
}

#pragma mark - Custom Setters and Getters

- (void)setLocation:(NSString *)theLocation {
  if (location != theLocation) {
    if (pollTimer) {
      [pollTimer invalidate];
    }

    [location release];
    location = [theLocation retain];
    self.binaryName = [theLocation lastPathComponent];

    if (location) {
      if ((pid = daemon_pid([binaryName UTF8String])))
        kqueue_watch_pid(pid, self); // watch the pid for termination
      else
        [self startPoll];
    }
  }
}

#pragma mark - Memory Management

- (void)dealloc {
  [arguments release];
  [location release];
  [launchAgentPath release];

  [binaryName release];
  [pollTimer release];
  [daemonTask release];

  [super dealloc];
}

@end
