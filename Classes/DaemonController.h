//
//  DaemonController.h
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import <Cocoa/Cocoa.h>
// Allows you to specify your mongod binary location, just in case you have it in a weird place
// like /fruity/loops/mongod :)
#define MONGOD_LOCATION @"/usr/local/bin/mongod"

@interface DaemonController : NSObject
{
    id delegate;

    NSTask	 *daemon_task;
    NSTimer	 *poll_timer;
    NSTimer	 *check_startup_status_timer;
    pid_t	  pid;
    NSString *arguments;
    NSString *location;
}

@property (nonatomic, retain) NSString *arguments;

-(id)initWithDelegate:(id)theDelegate andArguments:(NSString *)theArguments;

-(void)start;
-(void)stop;

-(bool)locateBinary;

-(bool)isRunning;

@end
