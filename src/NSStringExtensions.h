//
//  NSStringExtensions.h
//  MDAccess
//
//  Created by Nick Hristov on 1/21/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMutableString (MDAExtensions) 
- (void) escapeCharacter: (char) c;

@end
