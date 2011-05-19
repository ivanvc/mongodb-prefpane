//
//  ArgumentsViewController.m
//  mongodb.prefpane
//
//  Created by Ivan on 5/18/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

#import "ArgumentsViewController.h"

@implementation ArgumentsViewController
@synthesize tableView;

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Initialization code here.
  }
  
  return self;
}

#pragma mark - View lifecycle

- (void)loadView {
  [super loadView];
}

#pragma mark - Table View Tasks

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return 1;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  return @"Test";
}

#pragma mark - Memory Managment

- (void)dealloc {
  [tableView release];

  [super dealloc];
}

@end
