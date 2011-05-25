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
#import "Preferences.h"
#import "Sparkle/Sparkle.h"

@interface mongoPref(/* Hidden Methods */)
- (void)checkStatus;

@property (nonatomic, retain) SUUpdater *updater;

@end

@implementation mongoPref
@synthesize theSlider;
@synthesize updater;

- (id)initWithBundle:(NSBundle *)bundle {
  self = [super initWithBundle:bundle];
  if (self) {
    [[Preferences sharedPreferences] setBundle:bundle];
  }

  return self;
}

- (void) mainViewDidLoad {
  self.updater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
  [updater resetUpdateCycle];
  dC = [[DaemonController alloc] initWithDelegate:self];

  [theSlider setState:[dC isRunning] ? NSOnState : NSOffState];  
}

- (void) daemonStopped;
{
  [theSlider setState:NSOffState animate:YES];
}

- (void) daemonStarted; 
{
  [theSlider setState:NSOnState animate:YES];
}

- (void) dealloc {
  [updater release];
  [dC release];
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
    dC.arguments = [[Preferences sharedPreferences] argumentsWithParameters];
    [dC start];
  }
  
}

@end
