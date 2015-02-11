//
//  AppDelegate.m
//  CalendarImporter
//
//  Created by Core on 10/20/14.
//  Copyright (c) 2014 c0r3d3v. All rights reserved.
//

#import "AppDelegate.h"
#import "WindowController.h"

@interface AppDelegate()

@property WindowController *mainWindow;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.mainWindow = [[WindowController alloc] initWithWindowNibName:@"MainWindow"];
	[self.mainWindow showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

@end
