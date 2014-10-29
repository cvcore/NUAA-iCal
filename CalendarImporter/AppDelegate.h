//
//  AppDelegate.h
//  CalendarImporter
//
//  Created by Core on 10/20/14.
//  Copyright (c) 2014 c0r3d3v. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (unsafe_unretained) IBOutlet NSTableView *calTable;
@property (unsafe_unretained) IBOutlet NSTextField *sidText;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *downloadIndicator;
@property (unsafe_unretained) IBOutlet NSDatePicker *semesterDatePicker;
@property (unsafe_unretained) IBOutlet NSButton *addToCalendar;

- (IBAction)downloadCalendar:(id)sender;
- (IBAction)addToCalendar:(id)sender;

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView;
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
@end 