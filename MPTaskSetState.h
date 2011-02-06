//
//  MPTaskSetState.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class PatherController;



/*!
 * @class      MPTaskSetState
 * @abstract   Save the following key/value combo to the Toon Data
 * @discussion 
 * Save the given $Key / $Value combo to this toon's data.  This value can be retrieved in
 * task files using the value $State{"keyName"}.
 *
 * Example
 * <code>
 *	SetState
 *	{
 *		$Key="Phase";
 *		$Value="Vendoring";
 *	}
 * </code>
 *		
 */
@interface MPTaskSetState : MPTask {

	NSString *key, *value;
	BOOL isDone;
}
@property (retain) NSString *key, *value;


+ (id) initWithPather: (PatherController*)controller;
@end
