//
//  CourseInfo.m
//  CalendarImporter
//
//  Created by Core on 2/5/15.
//  Copyright (c) 2015 c0r3d3v. All rights reserved.
//

#import "CourseInfo.h"

@interface CourseInfo() <XMLMappedObject>

@end

@implementation CourseInfo

- (instancetype)initWithDataSetID:(NSString *)dsID {
    self = [super init];
    if (self) {
        _dsID = [dsID copy];
    }
    return self;
}

- (void)mapper:(XMLObjectMapper *)mapper foundString:(NSString *)string forElementNamed:(NSString *)elementName
{
    if ([elementName isEqualToString:@"kcm"]) {
        self.name = string;
    } else if ([elementName isEqualToString:@"jsm"]) {
        self.instructor = string;
    } else if ([elementName isEqualToString:@"xiaoqu"]) {
        self.campus = string;
    } else if ([elementName isEqualToString:@"week"]) {
        self.weekDay = string;
    } else if ([elementName isEqualToString:@"unit"]) {
        self.unit = string;
    } else if ([elementName isEqualToString:@"roomid"]) {
        self.roomID = string;
    } else if ([elementName isEqualToString:@"weeks"]) {
        self.weekNum = [string componentsSeparatedByString:@","];
    } else if ([elementName isEqualToString:@"jsh"]) {
        self.instructorID = string;
    } else if ([elementName isEqualToString:@"lsjs"]) {
        self.length = string;
    } else if ([elementName isEqualToString:@"kcxh"]) {
        self.courseUID = string;
    } else if ([elementName isEqualToString:@"kch"]) {
        self.courseID = string;
    }
}

@end
