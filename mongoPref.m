//
//  mongoPref.m
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import "mongoPref.h"
#import "MBSliderButton.h"
#import "DaemonController.h"

@implementation mongoPref
@synthesize theSlider;
@synthesize theArguments;

- (void) mainViewDidLoad;
{
  dC = [[DaemonController alloc] initWithDelegate:self andArguments:[theArguments stringValue]];
  
  [theSlider setState:[dC isRunning] ? NSOnState : NSOffState];
  
  preferences	= [[NSUserDefaults standardUserDefaults] retain];
  preferencesDict = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"arguments", nil];
  [preferences registerDefaults:preferencesDict];
  [theArguments setStringValue:[preferences objectForKey:@"arguments"]];
}

- (void) daemonStopped;
{
  [theSlider setState:NSOffState animate:YES];
}

- (void) daemonStarted; 
{
  [theSlider setState:NSOnState animate:YES];
}

- (void) dealloc;
{
  [dC release];
  [preferences release];
  [preferencesDict release];
  [super dealloc];
}

- (IBAction) startStopDaemon:(id)sender;
{
  if (![dC locateBinary]) {
    [NSAlert alertWithMessageText:@"Cannot locate mongod :(" 
                    defaultButton:@"Ok" 
                  alternateButton:nil
                      otherButton:nil 
        informativeTextWithFormat:@"Please make sure you have the mongod binary either in /usr/local/bin, /usr/bin, /bin, or /opt/bin"];
    [theSlider setState:NSOffState];
    return;
  }
  if (theSlider.state == NSOffState) {
    [dC stop];
  } else {
    [dC setArguments:[theArguments stringValue]];
    [dC start];
  }
  
}

- (IBAction) changeArguments:(id)sender;
{
  [preferences setObject:[theArguments stringValue] forKey:@"arguments"];
}

@end
