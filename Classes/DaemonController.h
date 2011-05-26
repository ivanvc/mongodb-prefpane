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
}

@property (nonatomic, retain) NSArray *arguments;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *launchAgentPath;
@property (nonatomic, assign) id delegate;

- (id)initWithDelegate:(id)theDelegate;

- (void)start;
- (void)stop;

- (BOOL)locateBinary;

- (BOOL)isRunning;

@end
