//
//  Properties.h
//  mongodb.prefpane
//
//  Created by Ivan on 5/23/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

@interface Preferences : NSObject {
  NSBundle *bundle;
}

@property (nonatomic, retain) NSBundle *bundle;

+ (Preferences *)sharedPreferences;

- (id)objectForUserDefaultsKey:(NSString *)key;
- (void)setObject:(id)value forUserDefaultsKey:(NSString *)key;
- (NSArray *)argumentsWithParameters;

@end
