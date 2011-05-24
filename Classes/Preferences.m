//
//  Properties.m
//  mongodb.prefpane
//
//  Created by Ivan on 5/23/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences
@synthesize preferences;
@synthesize bundle;

#pragma mark - Singleton

static Preferences *sharedPreferences = nil;

+ (Preferences *)sharedPreferences {
	@synchronized(self) {
    if (!sharedPreferences)
      [[self alloc] init];

    return sharedPreferences;
  }

	return sharedPreferences;
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
    if (!sharedPreferences) {
      sharedPreferences = [super allocWithZone:zone];
			return sharedPreferences;
		}
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax;
}

- (void)release {}

- (id)autorelease {
	return self;
}

#pragma mark - Initialization

- (id)init {
  self = [super init];
  if (self) {
    self.preferences = [NSUserDefaults standardUserDefaults];
  }

  return self;
}

#pragma mark - Custom Setters and Getters

- (void)setBundle:(NSBundle *)aBundle {
  if (bundle != aBundle) {
    [bundle release];
    self.bundle = [bundle retain];
    if (bundle) {
      NSString *path = [bundle pathForResource:@"defaultPreferences" ofType:@"plist"];
      [preferences registerDefaults:[NSDictionary dictionaryWithContentsOfFile:path]];
    }
  }
}

#pragma mark - Memory management

- (void)dealloc {
  [preferences release];
  [bundle release];

  [super dealloc];
}

@end
