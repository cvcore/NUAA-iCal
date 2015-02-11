//
//  CourseInfo.h
//  CalendarImporter
//
//  Created by Core on 2/5/15.
//  Copyright (c) 2015 c0r3d3v. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLObjectMapper.h"

@interface CourseInfo : NSObject <XMLMappedObject>

@property NSString *unit;
@property NSString *weekDay;
@property NSArray *weekNum;
@property NSString *length;
@property (copy) NSString *roomID;

@property (copy) NSString *name;
@property (copy) NSString *instructor;
@property (copy) NSString *instructorID;
@property (readonly) NSString *dsID;
@property (copy) NSString *courseUID;
@property (copy) NSString *courseID;
@property (copy) NSString *campus;

- (instancetype)initWithDataSetID:(NSString *)dsID;

@property BOOL selected;

@end
