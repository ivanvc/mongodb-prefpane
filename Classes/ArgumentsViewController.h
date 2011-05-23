//
//  ArgumentsViewController.h
//  mongodb.prefpane
//
//  Created by Ivan on 5/18/11.
//  Copyright 2011 Iván Valdés Castillo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArgumentsViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {
  NSTableView *tableView;
@private
  NSMutableArray *arguments;
}

@property (nonatomic, retain) IBOutlet NSTableView *tableView;

- (IBAction)addRow:(id)sender;

@end
