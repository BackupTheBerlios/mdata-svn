//  MDAPgConnection.h
//  MDAccess
//
//  Created by Nick Hristov on 1/19/05.
//  Copyright 2005 Nick Hristov. All rights reserved.

#import <Cocoa/Cocoa.h>
#include <libpq/libpq-fe.h>
#import "MDAConnection.h"

@class MDAPgStatement;
@class MDAPgResult;

@interface MDAPgConnection : MDAConnection {
	@protected
		struct PGConn * connection;
	@private
		int connection_state;
		BOOL useBlockingCall;
		id _callback_object;
		NSThread * connectionPoller;
		NSMutableDictionary * preparedStatements;
}
- (id) init;
@end

@interface MDAPgConnection (ConnectionHandling)
- (MDADbResult *) connectWithPreferences: (NSDictionary *) preferences;
- (void) disconnect;
@end

@interface MDAPgConnection (StatementHandling)
- (MDADbResult *) doQueryWithString: (NSString *) aString;
@end

@interface MDAPgConnection (SchemaHandling)
- (NSDictionary *) schemaForTableWithName: (NSString *) tableName;
- (NSArray *) tableNames;
- (MDADbResult *) dropTableWithName: (NSString *) tableName;
- (MDADbResult *) createTableWithName: (NSString *) tableName
						   withSchema: (NSDictionary *) newTableSchema;

- (MDADbResult *) dropColumnWithName: (NSString *) columnName 
					forTableWithName: (NSString *) tableName;

- (MDADbResult *) addColumnWithProperties: (NSDictionary *) columnProperties 
						 forTableWithName: (NSString *) tableName;

- (MDADbResult *) changeColumnWithName: (NSString *) columnName 
				toColumnWithProperties: (NSDictionary *) newProperties 
					  forTableWithName: (NSString *) tableName;
@end

@interface MDAPgConnection (TransactionHandling)
- (void) setAutoCommit: (BOOL) commitAutomatically;
- (BOOL) autoCommit;

- (MDADbResult *) beginTransaction;
- (MDADbResult *) commitTransaction;
- (MDADbResult *) rollbackTransaction;
@end

@interface MDAPgConnection (FunctionHandling)
- (MDADbResult *) createFunctionWithName: (NSString *) functionName 
									code: (NSData *) functionCode
								language: (NSString *) languageName;

- (NSArray *) supportedFunctionLanguages;
- (MDADbResult *) dropFunctionWithName: (NSString *) functionName;
@end

@interface MDAPgConnection (TriggerHandling)
- (MDADbResult *) createTriggerWithName: (NSString *) triggerName
						   functionName: (NSString *) functionName
								  event: (NSString *) event
							  tableName: (NSString *) tableName;

- (MDADbResult *) dropTriggerWithName: (NSString *) triggerName
					 forTableWithName: (NSString *) tableName;

- (NSArray *) supportedTriggerEvents;
@end
