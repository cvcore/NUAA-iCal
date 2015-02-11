//
//  WindowController.h
//  CalendarImporter
//
//  Created by Core on 1/31/15.
//  Copyright (c) 2015 c0r3d3v. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CourseInfo.h"
#import "XMLObjectMapper.h"

@interface WindowController : NSWindowController <XMLObjectMapperDelegate>

@property (weak) IBOutlet NSPopUpButton *semesterPopUp;
@property (weak) IBOutlet NSPopUpButton *seasonPopUp;
@property (weak) IBOutlet NSTextField *sidText;
@property (weak) IBOutlet NSImageView *logoImageView;
@property (weak) IBOutlet NSPopUpButton *calendarPopUp;
@property (weak) IBOutlet NSButton *confimButton;
@property (weak) IBOutlet NSWindow *mainWindow;

@property NSMutableArray *courses;

- (IBAction)downloadCalendar:(id)sender;
- (IBAction)addToCalendar:(id)sender;
- (IBAction)updateSemesterYear:(id)sender;
- (IBAction)updateSemesterSeason:(id)sender;


@end
