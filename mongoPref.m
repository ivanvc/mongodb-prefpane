//
//  mongoPref.m
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import "mongoPref.h"

@implementation mongoPref
@synthesize theSlider, theArguments;

- (void) mainViewDidLoad
{
    dC = [[DaemonController alloc] initWithDelegate:self andArguments:[theArguments stringValue]];
    int theStatus;
    if ([dC isRunning]) {
        theStatus = 2;
    } else {
        theStatus = 1;
    }
    [theSlider setIntValue:theStatus];

    preferences		= [[NSUserDefaults standardUserDefaults] retain];
    preferencesDict = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"arguments", nil];
    [preferences registerDefaults:preferencesDict];
    [theArguments setStringValue:[preferences objectForKey:@"arguments"]];
}

- (void) daemonStopped 
{
    [theSlider setIntValue:1];	
}

- (void) daemonStarted 
{
    NSLog(@"Daemon started");
    [theSlider setIntValue:2];
}


- (void) dealloc
{
    [dC release];
    [preferences release];
    [preferencesDict release];
    [super dealloc];
}


- (IBAction) startStopDaemon:(id)sender 
{
    if (![dC locateBinary]) {
        [NSAlert alertWithMessageText:@"Cannot locate mongod :(" 
            defaultButton:@"Ok" 
            alternateButton:nil
            otherButton:nil 
            informativeTextWithFormat:@"Please make sure you have the mongod binary either in /usr/local/bin, /usr/bin, /bin, or /opt/bin"];
        [sender setIntValue:1];
        return;
    }
    if ([sender intValue] == 1) {
        [dC stop];
    } else {
        [dC setArguments:[theArguments stringValue]];
        [dC start];
    }

}

- (IBAction) changeArguments:(id)sender {
    [preferences setObject:[theArguments stringValue] forKey:@"arguments"];
}

@end
