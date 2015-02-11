//
//  WindowController.m
//  CalendarImporter
//
//  Created by Core on 1/31/15.
//  Copyright (c) 2015 c0r3d3v. All rights reserved.
//

#import "WindowController.h"
#import "Soap.h"
#import <EventKit/EventKit.h>

@interface WindowController ()

@property EKEventStore *eventStore;
@property BOOL tableModified;
@property NSMutableDictionary *calendarPopUpDic;

@end

@implementation WindowController

#pragma mark - initializations

- (void)populateSemesterPopUp {
	//2014-2015 autumn(1), spring(2) starting from 2014 to current date
    NSLocale *cnLocale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
	NSDateComponents *components = [[cnLocale objectForKey:NSLocaleCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth) fromDate:[NSDate date]];
	NSUInteger currentYear = [components year];
    NSUInteger currentMonth = [components month];
	for (NSUInteger year = 2014; (currentMonth <= 6 && year < currentYear) || (currentMonth > 6 && year < currentYear + 1); year++) {
		NSString *semesterYearRange = [NSString stringWithFormat:@"%lu-%lu", year, year+1];
		[self.semesterPopUp addItemWithTitle:semesterYearRange];
		NSLog(@"%@", semesterYearRange);
	}
}

- (void)populateCourseInfoByXmlString:(NSString *)xmlString {
    NSData *data = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    XMLObjectMapper *mapper = [[XMLObjectMapper alloc] initWithData:data delegate:self];
    [self.courses removeAllObjects];
    self.tableModified = false;
    [self willChangeValueForKey:@"courses"];
    [mapper mapElementsToObjects];
    [self didChangeValueForKey:@"courses"];
}

- (void)populateCalendarPopUp {
    if (_eventStore == nil) {
        _eventStore = [[EKEventStore alloc] init];
        [_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            NSLog(@"%hhd", granted);
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }];
    }
    _calendarPopUpDic = [[NSMutableDictionary alloc] init];
    for (EKCalendar *calendar in [_eventStore calendarsForEntityType:EKEntityTypeEvent]) {
        [self.calendarPopUp addItemWithTitle:calendar.title];
        [self.calendarPopUpDic setObject:calendar forKey:calendar.title];
    }
}

- (void)awakeFromNib {
    [self populateSemesterPopUp];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"NUAAicon" ofType:@"png"];
    NSImage *logo = [[NSImage alloc] initWithContentsOfFile:path];
    _logoImageView.image = logo;
    
    _courses = [[NSMutableArray alloc] init];
    
    [self populateCalendarPopUp];
}

#pragma mark - helper functions

- (BOOL)selectedSemesterIsValid {
	NSLog(@"%lu %lu", [_semesterPopUp indexOfSelectedItem], [_seasonPopUp indexOfSelectedItem]);
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:[NSDate date]];
	if (([_semesterPopUp indexOfSelectedItem] == [_semesterPopUp numberOfItems] - 1) &&
		[_seasonPopUp indexOfSelectedItem] == 1 &&
        [components month] > 6) {
		return NO;
	}
	return YES;
}

- (NSDate *)calculateFirstSemesterMonday {
    NSLocale *cnLocale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
    NSArray *yearArray = [self.semesterPopUp.titleOfSelectedItem componentsSeparatedByString:@"-"];
    NSDate *approx;
    NSDateComponents *approxComp = [[NSDateComponents alloc] init];
    if ([self.seasonPopUp indexOfSelectedItem] == 0) {
        [approxComp setDay:1];
        [approxComp setMonth:9];
        [approxComp setYear:[[yearArray objectAtIndex:0] integerValue]];
        approx = [[cnLocale objectForKey:NSLocaleCalendar] dateFromComponents:approxComp];
    } else {
        [approxComp setDay:1];
        [approxComp setMonth:3];
        [approxComp setYear:[[yearArray objectAtIndex:1] integerValue]];
        approx = [[cnLocale objectForKey:NSLocaleCalendar] dateFromComponents:approxComp];
    }
    NSDateComponents *weekdayComp = [[cnLocale objectForKey:NSLocaleCalendar] components:NSCalendarUnitWeekday fromDate:approx];
    NSUInteger weekday = [weekdayComp weekday];
    
    NSDate *exact;
    if (weekday == 1) {
        exact = [approx dateByAddingTimeInterval:(60 * 60 * 24)];
    } else if (weekday == 6) {
        exact = [approx dateByAddingTimeInterval:(60 * 60 * 24 * 2)];
    } else {
        exact = [approx dateByAddingTimeInterval:(60 * 60 * 24 * (2 - weekday))];
    }
    return exact;
}

#pragma mark - Actions

- (IBAction)downloadCalendar:(id)sender {
    NSString *year = [[_semesterPopUp selectedItem] title];
    NSUInteger seasonInt = [_seasonPopUp indexOfSelectedItem] + 1;
    NSString *season = [[NSString alloc] initWithFormat:@"%lu", seasonInt];
    NSString *sid = [_sidText stringValue];
    NSString *methodName = @"GetCourseTableByXh";
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:year, @"xn", season, @"xq", sid, @"xh", nil];
    SoapUtility *su = [[SoapUtility alloc] initFromFile:@"NUAADedWebService"];
    NSString *postData = [su BuildSoapwithMethodName:methodName withParas:params];
    SoapService *soapRequest = [[SoapService alloc] init];
    soapRequest.PostUrl = @"http://ded.nuaa.edu.cn//NetEa/Services/WebService.asmx";
    soapRequest.SoapAction = [su GetSoapActionByMethodName:methodName SoapType:SOAP];
    [soapRequest PostAsync:postData
                   Success:^(NSString *xmlString) {
                       NSLog(@"%@", xmlString);
                       [self populateCourseInfoByXmlString:xmlString];
                       [self.confimButton setEnabled:YES];
                   } falure:^(NSError *response) {
                       NSLog(@"%@", response);
                   }];
    
}

- (IBAction)addToCalendar:(id)sender {
    if ([self.calendarPopUp indexOfSelectedItem] == 0) {
        NSLog(@"Invalid Selection!");
        [self.mainWindow makeFirstResponder:self.calendarPopUp];
        return;
    }
    
    EKCalendar *calendar = [self.calendarPopUpDic objectForKey:self.calendarPopUp.titleOfSelectedItem];

    for (CourseInfo *course in self.courses) {

        NSDate *semesterDate = [self calculateFirstSemesterMonday];
        NSInteger hours = 60*60;
        NSInteger minutes = 60;
        NSArray *timeForClass = [NSArray arrayWithObjects:
                                 @(8*hours),                     // 1. 8:00 - 8:50
                                 @(8*hours + 55*minutes),        // 2. 8:55 - 9:45
                                 @(10*hours + 15*minutes),       // 3. 10:15 - 11:05
                                 @(11*hours + 15*minutes),       // 4. 11:10 - 12:00
                                 @(14*hours),                    // 5. 14:00 - 14:50
                                 @(14*hours + 55*minutes),       // 6. 14:55 - 15:45
                                 @(16*hours + 15*minutes),       // 7. 16:15 - 17:05
                                 @(17*hours + 10*minutes),       // 8. 17:10 - 18:00
                                 @(18*hours + 30*minutes),       // 9. 18:30 - 19:20
                                 @(20*hours + 25*minutes), nil]; // 10. 19.25 - 20:15
        
        for (NSString *weekIdx in course.weekNum) {
            NSDate *startDate, *endDate;
            NSTimeInterval days, weeks;
            days = 60 * 60 * 24;
            weeks = days * 7;

			startDate = [NSDate dateWithTimeInterval:weeks * ([weekIdx integerValue] - 1) + days * ([course.weekDay integerValue] - 1) + [[timeForClass objectAtIndex:([course.unit integerValue] - 1)] integerValue] sinceDate:semesterDate];
            if ([course.length isEqualToString:@"1"]) {
                endDate = [startDate dateByAddingTimeInterval:50 * 60];
            } else if ([course.length isEqualToString:@"2"]) {
                endDate = [startDate dateByAddingTimeInterval:(50 + 55) * 60];
            } else {
                endDate = [startDate dateByAddingTimeInterval:(50 + 55 + 55) * 60];
            }
            NSString *locationString = [NSString stringWithFormat:@"%@ %@", course.roomID, course.campus];
            NSString *noteString = [NSString stringWithFormat:@"%@ %@ %@", course.instructor, course.instructorID, course.courseUID];
            
            EKEvent *calendarEvent = [EKEvent eventWithEventStore:_eventStore];
            calendarEvent.title = course.name;
            calendarEvent.startDate = startDate;
            calendarEvent.endDate = endDate;
            calendarEvent.allDay = NO;
            calendarEvent.calendar = calendar;
            calendarEvent.location = locationString;
            calendarEvent.notes = noteString;
            
            NSError *eventStoreErr;
            [_eventStore saveEvent:calendarEvent span:EKSpanThisEvent commit:NO error:&eventStoreErr];
            
        }
    }
    NSError *eventStoreErr;
    [_eventStore commit:&eventStoreErr];
}

- (IBAction)updateSemesterYear:(id)sender {
	if (![self selectedSemesterIsValid]) {
		[_seasonPopUp selectItemAtIndex:0];
	}
}

- (IBAction)updateSemesterSeason:(id)sender {
	if (![self selectedSemesterIsValid]) {
		[_semesterPopUp selectItemAtIndex:[_semesterPopUp indexOfSelectedItem] - 1];
	}
}

#pragma mark - XMLObjectMapperDelegate

- (id <XMLMappedObject>)mapper:(XMLObjectMapper *)mapper startElementNamed:(NSString *)elementName withAttributes:(NSDictionary *)attributes currentObject:(CourseInfo<XMLMappedObject> *)currentObject {
    if ([elementName isEqualToString:@"ds"] &&
        (!_tableModified || [attributes objectForKey:@"diffgr:hasChanges"])) {
        if (!_tableModified && [attributes objectForKey:@"diffgr:hasChanges"]) {
            _tableModified = YES;
            [self.courses removeAllObjects]; // use the latest modified ones
        }
        return [[CourseInfo alloc] initWithDataSetID:[attributes objectForKey:@"diffgr:id"]];
    }
    return currentObject;
}

- (void)mapper:(XMLObjectMapper *)mapper endElementNamed:(NSString *)elementName currentObject:(CourseInfo<XMLMappedObject> *)currentObject {
    if ([elementName isEqualToString:@"ds"] && currentObject) {
        [_courses addObject:currentObject];
    }
    
}

@end
