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
    self.arguments  = [NSMutableArray arrayWithArray:[[[Preferences sharedPreferences] preferences] objectForKey:@"arguments"]];
    self.parameters = [NSMutableArray arrayWithArray:[[[Preferences sharedPreferences] preferences] objectForKey:@"parameters"]];
  }

  return self;
}

#pragma mark - Preferences management

- (void)updatePreferences {
  [[[Preferences sharedPreferences] preferences] setObject:[NSArray arrayWithArray:arguments] forKey:@"arguments"];
  [[[Preferences sharedPreferences] preferences] setObject:[NSArray arrayWithArray:parameters] forKey:@"parameters"];
}

#pragma mark - Table View Tasks

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return [arguments count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([[tableColumn identifier] isEqualToString:@"argumentColumn"])
    return [arguments objectAtIndex:row];
  if ([[tableColumn identifier] isEqualToString:@"parametersColumn"])
    return [parameters objectAtIndex:row];

  return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  if ([[tableColumn identifier] isEqualToString:@"argumentColumn"])
    [arguments replaceObjectAtIndex:row withObject:(NSString *)object];
  if ([[tableColumn identifier] isEqualToString:@"parametersColumn"])
    [parameters replaceObjectAtIndex:row withObject:(NSString *)object];

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
  [arguments removeObjectAtIndex:[tableView selectedRow]];
  [parameters removeObjectAtIndex:[tableView selectedRow]];

  [self updatePreferences];
  [self.tableView reloadData];
}

- (IBAction)addRow:(id)sender {
  [arguments addObject:[NSString stringWithFormat:@"-argument", [arguments count]]];
  [parameters addObject:[NSString stringWithFormat:@"parameter", [parameters count]]];

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
