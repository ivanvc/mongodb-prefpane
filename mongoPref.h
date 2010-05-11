//
//  mongoPref.h
//  mongodb.prefpane
//
//  Created by Iván Valdés Castillo on 4/12/10.
//  Copyright (c) 2010 Iván Valdés Castillo, released under the MIT license
//

#import <PreferencePanes/PreferencePanes.h>
#import "DaemonController.h"

@interface mongoPref : NSPreferencePane 
{
    NSSlider		 *theSlider;
    DaemonController *dC;
    NSTextField		 *theArguments;
    NSUserDefaults	 *preferences;
    NSDictionary	 *preferencesDict;
}

@property (nonatomic, retain) IBOutlet NSSlider		*theSlider;
@property (nonatomic, retain) IBOutlet NSTextField  *theArguments;

- (void) mainViewDidLoad;
- (void) daemonStopped;
- (void) daemonStarted;
- (IBAction) startStopDaemon:(id)sender;
- (IBAction) changeArguments:(id)sender;

@end

@interface mongoPref(Private)

- (void) checkStatus;

@end
