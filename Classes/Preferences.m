//
//  Properties.m
//  mongodb.prefpane
//
//  Created by Ivan on 5/23/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences
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

- (oneway void)release {}

- (id)autorelease {
	return self;
}

#pragma mark - Read/Write User defaults

- (id)objectForUserDefaultsKey:(NSString *)key {	
	CFPropertyListRef obj = CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)[bundle bundleIdentifier]);
	return [(id)CFMakeCollectable(obj) autorelease];
}

- (void)setObject:(id)value forUserDefaultsKey:(NSString *)key {
  CFPreferencesSetValue((CFStringRef)key, value, (CFStringRef)[bundle bundleIdentifier], kCFPreferencesCurrentUser,  kCFPreferencesAnyHost);
  CFPreferencesSynchronize((CFStringRef)[bundle bundleIdentifier], kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

- (NSArray *)argumentsWithParameters {
  NSMutableArray *theArgumentsWithParameters = [NSMutableArray array];
  NSArray *parameters = [self objectForUserDefaultsKey:@"parameters"];

  [[self objectForUserDefaultsKey:@"arguments"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *argument  = obj;
    NSString *parameter = [[parameters objectAtIndex:idx] stringByExpandingTildeInPath];
    
    if ([argument length] && [argument characterAtIndex:0] == '-') {
      [theArgumentsWithParameters addObject:argument];
      if ([parameter length])
        [theArgumentsWithParameters addObject:parameter];
    }
  }];
  
  return (NSArray *)theArgumentsWithParameters;
}

#pragma mark - Custom Setters and Getters

- (void)setBundle:(NSBundle *)aBundle {
  if (bundle != aBundle) {
    [bundle release];
    bundle = [aBundle retain];

    if (bundle) {
      if (![self objectForUserDefaultsKey:@"arguments"])
        [self setObject:[NSArray array] forUserDefaultsKey:@"arguments"];
      if (![self objectForUserDefaultsKey:@"parameters"])
        [self setObject:[NSArray array] forUserDefaultsKey:@"parameters"];
      if (![self objectForUserDefaultsKey:@"launchPath"]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *location = @"";

        if([fileManager fileExistsAtPath:@"/usr/local/bin/mongod"])
          location = @"/usr/local/bin/mongod";
        else if ([fileManager fileExistsAtPath:@"/usr/bin/mongod"])
          location = @"/usr/bin/mongod";
        else if ([fileManager fileExistsAtPath:@"/bin/mongod"])
          location = @"/bin/mongod";
        else if ([fileManager fileExistsAtPath:@"/sbin/mongod"])
          location = @"/sbin/mongod";
        else if ([fileManager fileExistsAtPath:@"/opt/bin/mongod"])
          location = @"/opt/bin/mongod";

        [self setObject:location forUserDefaultsKey:@"launchPath"];
      }
    }
  }
}

#pragma mark - Memory management

- (void)dealloc {
  [bundle release];

  [super dealloc];
}

@end
