//
//  AppDelegate.m
//  CalendarImporter
//
//  Created by Core on 10/20/14.
//  Copyright (c) 2014 c0r3d3v. All rights reserved.
//

#import "AppDelegate.h"

#import <EventKit/EventKit.h>

#import "hpple/TFHpple.h"
#import "hpple/TFHppleElement.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSArray *scheduleArray;
@property (nonatomic, strong) NSDictionary *columnDictionary;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) NSDictionary *Setings;
@property (nonatomic, strong) EKCalendar *defaultCalendar;
@end

@implementation AppDelegate

- (void)loadScheduleWithSID:(NSString *)sid {
	NSString *urlString = [NSString stringWithFormat:@"http://ded.nuaa.edu.cn/JwSys/Manager/Module/DedSys/Schedule/Show/PersonalSchedule.aspx?xh=%@", sid];
	NSURL *url = [NSURL URLWithString:urlString];
	NSData *scheduleData = [NSData dataWithContentsOfURL:url];
	TFHpple *scheduleParser = [TFHpple hppleWithHTMLData:scheduleData];
	NSString *scheduleXpathQueryString = @"//table[@id='GrwCourseTablePrint']/tr";
	_scheduleArray = [scheduleParser searchWithXPathQuery:scheduleXpathQueryString];
	
	TFHppleElement *columnAdder = [_scheduleArray objectAtIndex:0];
	NSMutableArray *keyArray = [[NSMutableArray alloc] init];
	NSMutableArray *valueArray = [[NSMutableArray alloc] init];
	NSUInteger idx = 1;
	for (TFHppleElement *headerElem in [columnAdder children]) {
//		NSLog(@"%@", [headerElem text]);
		if ([headerElem text] == nil) {
			continue;
		}
		NSTableColumn *tc = [[NSTableColumn alloc] init];
		[tc setIdentifier:[headerElem text]];
		[tc.headerCell setStringValue:[headerElem text]];
		[self.calTable addTableColumn:tc];
		[keyArray addObject:[headerElem text]];
		[valueArray addObject:[NSNumber numberWithInteger:idx]];
		idx++;
	}
	[self.calTable.headerView setNeedsDisplay:true];
	_columnDictionary = [NSDictionary dictionaryWithObjects:valueArray forKeys:keyArray];
	
	[self.calTable reloadData];
	[self.addToCalendar setEnabled:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self.calTable setDelegate:self];
	[self.calTable setDataSource:self];
	[self.addToCalendar setEnabled:NO];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Settings" ofType:@"plist"];
    self.Setings = [NSDictionary dictionaryWithContentsOfFile:path];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}


- (IBAction)downloadCalendar:(id)sender {
	NSString *studentID = self.sidText.stringValue;
	[self.downloadIndicator startAnimation:self];
	[self loadScheduleWithSID:studentID];
	[self.downloadIndicator stopAnimation:self];
}

- (IBAction)addToCalendar:(id)sender {
	if (_eventStore == nil) {
		_eventStore = [[EKEventStore alloc] init];
		[_eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
			});
		}];
	}
    EKCalendar *calendar = [self getCalendarbyTitl:@"NuaaTimeTable"];

	NSEnumerator *schdEnum = [_scheduleArray objectEnumerator];
	[schdEnum nextObject];
	for (TFHppleElement *schdItem in schdEnum) {
		NSUInteger kcmCol = [[_columnDictionary objectForKey:@"kcm"] integerValue];
		NSUInteger weeksCol = [[_columnDictionary objectForKey:@"weeks"] integerValue];
		NSUInteger classCol = [[_columnDictionary objectForKey:@"unit"] integerValue];
		NSUInteger roomCol = [[_columnDictionary objectForKey:@"roomid"] integerValue];
		NSUInteger weekDayCol = [[_columnDictionary objectForKey:@"week"] integerValue];
		
		NSString *title = [[[schdItem children] objectAtIndex:kcmCol] text];
		NSDate *semesterDate = [self.semesterDatePicker dateValue];
		NSString *weeksString = [[[schdItem children] objectAtIndex:weeksCol] text];
		NSString *locationString = [[[schdItem children] objectAtIndex:roomCol] text];
		NSArray *weeksArray = [weeksString componentsSeparatedByString:@","];
		NSInteger classNum = ([[[[schdItem children] objectAtIndex:classCol] text] integerValue] - 1) / 2;
		NSInteger weekDay = [[[[schdItem children] objectAtIndex:weekDayCol] text] integerValue] - 1;
		
		NSArray *timeForClass = [NSArray arrayWithObjects:
								 @(8*60*60),
								 @(10*60*60 + 15*60),
								 @(14*60*60),
								 @(16*60*60 + 15*60),
								 @(18*60*60 + 30*60), nil];
		for (NSString *weekIdx in weeksArray) {
			NSDate *startDate, *endDate;
			NSTimeInterval days, weeks;
			days = 60 * 60 * 24;
			weeks = days * 7;
			
			startDate = [NSDate dateWithTimeInterval:weeks * ([weekIdx integerValue] - 1) + days * weekDay + [[timeForClass objectAtIndex:classNum] integerValue]
										   sinceDate:semesterDate];
			endDate = [startDate dateByAddingTimeInterval:(60 + 45) * 60];
			EKEvent *classEvent = [EKEvent eventWithEventStore:_eventStore];
			classEvent.title = title;
			classEvent.startDate = startDate;
			classEvent.endDate = endDate;
			classEvent.allDay = NO;
			classEvent.calendar = calendar; //TODO: add a pickup
			classEvent.location = locationString;
			
			NSError *e;
			[_eventStore saveEvent:classEvent span:EKSpanThisEvent commit:NO error:&e];
			
		}
	}
	NSError *e;
	[_eventStore commit:&e];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
	if (_scheduleArray) {
		return _scheduleArray.count - 1;
	}
	return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (_columnDictionary && _scheduleArray) {
		NSUInteger colIdx = [[_columnDictionary objectForKey:tableColumn.identifier] integerValue];
		NSTextField *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
		if (result == nil) {
			result = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 10, 4)];
			result.identifier = tableColumn.identifier;
		}
		NSString *item = [[[[_scheduleArray objectAtIndex:(row + 1)] children] objectAtIndex:colIdx] text];
		if (item) {
			result.stringValue = item;
		}
		return result;
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	id result = nil;
	if (_columnDictionary && _scheduleArray) {
		NSUInteger colIdx = [[_columnDictionary objectForKey:tableColumn.identifier] integerValue];
		NSString *item = [[[[_scheduleArray objectAtIndex:(row + 1)] children] objectAtIndex:(colIdx)] text];
		if (item) {
			result = item;
		}
	}
	return result;
}

// ljlin

- (EKCalendar*)getCalendarbyTitl:(NSString*)titl{

    EKSource *localSource = nil;
    EKCalendar *cal = nil;
    NSString *identifier = self.Setings[@"identifier"];
    for (EKSource *source in self.eventStore.sources)
    {
        if (source.sourceType == EKSourceTypeCalDAV &&
            [source.title isEqualToString:@"iCloud"])
        {
            localSource = source;
            break;
        }
    }
    if ([identifier isEqualToString:@""])
    {
        cal = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
        cal.title = titl;
        cal.source = localSource;
        self.defaultCalendar = cal;
        [self.eventStore saveCalendar:cal commit:YES error:nil];
        NSLog(@"creat cal id = %@", cal.calendarIdentifier);
        [self.Setings setValue:cal.calendarIdentifier forKey:@"identifier"];
        NSString *path = [[NSBundle mainBundle]pathForResource:@"Settings" ofType:@"plist"];
        [self.Setings writeToFile:path atomically:YES];
    }
    else{
        cal=[self.eventStore calendarWithIdentifier:identifier];
        self.defaultCalendar = cal;
        NSLog(@"get cal id = %@", cal.calendarIdentifier);
    }

    //NSLog(@"%lu",(unsigned long)self.eventStore.sources.count);
    
    NSArray *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
    
    for (EKCalendar* cal in calendars){
        NSLog(@"titl = %@",cal.title);
        NSLog(@"source = %@",cal.source.title);
        NSLog(@"id = %@",cal.calendarIdentifier);
        NSLog(@"\n");
    }
    return cal;
}

@end
