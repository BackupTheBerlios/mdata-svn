//  MDAConnection.m
//  MDAccess
//
//  Created by Nick Hristov on 1/30/05.
//  Copyright 2005 Nick Hristov. All rights reserved.

#import "MDAConnection.h"
#import "MDAConnectionPrivate.h"
#import "MDADbResult.h"
#import "MDAPgConnection.h"

@class MDAStatement;

@implementation MDAConnection
- (id) init
{
	[super init];
	_connection_state = CONN_DOWN;
	_activeStatements = [[NSMutableArray alloc] initWithCapacity:5];
	return self;
}

- (void) dealloc {
	if(_connection_state == CONN_UP) {	
		[_activeStatements removeAllObjects];
		[_activeStatements release];
	}
	[super dealloc];
}

+ (MDAConnection *) postgreConnection 
{
	MDAPgConnection * conn;
	conn = [[MDAPgConnection alloc] init];
	[conn autorelease];
	return conn;
}

@end


@implementation MDAConnection (ConnectionHandling)
- (MDADbResult *) connectWithPreferences: (NSDictionary *) preferences
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (void) disconnect {
	_connection_state = CONN_DOWN;
	if([_activeStatements count] > 0) {
		[self releaseAllActiveStatements];
	}
}

@end

@implementation MDAConnection (StatementHandling)
- (MDAPreparedStatement *) preparedStatementWithString: (NSString *) aString
{
	return nil;
}

- (MDADbResult *) doQueryWithString: (NSString *) aString
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}
@end

@implementation MDAConnection (SchemaHandling)
- (NSDictionary *) schemaForTableWithName: (NSString *) tableName
{
	return nil;
}

- (NSArray *) tableNames
{
	return nil;
}

- (MDADbResult *) dropTableWithName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) createTableWithName: (NSString *) tableName
						   withSchema: (NSDictionary *) newTableSchema
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) dropColumnWithName: (NSString *) columnName 
					forTableWithName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) addColumnWithProperties: (NSDictionary *) columnProperties 
						 forTableWithName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) changeColumnWithName: (NSString *) columnName 
				toColumnWithProperties: (NSDictionary *) newProperties 
					  forTableWithName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}
@end

@implementation MDAConnection (TransactionHandling)
- (void) setAutoCommit: (BOOL) commitAutomatically
{
	return;
}

- (BOOL) autoCommit {
	return YES;		// assuming transactions are unsupported
}

- (MDADbResult *) beginTransaction
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) commitTransaction
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) rollbackTransaction
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (BOOL) databaseSupportsTransactions
{
	return NO;
}

@end

@implementation MDAConnection (FunctionHandling)
- (MDADbResult *) createFunctionWithName: (NSString *) functionName 
									code: (NSData *) functionCode
								language: (NSString *) languageName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (NSArray *) supportedFunctionLanguages
{
	return nil;
}

- (MDADbResult *) dropFunctionWithName: (NSString *) functionName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (BOOL) databaseSupportsFunctions
{
	return NO;
}
@end

@implementation MDAConnection (TriggerHandling)
- (MDADbResult *) createTriggerWithName: (NSString *) triggerName
						   functionName: (NSString *) functionName
								  event: (NSString *) event
							  tableName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) dropTriggerWithName: (NSString *) triggerName
					 forTableWithName: (NSString *) tableName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (NSArray *) supportedTriggerEvents
{
	return nil;
}

- (BOOL) databaseSupportsTriggers
{
	return NO;
}
@end

@implementation MDAConnection (ViewsHandling)
- (MDADbResult *) createNamedView: (NSString *) viewName forQuery: (NSString *) query
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) dropViewWithName: (NSString *) viewName
{
	MDADbResult * _result;
	_result = [[MDADbResult alloc] init];
	[_result setResultCode:MDADB_FAIL];
	[_result setMessage:@"MDAConnection does not implement this method"];
	[_result autorelease];
	return _result;
}

- (BOOL) databaseSupportsViews
{
	return NO;
}

@end

