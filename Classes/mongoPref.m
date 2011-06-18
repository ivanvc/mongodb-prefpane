//
//  mongoPref.m
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import "mongoPref.h"
#import "MBSliderButton.h"
#import "FFYDaemonController.h"
#import "Preferences.h"
#import "Sparkle/Sparkle.h"

@interface mongoPref(/* Hidden Methods */)
@property (nonatomic, retain) SUUpdater *updater;
@property (nonatomic, retain) FFYDaemonController *daemonController;
@end

@implementation mongoPref
@synthesize theSlider;
@synthesize updater;
@synthesize daemonController;
@synthesize launchPathTextField;

- (id)initWithBundle:(NSBundle *)bundle {
  if ((self = [super initWithBundle:bundle])) {
    [[Preferences sharedPreferences] setBundle:bundle];
  }

  return self;
}

- (void)mainViewDidLoad {
  self.updater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
  [updater resetUpdateCycle];
  FFYDaemonController *dC = [[FFYDaemonController alloc] init];
  self.daemonController = dC;
  [dC release];

  daemonController.launchPath     = [[[Preferences sharedPreferences] preferences] objectForKey:@"org.ivanvc.mongo.launchPath"];
  daemonController.startArguments = [[Preferences sharedPreferences] argumentsWithParameters];

  daemonController.daemonStartedCallback = ^(NSNumber *pid) {
    [theSlider setState:NSOnState animate:YES];
  };

  daemonController.daemonFailedToStartCallback = ^(NSString *reason) {
    [theSlider setState:NSOffState animate:YES];
  };

  daemonController.daemonStoppedCallback = ^(void) {
    [theSlider setState:NSOffState animate:YES];
  };

  daemonController.daemonFailedToStopCallback = ^(NSString *reason) {
    [theSlider setState:NSOnState animate:YES];
  };

  [theSlider setState:daemonController.isRunning ? NSOnState : NSOffState];
  [launchPathTextField setStringValue:[[[Preferences sharedPreferences] preferences] objectForKey:@"org.ivanvc.mongo.launchPath"]];
}

//- (void)daemonStopped {
//  [theSlider setState:NSOffState animate:YES];
//}
//
//- (void)daemonStarted {
//  [theSlider setState:NSOnState animate:YES];
//}

- (void)dealloc {
  [updater release];
  [daemonController release];

  [super dealloc];
}

- (IBAction)startStopDaemon:(id)sender {
  daemonController.launchPath     = [[[Preferences sharedPreferences] preferences] objectForKey:@"org.ivanvc.mongo.launchPath"];
  daemonController.startArguments = [[Preferences sharedPreferences] argumentsWithParameters];

  if (theSlider.state == NSOffState)
    [daemonController stop];
  else
    [daemonController start];
}

- (IBAction)locateBinary:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setCanChooseFiles:YES];

  if ([openPanel runModalForDirectory:nil file:nil] == NSOKButton) {
    [launchPathTextField setStringValue:[openPanel filename]];
    [[[Preferences sharedPreferences] preferences] setObject:[launchPathTextField stringValue] forKey:@"org.ivanvc.mongo.launchPath"];
  }
}

@end
