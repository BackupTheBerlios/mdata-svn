//  MDAStatement.h
//  MDAccess
//
//  Created by Nick Hristov on 1/19/05.
//  Copyright 2005 Nick Hristov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDAConnection;
@class MDADbResult;

#define MDAST_VOID		0
#define MDAST_PREPARED  1
#define MDAST_EXECUTING 2
#define MDAST_EXECUTED  4
#define MDAST_HAS_DATA  8


@interface MDAPreparedStatement
- (id) initWithConnection:(MDAConnection *) openConnection query: (NSString *) queryStatement;
- (MDADbResult *) executeWithParameters: (NSArray *) parameters;
- (MDADbResult *) nonBlockingExecuteWithParameters: (NSArray *) parameters
					callBackObject: (id) object
					selector: (SEL) aSelector;
- (NSDictionary *) nextRow;
- (int) numberOfRows;
- (BOOL) supportsNonBlockingExecution;
@end
