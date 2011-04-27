//
//  DaemonController.m
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import "DaemonController.h"
#import <sys/sysctl.h>

/** returns the pid of the running playdar instance, or 0 if not found */
static pid_t mongod_pid()
{
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    struct kinfo_proc *info;
    size_t N;
    pid_t pid = 0;

    if(sysctl(mib, 3, NULL, &N, NULL, 0) < 0)
        return 0; //wrong but unlikely
    if(!(info = NSZoneMalloc(NULL, N)))
        return 0; //wrong but unlikely
    if(sysctl(mib, 3, info, &N, NULL, 0) < 0)
        goto end;

    N = N / sizeof(struct kinfo_proc);
    for(size_t i = 0; i < N; i++)
        if(strcmp(info[i].kp_proc.p_comm, "mongod") == 0)
        { pid = info[i].kp_proc.p_pid; break; }
    end:
    NSZoneFree(NULL, info);
    return pid;
}

static void kqueue_termination_callback(CFFileDescriptorRef f, CFOptionFlags callBackTypes, void* self)
{
    [(id)self performSelector:@selector(daemonStopped)];
}

static inline void kqueue_watch_pid(pid_t pid, id self)
{
    int                     kq;
    struct kevent           changes;
    CFFileDescriptorContext context = { 0, self, NULL, NULL, NULL };
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

#define START_POLL poll_timer = [NSTimer scheduledTimerWithTimeInterval:0.33 target:self selector:@selector(poll:) userInfo:nil repeats:true];



@implementation DaemonController
@synthesize arguments;

-(id)initWithDelegate:(id)theDelegate andArguments:(NSString *)theArguments
{
    delegate = [theDelegate retain];
    location = @"";
    [self setArguments:theArguments];
    if(pid = mongod_pid())
        kqueue_watch_pid(pid, self); // watch the pid for termination
    else
        START_POLL;

    return self;
}

-(bool)isRunning
{
    return ((pid = mongod_pid()) != 0);
}

-(void)daemonTerminated:(NSNotification*)note
{    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:daemon_task];

    daemon_task = nil;
    pid = 0;

    START_POLL;

    [delegate performSelector:@selector(daemonStopped)];
}

-(void)stop
{
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/env";
    // try to remove service first
    task.arguments = [NSArray arrayWithObjects:@"launchctl", 
        @"unload", 
        [@"~/Library/LaunchAgents/org.mongodb.mongod.plist" stringByExpandingTildeInPath], 
        nil];

    [delegate performSelector:@selector(daemonStopped)];

    [task launch];
    [task waitUntilExit];

    // if we have it running, then terminate the daemon
    if(daemon_task)
        [daemon_task terminate];
    else
    {
        pid = mongod_pid();
        if (pid == 0)
        {
            // actually we weren't even running in the first place
            START_POLL
                [delegate performSelector:@selector(daemonStopped)];
        }
        else 
        {
            if (kill(pid, SIGHUP) == -1 && errno != ESRCH)
                [delegate performSelector:@selector(daemonStarted)];
            else
                [delegate performSelector:@selector(daemonStopped)];
        }

    }
}

-(void)initDaemonTask
{
    [poll_timer invalidate];
    poll_timer = nil;

    [delegate performSelector:@selector(daemonStarted)];

    daemon_task = [[NSTask alloc] init];
}

-(void)failedToStartDaemonTask
{
    NSMutableString* msg = [@"The file at “" mutableCopy];
    [msg appendString:daemon_task.launchPath];
    [msg appendString:@"” could not be executed."];
    NSLog(@"Failed to start daemon %@ %i", msg);

    [delegate performSelector:@selector(daemonStopped)];

    daemon_task = nil;
    [msg release];
}

-(void)start
{
    @try {
        NSMutableArray *arrayOfArguments = [[NSMutableArray alloc] initWithObjects:@"run", nil];
        [self initDaemonTask];
        daemon_task.launchPath = location;

        if (arguments) {
            [arrayOfArguments addObjectsFromArray:[arguments componentsSeparatedByString:@" "]];
        }
        daemon_task.arguments = [[arrayOfArguments copy] autorelease];
        [arrayOfArguments release];

        [daemon_task launch];
        START_POLL
        }
    @catch (NSException* e) {
        NSLog(@"Exception %@", [e reason]);
        [self failedToStartDaemonTask];
    }
}

-(void)checkReadyForScan
{
    if (!pid) // started via Terminal route perhaps
        kqueue_watch_pid(pid = mongod_pid(), self);
    [delegate performSelector:@selector(daemonStarted)];
}

-(void)poll:(NSTimer*)t
{
    if (pid = mongod_pid() == 0) {
        [delegate performSelector:@selector(daemonStopped)];
        return;
    }
    [delegate performSelector:@selector(daemonStarted)];
    [poll_timer invalidate];
    poll_timer = nil;
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

-(bool)locateBinary {
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

@end