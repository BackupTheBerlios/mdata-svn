//  MDAConnection.h
//  mData
//
//  Created by Nick Hristov on 1/19/05.
//  Copyright 2005 Nick Hristov. All rights reserved.

// This is the abstract connection class for the mData framework.
// All connection classes should subclass this class and override the 
// methods in the various categories as defined by this class. The
// implementation of all categories is not required, however, the 
// following categories MUST be implemented: 
//
//	ConnectionHandling
//	StatementHandling
//	SchemaHandling
//
//  MDAConnection and its subclasses are a class cluster.

#import <Cocoa/Cocoa.h>

#define CONN_CONNECTING 0
#define CONN_UP 1
#define CONN_DOWN -1


@class MDAPreparedStatement;
@class MDADbResult;

@interface MDAConnection : NSObject {
	@protected
	int _connection_state;			// keep the connection state here
	
	NSMutableArray * _activeStatements;	// holds active handles that must be 
										// deallocated before disconnect
}

- (id) init;
+ (MDAConnection *) postgreConnection;
@end

@interface MDAConnection (ConnectionHandling)
- (MDADbResult *) connectWithPreferences: (NSDictionary *) preferences;
- (void) disconnect;
@end

@interface MDAConnection (StatementHandling)
- (MDAPreparedStatement *) preparedStatementWithString: (NSString *) aString;
- (MDADbResult *) doQueryWithString: (NSString *) aString;
@end

@interface MDAConnection (SchemaHandling)
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

@interface MDAConnection (TransactionHandling)
- (void) setAutoCommit: (BOOL) commitAutomatically;
- (BOOL) autoCommit;

- (MDADbResult *) beginTransaction;
- (MDADbResult *) commitTransaction;
- (MDADbResult *) rollbackTransaction;
- (BOOL) databaseSupportsTransactions;
@end

@interface MDAConnection (FunctionHandling)
- (MDADbResult *) createFunctionWithName: (NSString *) functionName 
								code: (NSData *) functionCode
								language: (NSString *) languageName;

- (NSArray *) supportedFunctionLanguages;
- (MDADbResult *) dropFunctionWithName: (NSString *) functionName;
- (BOOL) databaseSupportsFunctions;
@end

@interface MDAConnection (TriggerHandling)
- (MDADbResult *) createTriggerWithName: (NSString *) triggerName
						functionName: (NSString *) functionName
						event: (NSString *) event
						tableName: (NSString *) tableName;

- (MDADbResult *) dropTriggerWithName: (NSString *) triggerName
						forTableWithName: (NSString *) tableName;

- (NSArray *) supportedTriggerEvents;
- (BOOL) databaseSupportsTriggers;
@end

@interface MDAConnection (ViewsHandling)
- (MDADbResult *) createNamedView: (NSString *) viewName forQuery: (NSString *) query; 
- (MDADbResult *) dropViewWithName: (NSString *) viewName;
- (BOOL) databaseSupportsViews;
@end