//
//  DaemonController.h
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import <Cocoa/Cocoa.h>

@interface DaemonController : NSObject {
  id delegate;

  NSArray  *arguments;
  NSString *location;
  NSString *launchAgentPath;

@private
  NSString *binaryName;
  NSTask	 *daemonTask;
  NSTimer  *pollTimer;
  NSTimer  *checkStartupStatusTimer;
  pid_t	    pid;
  CFFileDescriptorRef fdref;
}

@property (nonatomic, retain) NSArray *arguments;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *launchAgentPath;
@property (nonatomic, assign) id delegate;
@property (readonly, getter = pid) NSNumber *pid;

- (id)initWithDelegate:(id)theDelegate;

- (void)start;
- (void)stop;

//- (BOOL)locateBinary;

- (BOOL)isRunning;
- (NSNumber *)pid;

@end
