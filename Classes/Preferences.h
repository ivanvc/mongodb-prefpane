//
//  Properties.h
//  mongodb.prefpane
//
//  Created by Ivan on 5/23/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

@interface Preferences : NSObject {
  NSUserDefaults *preferences;
  NSBundle *bundle;
}

@property (nonatomic, retain) NSUserDefaults *preferences;
@property (nonatomic, retain) NSBundle *bundle;

+ (Preferences *)sharedPreferences;

@end
