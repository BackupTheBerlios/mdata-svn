//
//  NSStringExtensions.m
//  MDAccess
//
//  Created by Nick Hristov on 1/21/05.
//  Copyright 2005 Nick Hristov. All rights reserved.

#import "NSStringExtensions.h"

@implementation NSMutableString (MDAExtensions)
- (void) escapeCharacter: (char) c
{
	NSScanner * search;
	NSCharacterSet * set;
	char buffer[2];
	char insertion[2];
	int location;
	BOOL done;
	done = NO;
	buffer[0] = c;
	buffer[1] = '\0';
	
	insertion[0] = '\'';
	insertion[1] = '\0';
	
	set = [NSCharacterSet characterSetWithCharactersInString: 
				[NSString stringWithUTF8String:buffer]];
	
	search = [[NSScanner alloc] initWithString: self];
	[search setScanLocation: 0];
	while (done == NO) {
		[search scanUpToCharactersFromSet: set intoString:nil];
		location = [search scanLocation];
		[self insertString:[NSString stringWithUTF8String:insertion] atIndex: (location -1)];
	}
	[search release];
}

@end
