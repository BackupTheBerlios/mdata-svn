/*
 *  MDADbResult.m
 *  MDAccess
 *
 *  Created by Nick Hristov on Thu Feb 17 2005.
 *  Copyright (c) 2005 __MyCompanyName__. All rights reserved.
 *
 */

#include "MDADbResult.h"

@implementation MDADbResult

- (int) resultCode
{
	return resultCode;
}

- (void) setReturnCode: (int) resultCode
{
	self->resultCode = resultCode;
}

- (NSString *) message
{
	return [message copyWithZone: nil];
}

- (void) setMessage: (NSString *) message
{
	[message retain];
	if(self->message != nil) {
		[self->message release];
	}
	self->message = message;
}

@end
