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
    bundle = [aBundle retain];

    if (bundle) {
      NSString *path = [bundle pathForResource:@"defaultPreferences" ofType:@"plist"];
      [preferences registerDefaults:[NSDictionary dictionaryWithContentsOfFile:path]];
    }
  }
}

- (NSArray *)argumentsWithParameters {
  NSMutableArray *theArgumentsWithParameters = [NSMutableArray array];

  [[preferences objectForKey:@"arguments"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *argument  = obj;
    NSString *parameter = [[preferences objectForKey:@"parameters"] objectAtIndex:idx];

    if ([argument length] && [argument characterAtIndex:0] == '-')
      [theArgumentsWithParameters addObject:[NSString stringWithFormat:@"%@ %@", argument, parameter]];
  }];

  return [NSArray arrayWithArray:theArgumentsWithParameters];
}

#pragma mark - Memory management

- (void)dealloc {
  [preferences release];
  [bundle release];

  [super dealloc];
}

@end
