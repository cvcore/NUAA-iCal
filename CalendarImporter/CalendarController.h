//
//  CalendarController.h
//  CalendarImporter
//
//  Created by Core on 2/1/15.
//  Copyright (c) 2015 c0r3d3v. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CourseInfo.h"

@interface CalendarController : NSWindowController

@property NSMutableArray *courses;

- (void)transferXmlString:(NSString *)string;

@end
