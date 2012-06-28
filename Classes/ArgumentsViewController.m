//
//  ArgumentsViewController.m
//  mongodb.prefpane
//
//  Created by Ivan on 5/18/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

#import "ArgumentsViewController.h"
#import "Preferences.h"

@interface ArgumentsViewController(/* Hidden Methods*/)
@property (nonatomic, retain) NSMutableArray *arguments;
@property (nonatomic, retain) NSMutableArray *parameters;
- (void)removeArgument:(id)sender;
- (void)updatePreferences;
@end

@implementation ArgumentsViewController
@synthesize tableView;
@synthesize arguments;
@synthesize parameters;

#pragma mark - Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.arguments  = [NSMutableArray arrayWithArray:[[Preferences sharedPreferences] objectForUserDefaultsKey:@"arguments"]];
    self.parameters = [NSMutableArray arrayWithArray:[[Preferences sharedPreferences] objectForUserDefaultsKey:@"parameters"]];
  }

  return self;
}

#pragma mark - Preferences management

- (void)updatePreferences {
  [[Preferences sharedPreferences] setObject:[NSArray arrayWithArray:self.arguments]
                          forUserDefaultsKey:@"arguments"];
  [[Preferences sharedPreferences] setObject:[NSArray arrayWithArray:self.parameters]
                          forUserDefaultsKey:@"parameters"];
}

#pragma mark - Table View Tasks

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [self.arguments count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([[tableColumn identifier] isEqualToString:@"argumentColumn"])
    return [self.arguments objectAtIndex:row];
  if ([[tableColumn identifier] isEqualToString:@"parametersColumn"])
    return [self.parameters objectAtIndex:row];

  return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([[tableColumn identifier] isEqualToString:@"argumentColumn"])
    [self.arguments replaceObjectAtIndex:row withObject:(NSString *)object];
  if ([[tableColumn identifier] isEqualToString:@"parametersColumn"])
    [self.parameters replaceObjectAtIndex:row withObject:(NSString *)object];

  [self updatePreferences];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return [[tableColumn identifier] isEqualToString:@"argumentColumn"] || [[tableColumn identifier] isEqualToString:@"parametersColumn"];
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  NSCell *cell = [tableColumn dataCell];
  if ([[tableColumn identifier] isEqualToString:@"deleteColumn"]) {
    NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
    [buttonCell setButtonType:NSMomentaryPushInButton];
    [buttonCell setBezeled:YES];
    [buttonCell setBezelStyle:NSSmallSquareBezelStyle];
    [buttonCell setTitle:@"-"];
    [buttonCell setTarget:self];
    [buttonCell setAction:@selector(removeArgument:)];
    return [buttonCell autorelease];
  }
  return cell;
}

#pragma mark - Interface Builder Actions

- (void)removeArgument:(id)sender {
  [self.arguments removeObjectAtIndex:[tableView selectedRow]];
  [self.parameters removeObjectAtIndex:[tableView selectedRow]];

  [self updatePreferences];
  [self.tableView reloadData];
}

- (IBAction)addRow:(id)sender {
  [self.arguments addObject:[NSString stringWithFormat:@"-argument%d",
                             [self.arguments count]]];
  [self.parameters addObject:[NSString stringWithFormat:@"parameter%d",
                              [self.parameters count]]];

  [self.tableView reloadData];
}

#pragma mark - Memory Managment

- (void)dealloc {
  [tableView release];
  [parameters release];
  [arguments release];

  [super dealloc];
}

@end
