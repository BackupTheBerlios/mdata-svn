//  MDAPgConnection.m
//  MDAccess
//
//  Created by Nick Hristov on 1/19/05.
//  Copyright 2005 Nick Hristov. All rights reserved.

#import "MDAPgConnection.h"
#import "MDAPgConnectionPrivate.h"
#import "MDADbResult.h"

@implementation MDAPgConnection

- (id) init {
	[super init];
	connection_state = CONN_DOWN;
	return self;
}

- (void) dealloc {
	if([self class] == [MDAPgConnection class]) {
		// classes that inherit from this class should not invoke this portion of the code:
		if(connection_state != CONN_DOWN) {
			connection_state = CONN_DOWN;
			PQfinish(connection);
		}		
	}
	[super dealloc];
}


- (void) connectionPoll
{
	NSThread * thisThread;
	NSAutoreleasePool * pool;
	int status;
	NSDate * nextFireDate;
	NSTimeInterval delay = 5;
	pool = [[NSAutoreleasePool alloc] init];
	
	thisThread = [NSThread currentThread];
	while(TRUE) {
		status = PQstatus(connection);
		nextFireDate = [NSDate dateWithTimeIntervalSinceNow: delay];
		
		if(status = CONNECTION_MADE) {
			if([_callback_object respondsToSelector:@selector(connectionStatusUpdate:)])
			{
				[_callback_object connectionStatusUpdate:@"Connected successfully."];
			}
			connection_state = CONN_UP;
			[connectionPoller autorelease]; 
			break;
		}
		else if (status == CONNECTION_BAD) {
			if([_callback_object respondsToSelector:@selector(connectionStatusUpdate:)])
			{
				[_callback_object connectionStatusUpdate:@"Connection failed."];
			}
			[connectionPoller autorelease];
			break;
		} 
		else {
			[thisThread sleepUntilDate: nextFireDate]; 
		}
	}
	[pool release];
}

@end

@implementation MDAPgConnection (ConnectionHandling)
- (MDADbResult *) connectWithPreferences: (NSDictionary *) preferences
{
	static NSArray * allowedKeys;		/* allowed keys for this interface	*/
	static NSArray * allowedPgKeys;		/* allowed keys to pass to libpq	*/
	NSEnumerator * crawler;
	NSMutableString * _parameter;
	NSMutableString * _connectionString;
	NSNumber * blockFlag;
	MDADbResult * connectResult;
	id key;
	id object;
	int status;
	
	crawler = [preferences keyEnumerator];
	_parameter = [[NSMutableString alloc] init];
	_connectionString = [[NSMutableString alloc] init];
	connectResult = [[MDADbResult alloc] init];
	
	
	allowedKeys = [[NSArray alloc] 
		initWithObjects:	@"host",		
							@"hostaddr",	
							@"dbname",		
							@"block",		/* blocking/non blocking connect */
							@"port",		
							@"user",		
							@"password",	
							@"connect_timeout",	
							@"callback_object", /* object for callback when connect completes */
							@"sslmode", nil];
		allowedPgKeys = [[NSArray alloc] 
		initWithObjects:	@"host",		
							@"hostaddr",	
							@"dbname",		
							@"port",		
							@"user",		
							@"password",	
							@"connect_timeout",	
							@"sslmode", nil];
							
	while( (key = [crawler nextObject]) != nil) {
		if([key isKindOfClass:@"NSString"] == NO)
			continue;
		
		if([allowedPgKeys indexOfObject:key] == NSNotFound)
			continue;
		
		object = [preferences objectForKey: key];
		
		if([object isKindOfClass:@"NSString"] == NO)
			continue;
		
		// ok, so we did not get junk, afer all
		[_connectionString appendString:key];
		[_connectionString appendString:@"='"];
		[_parameter setString:object];
		[_parameter escapeCharacter:'\''];
		[_connectionString appendString: _parameter];
		[_connectionString appendString:@"' "];
	}

	// check for connection type
	if([preferences objectForKey:@"block"] != nil)
	{
		blockFlag = [preferences objectForKey:@"block"];
		_callback_object = [preferences objectForKey:@"callback_object"];
		useBlockingCall = [blockFlag boolValue];
	}

	if(useBlockingCall == YES && _callback_object != nil) 
	{
		//connect through a non-blocking call to PQconn
		connection = PQconnectStart([_connectionString cString]);
		connection_state = CONN_CONNECTING;
		if(connection == NULL) {
			// connection failed
			[connectResult setReturnCode: MDADB_FAIL];
			[connectResult setMessage:  @"Unable to allocate enough resource for connection."];
			[connectResult autorelease];
			connection_state = CONN_CONNECTING;
			return connectResult;
		}
		// PQConn allocated, spawn off a thread to watch over the state and do callback
		connectionPoller = [NSThread detachNewThreadSelector:@selector(connectionPoll) toTarget:self withObject:nil];
		connection_state = CONN_CONNECTING;
		[connectResult setReturnCode: MDADB_OK];
		[connectResult setMessage:  @"Connection in progress."];
		[connectResult autorelease];
		return connectResult;
		
	}
	else {
		connection = PQconnectdb([_connectionString cString]);
		if(connection == NULL) {
			// connection failed
			[connectResult setReturnCode: MDADB_FAIL];
			[connectResult setMessage:  @"Unable to allocate enough resources for connection."];
			[connectResult autorelease];
			connection_state = CONN_DOWN;
			return connectResult;
		}
		status = PQstatus(connection);
		if(status == CONNECTION_OK) {
			[connectResult setReturnCode:MDADB_OK];
			[connectResult setMessage:@"Connection established."];
			[connectResult autorelease];
			connection_state = CONN_UP;
			return connectResult;
		}
		else {
			[connectResult setReturnCode: MDADB_FAIL];
			[connectResult setMessage:@"Failed to connect to remote host."];
			[connectResult autorelease];
			PQfinish(connection);
			connection_state = CONN_DOWN;
			return connectResult;
		}
	}
}

- (void) disconnect
{
	if(connection_state != CONN_DOWN) {
		PQfinish(connection);
		connection = nil;
		connection_state = CONN_DOWN;
	}
}

@end

@implementation MDAPgConnection (StatementHandling)

- (MDAPgResult *) doQueryWithString: (NSString *) aString
{
	MDADbResult * result;
	PGresult * _result;
	result = [[MDADbResult alloc]init];
	if(connection_state == CONN_UP) {
		[result setReturnCode: MDADB_FAIL];
		[result setMessage:  @"Not connected to a database."];
		[result autorelease];
		return result;
	}
	
	_result = PQexec (connection, [aString cString]);
	if ( PQresultStatus (_result) == PGRES_TUPLES_OK ) {
		PQclear(_result);
		NSLog(@"doQueryWithString: ignoring SELECT result");
		[result setReturnCode:MDADB_OK];
		[result setMessage: @"Query executed successfully."];
		[result autorelease];
		return result;		
	}
	else if ( PQresultStatus (_result) == PGRES_COMMAND_OK ) {
		PQclear(_result);
		[result setReturnCode:MDADB_OK];
		[result setMessage:@"Query executed successfully."];
		[result autorelease];
		return result;
	}
	else {
		PQclear(_result);
		[result setReturnCode:MDADB_FAIL];
		[result setMessage:@"Last query failed."];
		[result autorelease];
		return result;
	}
}
@end

@implementation MDAPgConnection (SchemaHandling)
/*
- (NSDictionary *) schemaForTableWithName: (NSString *) tableName
{
	NSDictionary * _result;
	PGresult * _queryResult;
	NSString * _tableQuery = @"SELECT ";
	
	if(connection_state != CONN_UP) {
		NSLog(@"schemaForTableWithName called with no connection up");
		return nil;
	}
	
	
	
}
*/


- (NSArray *) tableNames	// throws MDAGenericPostgresqlException
{
	NSArray * _result;
	NSMutableArray * _construct;
	PGresult * _queryResult;
	NSException * _exception;
	ExecStatusType status;
	int _num_tables, _counter;
	
	// main function query:
	NSString * _listRelationsQuery = @"SELECT tablename FROM pg_tables;";
	
	_construct = [[NSMutableArray alloc] initWithCapacity: 20];	// good enough
																// for small dbs
	
	// check the connection status:
	if(_connection_state != CONN_UP) {
		NSLog(@"tableNames called with no connection up");
		return nil;
	}
	
	_queryResult = PQexec(connection, [_listRelationsQuery cString]);
	
	// check query sanity:
	if((status = PQresultStatus(_queryResult)) != PGRES_TUPLES_OK) {
		PQclear(_queryResult);
		_exception = 
			[NSException exceptionWithName:@"MDAGenericPostgresqlException"
				reason: [NSString stringWithUTF8String: PQresultErrorMessage(&_queryResult)] 
				userInfo: @"=> MDAPgConnection:tableNames"];
		[_exception raise];
		return nil;
	}
	_num_tables = PQntuples(_queryResult);
	
	// cycle through results and copy results into _construct
	for(_counter = 0; _counter = _num_tables; _counter ++)
	{
		[_construct addObject: [NSString stringWithUTF8String: PQgetvalue(_queryResult,_counter,0)]];
	}
	
	// clean up
	PQclear(_queryResult);
	[_construct autorelease];
	return [NSArray arrayWithArray:_construct];
}

- (MDADbResult *) dropTableWithName: (NSString *) tableName
{
	// set up:
	MDADbResult * _result;
	PGresult * _queryResult;
	ExecStatusType status;
	
	NSMutableString * _dropTableQuery = 
		[NSMutableString stringWithString: @"DROP TABLE "];
	[_dropTableQuery appendString:tableName];
	
	_result = [self doQueryWithString:_dropTableQuery];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) createTableWithName: (NSString *) tableName
						   withSchema: (NSDictionary *) newTableSchema
{
	MDADbResult * _result;
	NSArray * _supportedDataTypes;
	NSMutableString * queryString;
	int _index, count;
	NSArray * _keys;
	NSString * _fieldName;
	NSString * _fieldType;
	int _supportCount, _sIndex;
	NSDictionary * _supportPair;
	NSRange _lookup;
	NSRange _testRange;
	
	_result = [[MDADbResult alloc] init];
	
	if(connection_state != CONN_UP) {
		[_result setReturnCode: MDADB_FAIL];
		[_result setMessage: @"connection is not established"];
		[_result autorelease];
		return _result;
	}
	
	queryString = [[NSMutableString alloc] initWithString: @"CREATE TABLE "];
	
	[queryString appendString:tableName];
	[queryString appendString:@"( "];
	
	_lookup.location = NSNotFound;
	_lookup.length = 0;
	
	//ok, look through the data types and verify that they are supported by the driver
	_supportedDataTypes = [NSBundle objectForInfoDictionaryKey: @"Supported Data Types"];
	
	_keys = [newTableSchema keys];
	_supportCount = [_supportedDataTypes count];
	count = [_keys count];

	if (count < 1) {
		[_result setReturnCode: MDADB_FAIL];
		[_result setMessage: @"cannot create a table with no columns"];
		[queryString release];
		[_result autorelease];
		return _result;
	}
	
	for(_index = 0; _index < count; _index++) {
		_fieldType = [_keys objectAtIndex: _index];
		// ok, now look for _field type in _supportedDataTypes
		for(_sIndex = 0; _sIndex < _supportCount; _sIndex ++) {
			_supportPair = [_supportedDataTypes objectAtIndex: _sIndex];
			if([[_supportPair objectForKey:@"Expandable"] isEqualToNumber:[NSNumber numberWithBool:YES]])
			{
				_testRange = [_fieldType rangeOfString:[_supportPair objectForKey:@"Type"]];
				if(_testRange.location != _lookup.location ){
					[queryString appendString: [newTableSchema objectForKey: _fieldType]];
					[queryString appendString: @" "];
					[queryString appendString: _fieldType];
					[queryString appendString: @", "];
				}
			}
			else if([_fieldType isEqual: [_supportPair objectForKey: @"Type"]]) {
				[queryString appendString: [newTableSchema objectForKey: _fieldType]];
				[queryString appendString: @" "];
				[queryString appendString: _fieldType];
				[queryString appendString: @", "];
			}
			else {
				[_result setReturnCode: MDADB_FAIL];
				[queryString setString: @"unsupported column type by driver:"];
				[queryString appendString: _fieldType];
				[_result setMessage:  [NSString stringWithString:queryString]];
				[queryString release];  // local cleanup
				[_result autorelease];
				return _result;
			}
		}
	}
	
	count = [queryString length];
	_lookup.location = count - 3;
	_lookup.length = 2;
	queryString = [queryString deleteCharactersInRange:_lookup];
	[queryString appendString:@" );"];
	
	//execute query and see what happens
	_result = [self doQueryWithString:queryString];
	[queryString release];
	[_result autorelease];
	return _result;
}

- (MDADbResult *) dropColumnWithName: (NSString *) columnName 
					forTableWithName: (NSString *) tableName
{
	NSMutableString * _queryString;
	_queryString = [NSMutableString stringWithString:@"ALTER TABLE "];
	[_queryString appendString:tableName];
	[_queryString appendString:@" DROP "];
	[_queryString appendString:columnName];
	[_queryString appendString:@";"];
	return [self doQueryWithString:_queryString];
}







/*!
 *  @method addColumnWithProperties
 *  @discussion Creates a new column for tableName with columnProperties.
 *  @param columnProperties Specifies the name, constraints and types for 
 *		   the new column. The keys for the dictionary are the following NSStrings 
 *		   respectively: "name", "constraints", "type". The value associated with
 *		   constraint is an array with NSDictionaries which specify the 
 *  @param tableName Name of the table that the new column will belong to
 *  @result Returns the result of the newly added column.
 *  
 *  TODO: add MDA_CONSTRAINT_UNIQUE, MDA_CONSTRAINT_FOREIGN_KEY
 */
/*
- (MDADbResult *) addColumnWithProperties: (NSDictionary *) columnProperties 
	forTableWithName: (NSString *) tableName
{
	NSMutableString * _query;
	NSArray * _constraints;			// array of constraints
	NSDictionary * _constraint;		// single constraint
	MDADbResult * _result;
	NSString * _constraintType;
	int _number_constraints, _index;
	NSArray * _supportedDataTypes;
	int _number_supported_types;
	NSString * _columnType;
	
	
	
	_result = [[MDADbResult alloc] init];
	
	// first make sure we received good data
	if([columnProperties objectForKey: @"name"] == nil
	   || [columnProperties objectForKey: @"type"] == nil)
	{
		// return fail
		[_result setReturnCode: MDADB_FAIL];
		[_result setMessage:  @"MDAConnection: required parameter is missing"];
		[_result autorelease];
		return _result;
	}
	
	_query = [NSMutableString stringWithString:@"ALTER TABLE "];
	[_query appendString:tableName];
	[_query appendString:@" ADD "];
	[_query appendString: [columnProperties objectForKey: @"name"]];
	[_query appendString: @" "];
	
	_columnType = [columnProperties objectForKey: @"type"];
	
	// TODO: supported types code is repeating, see if this can become a seperate method
	
	// check if the given type is supported by the database
	_supportedDataTypes = [NSBundle objectForInfoDictionaryKey: @"Supported Data Types"];

	_number_supported_types = [_supportedDataTypes count];
	
	for(_index = 0; _index < _number_supported_types; _index ++)
	{
		_supportPair = [_supportedDataTypes objectAtIndex: _index];
		if([[_supportPair objectForKey:@"Expandable"] isEqualToNumber:[NSNumber numberWithBool:YES]])
		{
			if([_columnType rangeOfString:[_supportPair objectForKey:@"Type"]] != _lookup ){
				[_query appendString: [newTableSchema objectForKey: _fieldType]];
				[_query appendString: @" "];
				[_query appendString: _fieldType];
				[_query appendString: @", "];
			}
		}
		else if([_columnType isEqual: [_supportPair objectForKey: @"Type"]]) {
			[_query appendString: [newTableSchema objectForKey: _fieldType]];
			[_query appendString: @" "];
			[_query appendString: _fieldType];
			[_query appendString: @", "];
		}
		else {
			_result->resultCode = MDADB_FAIL;
			[queryString setString: @"unsupported column type by driver:"];
			[queryString appendString: _fieldType];
			_result setMessage:  [NSString stringWithString:queryString];
			[queryString release];  // local cleanup
			[_result autorelease];
			return _result;
		}
		
		
		
	}
	
	
	
	
	
	
	
	
	_constraints = [columnProperties objectForKey: @"constraints"];
	_number_constraints = [_constraints count];
	
	for(_index = 0; _index < _number_of_constraints; _index ++) 
	{
		_constraint = [_constraints objectAtIndex: _index];
		_constraintType = [_constraint objectForKey: @"type"];
		if(_constraintType == MDA_CONSTRAINT_UNIQUE) {
			[_query appendString: ];
			
			
		}
		
		
	}
	

}


- (MDADbResult *) changeColumnWithName: (NSString *) columnName 
				toColumnWithProperties: (NSDictionary *) newProperties 
					  forTableWithName: (NSString *) tableName
{
	
}
*/

/* private methods: */

- (void) releaseAllActiveStatements
{
	int count, index;
	NSArray * statements;
	NSArray * statementStrings;
	NSString * releaseString;
	NSMutableString * releaseQuery;
	MDAPgStatement * currentStatement;
	releaseString = @"DEALLOCATE PREPARED ";
	releaseQuery = [[NSMutableString alloc] init];
	MDADbResult * releaseResult;
	
	statements = [[preparedStatements keys] retain];
	count [statements count];
	for(index = 0; index < count; index++){
		currentStatement = [statements objectAtIndex: index];
		[currentStatement invalidate];
		
		// deallocate the connection from the server
		[releaseQuery setString:releaseString];
		[releaseQuery appendString:[preparedStatements objectForKey:currentStatement]];
		
		
		// really would prefer to issue a bunch of these as non-blocking calls
		releaseResult = [[self doQueryWithString:releaseQuery] retain];
		if([releaseResult resultCode] != MDADB_OK) {
			//something bad happened. dump it in the console for now
			NSLog([releaseResult message]);
		}
		[releaseResult release];
	}
	[releaseQuery release];
	[statements release];
}

- (MDADbResult *) prepareStatement: (MDAPgStatement *) statement forQuery: (NSString *) query
{
	int ps_count;   // number of prepared statements so far
	NSString * psName;  // name of the new prepared statement
	NSDictionary * newStatement;
	MDADbResult * prepareResult;
	NSCharacterSet * escapeCharacterSet;
	NSCharacterSet * parametersCharacterSet;
	NSScanner * scanner;
	NSString * unquotedQueryString;
	unichar qmark, special_char, ex_mark, s_quote;
	PGresult _result;
	int recording;
	int parameterCount;
	int location;
	NSMutableString * mutatedQuery; //getting creative with variables after 1 beer
									//if somebody dies in a plane crash because of the
									//following code, sue Spaten DbmG. 
	NSString * substring;
	NSMutableString * moldedString;
	ExecStatusType _result_status;
	
	qmark = '?';
	ex_mark = '!';
	s_quote = '\'';
	
	prepareResult = [[MDADbResult alloc] init];
	parametersCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"'!?"];
	mutatedQuery = [[NSMutableString alloc] initWithString:query];
	scanner = [NSScanner scannerWithString:mutatedQuery];
	moldedString = [[NSMutableString alloc] init];
	
	// scan through the query and find the number of parameters in the query
	recording = 1;
	parameterCount = 0;
	while ( [scanner scanUpToCharactersFromSet: escapeCharacterSet
										   intoString: unquotedQueryString] == YES)
	{		
		location = [scanner location];
		location--;
		special_char = [mutatedQuery characterAtIndex:location];
		switch (special_char) {
			case qmark:
				if(recording == 0) { break; }
				//put single quotes around ?
				
				substring = [mutatedQuery substringToIndex: location];
				
				[moldedString setString: substring];
				[moldedString appendString:@"'?'"];
				substring = [mutatedQuery substringFromIndex:(location + 1)];
				[mutatedQuery setString: moldedString];
				[scanner setScanLocation:location + 2]; //bypass the enclosing '
				parameterCount ++;
				break;
			case ex_mark:
				if(recording == 1) { parameterCount ++ ; }
				break;
			case s_quote:
				recording = (recording == 1) ? 0 : 1;   // ! recording
				break;
		}
	}
	
	ps_count = [[preparedStatements keys] count];
	ps_count++;
	
	ps = [[NSString stringWithFormat: @"MDAPS%d", ps_count] retain];
	
	// do not add the new entry to the list of prepared statements until
	// we actually register the prepared statement with the library
	
	_result = PQprepare(connection, [ps cString], [mutatedQuery cString], parameterCount, NULL);
	_result_status = PQresultStatus(_result);
	
	if(_result_status == PGRES_COMMAND_OK) {
		[prepareResult setReturnCode:MDADB_OK];
		[prepareResult setMessage:@"Prepare executed successfully."];
	}
	else {
		// something bad happened. propagate error, and error message
		[prepareResult setReturnCode:MDADB_FAIL];
		[prepareResult setMessage: [NSString stringWithUTF8String: PQresultErrorMessage(&_result)]];
	}
	
	newStatement = [[NSDictionary dictionaryWithObjects:
		[NSArray arrayWithObjects:[mutatedQuery copyWithZone:nil], ps, [NSNumber numberWithInt: parameterCount], nil]
												forKeys:
		[NSArray arrayWithObjects:@"actual_statement", "database_handle", @"number_of_parameters", nil]] retain];
		
		
	[preparedStatements setObject:newStatement forKey:statement];
	
	
	//clean-up
	[ps release];
	[newStatement release];
	[mutatedQuery release];
	[moldedString release];
	
	[prepareResult autorelease];
	return prepareResult;
}


- (PGresult *) executeStatement: (MDAPgStatement *) statement 
					withParameters: (NSArray *) parameters
{
	char ** parameter_buffer;   // a buffer that holds all parameter
	char * single_buffer;		// a buffer for a single parameter
	int buffer_length;
	int * parameter_lengths;	
	int parameterCount;
	int * flying_pointer;
	char * flying_character;
	char * save_position;
	NSNumber * _savedParameterCount;
	NSDictionary * _statementData;
	PGresult * _result;
	int index;
	int total_size;
	NSString * t_param;
	
	_statementData = [preparedStatements objectForKey:statement];
	parameter_lengths = NULL;
	single_buffer = NULL;
	if(_statementData == nil) {
		//bogus statement?
		return NULL;
	}
	parameterCount = [parameters count];
	_savedParameterCount = [_statementData objectForKey:@"number_of_parameters"];
	if([_savedParameterCount intValue] != parameterCount) {
		return NULL;
	}
	total_size = 0;
	if(parameterCount > 0) {
		//nasty memory allocation bellow
		parameter_lengths = malloc(sizeof(int) * parameterCount);
		if(parameter_lengths == NULL) {
			// this is a pretty grave error. it is actually so grave that it is
			// worth throwing an exception 
			[[NSException exceptionWithName:@"MemoryException" 
									 reason:@"failed to allocate memory through malloc"
								   userInfo:nil] raise];
			return nil; //not really reached
		}
		
		for(index = 0; index < parameterCount; index++) {
			t_param = [parameters objectAtIndex: index];
			buffer_length = [t_param length];
			total_size += buffer_length + 1;
			
			//damn, this is ugly:
			flying_pointer = parameter_lengths + index*sizeof(int);
			*flying_pointer = buffer_length;
			// hopefully no crash and burn!
		}
		
		// ok, now prepare the real buffer
		parameter_buffer = malloc(total_size*sizeof(char)		 // length of all strings 
								  + parameterCount*sizeof(char) // leave room for NULL char
								  + parameterCount*sizeof(char*) // the initial pointers
								  );
		if(parameter_buffer == NULL) {
			// again a pretty grave error. throw exception
			[_execResult release];
			free(parameter_lengths);
			
			[[NSException exceptionWithName:@"MemoryException" 
									 reason:@"failed to allocate memory through malloc"
								   userInfo:nil] raise];
			return nil;		// not really reached
		}
		
		//okay all memory alloc went through okay
		memset(parameter_buffer, 0, 
			   total_size*sizeof(char)		 // length of all strings 
			   + parameterCount*sizeof(char) // leave room for NULL char
			   + parameterCount*sizeof(char*) // the initial pointers
			   );
		
		
		// build the fancy array
		// what we end up having in a structure like this
		// char * buffer[parameterCount]
		// buffer[strlen(parameter1)]
		// buffer[strlen(parameter2)]
		// ...
		// buffer[strlen(parameterN)]
		total_size =  0;
		for(index = 0 ; index < parameterCount; index++)
		{
			t_param = [parameters objectAtIndex: index];
			buffer_length = [t_param length];
			
			// copy the string at the proper location
			flying_character =	parameter_buffer				//base location
							+   parameterCount*sizeof(char *)   // the base pointers
							+   total_size;						// current offset
			
			memcpy(flying_character, [t_param cString], buffer_length);
			save_position = flying_character;
			
			flying_character = parameter_buffer + index*sizeof(char *);			
			*flying_character = save_position;
			total_size = buffer_length + 1; // leave space for NULL character
		}
		_result = 
		PQexecPrepared(connection, [[_statementData objectForKey: @"database_handle"]cString],parameterCount, parameter_buffer, parameter_lengths,NULL, 0);
		
		// free the memory we allocated for the prepare
		free(parameter_buffer);
		free(parameter_lengths);
	}
	else {
		//no parameters - easy money
		_result = PQexecPrepared (connection, [[_statementData objectForKey: @"database_handle"]cString], 0,
								  NULL, NULL, NULL, 0);
	}
	return _result;
}

- (void) willReleaseStatement: (MDAPgStatement *) statement
{
	
	
}
@end