//
//  mongoPref.m
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import "mongoPref.h"

@implementation mongoPref
@synthesize theSlider;

- (void) mainViewDidLoad
{
	dC = [[DaemonController alloc] initWithDelegate:self];
	int theStatus;
	if ([dC isRunning]) {
		theStatus = 2;
	} else {
		theStatus = 1;
	}
	[theSlider setIntValue:theStatus];
}

- (void) daemonStopped {
	NSLog(@"Daemon stopped");
	[theSlider setIntValue:1];	
}

- (void) daemonStarted {
	NSLog(@"Daemon started");
	[theSlider setIntValue:2];
}

- (IBAction) startStopDaemon:(id)sender {
	if ([sender intValue] == 1) {
		[dC stop];
	} else {
		[dC start];
	}

}

@end
