//
//  DaemonController.h
//  mongodb.prefpane
//
//  Created by Max Howell http://github.com/mxcl/playdar.prefpane
//  Modified by Iván Valdés
//

#import <Cocoa/Cocoa.h>

@interface DaemonController : NSObject
{
    id delegate;
    
    NSTask* daemon_task;
    NSTimer* poll_timer;
    NSTimer* check_startup_status_timer;
    pid_t pid;    
}

-(id)initWithDelegate:(id)delegate;

-(void)start;
-(void)stop;

-(bool)isRunning;

@end
