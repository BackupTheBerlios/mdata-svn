/*
 *  MDADbResult.h
 *  MDAccess
 *
 */

#include <Carbon/Carbon.h>

@interface MDADbResult : NSObject 
{
	@private
	int resultCode;
	NSString * message;
}

- (int) resultCode;
- (void) setResultCode: (int) code;
- (NSString *) message;
- (void) setMessage: (NSString *) message;

#define MDADB_OK	0
#define MDADB_FAIL -1
@end
