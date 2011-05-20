//
//  mongoPref.h
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import <PreferencePanes/PreferencePanes.h>

@class DaemonController;
@class MBSliderButton;
@class SUUpdater;

@interface mongoPref : NSPreferencePane {
  MBSliderButton   *theSlider;
  DaemonController *dC;
  NSTextField      *theArguments;
  NSUserDefaults   *preferences;
  NSDictionary     *preferencesDict;
@private
  SUUpdater        *updater;
}

@property (nonatomic, retain) IBOutlet MBSliderButton	*theSlider;
@property (nonatomic, retain) IBOutlet NSTextField *theArguments;

- (void) mainViewDidLoad;
- (void) daemonStopped;
- (void) daemonStarted;
- (IBAction) startStopDaemon:(id)sender;
- (IBAction) changeArguments:(id)sender;

@end