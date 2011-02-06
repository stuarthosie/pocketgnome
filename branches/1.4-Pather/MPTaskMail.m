//
//  MPTaskMail.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/19/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPTaskMail.h"

#import "InventoryController.h"
#import "MPActivityMail.h"
#import "MPActivityWalk.h"
#import "NodeController.h"
#import "PatherController.h"


@interface MPTaskMail (Internal)

- (Node *) mailbox;
- (void) clearActivityApproach;
- (void) clearActivityMail;

@end


@implementation MPTaskMail

@synthesize mailboxLocation, listMailItems, listProtectedItems, selectedMailbox;
@synthesize mailTo, mailSubj, mailMessage;
@synthesize activityApproach, activityMail;






- (id) initWithPather:(PatherController*)controller {
	if ((self = [super initWithPather:controller])) {
		name = @"Mail";
		
		self.mailboxLocation = nil;
		self.mailTo = nil;
		self.mailSubj = nil;
		self.mailMessage = nil;
		self.listMailItems = nil;
		self.listProtectedItems = nil;
		self.activityApproach = nil;
		self.activityMail = nil;
		self.selectedMailbox = nil;
		
		mailWhite = NO;  
		mailGreen = YES;
		mailBlue = YES;
		
		isDone = NO;
		
		state = MailTaskWaiting;
	}
	return self;
}



- (void) setup {
	
	self.mailboxLocation = [self locationFromVariable:@"location"];
	
	self.mailTo = [self stringFromVariable:@"to" orReturnDefault:@"noname"];
	self.mailSubj = [self stringFromVariable:@"subj" orReturnDefault:@""];
	self.mailMessage = [self stringFromVariable:@"message" orReturnDefault:@""];
	
	NSMutableArray *tempList = [NSMutableArray array];
	NSArray *itemList = [self arrayStringsFromVariable:@"protected"];
	
	for( NSString *itemName in itemList) {
		
		[tempList addObject:[NSString stringWithFormat:@"*%@*",[itemName lowercaseString]]];
	}
	self.listProtectedItems = [tempList copy];
	
	
	[tempList removeAllObjects];
	itemList = [self arrayStringsFromVariable:@"items"];
	
	for( NSString *itemName in itemList) {
		
		[tempList addObject:[NSString stringWithFormat:@"*%@*",[itemName lowercaseString]]];
	}
	self.listMailItems = [tempList copy];
	
	
	mailWhite = [self boolFromVariable:@"mailwhite" orReturnDefault:NO];
	mailGreen = [self boolFromVariable:@"mailgreen" orReturnDefault:YES];
	mailBlue = [self boolFromVariable:@"mailblue" orReturnDefault:YES];
	
	
	minFreeBagSlots = (NSInteger)[[self integerFromVariable:@"minfreebagslots" orReturnDefault:10000] value];
}



- (void) dealloc
{
	[mailboxLocation release];
	[mailTo	release];
	[mailSubj release];
	[mailMessage release];
	[listMailItems release];
	[listProtectedItems release];
    [activityApproach release];
	[activityMail release];
    [selectedMailbox release];
	
    [super dealloc];
}



#pragma mark -



- (BOOL) isFinished {
	
	// NOTE:  if a $MinFreeBagSlots value it given, then this task is never done, but always watching your bag state
	//        otherwise, this is a single shot task, and is finished when isDone it set.
	return (minFreeBagSlots < 10000)? NO: isDone;
}



- (MPLocation *) location {
	
	return mailboxLocation;
}



- (void) restart {
	isDone = NO;
	state = MailTaskWaiting;
}



- (BOOL) wantToDoSomething {
    PGLog( @"[MPTaskMail wtds]: mfbs[%d]  bsa[%d]", minFreeBagSlots, [[InventoryController sharedInventory] bagSpacesAvailable]);
	
	
	switch (state) {
		default:
		case MailTaskWaiting:
			//// Waiting until we want to go mail something.
			
			
			// if a minFreeBagSlots are set: then check to see if valid.
			if (minFreeBagSlots < 10000) {
				if (minFreeBagSlots >= [[InventoryController sharedInventory] bagSpacesAvailable]) {
					isDone = NO;
					state = MailTaskApproaching;
					return YES;  
				}
			} else {
				
				// no minFreeBagSlots given, so we want to do our thing if we are !Done
				// this makes this task a single shot task (good for SEQ{} tasks)
				if (!isDone) {
					state = MailTaskApproaching;
					return YES;
				}
				
			}
			return NO;
			break;
			
			
			
		case MailTaskApproaching:
			//// Approaching our mailbox to sell stuff to
			
			
			// if distance to location < 5
			if ([mailboxLocation distanceToPosition:[self myPosition]] < 3.5f ) {
				// state = selling
				state = MailTaskMailing;
			}// end if
			return YES;
			break;
			
			
			
		case MailTaskMailing:
			//// mailing our stuff
			//// NOTE:  let [activityDone]  reset our state to Waiting
			
			//// sanity check here:
			// if we are too far away, approch location
			if ([mailboxLocation distanceToPosition:[self myPosition]] > 5.0f) {
				// state = selling
				state = MailTaskApproaching;
			}// end if
			return YES;
			break;
			
			
	}
	
	// shouldn't get here, but if I do: return NO.
	return NO;
	
	
}



- (MPActivity *) activity {
	
	switch (state) {
			
		case MailTaskWaiting:
			//// ok, really shouldn't get here on Waiting.
			
			break;
			
			
		default:
		case MailTaskApproaching:
			
			if (activityMail != nil) {
				[self clearActivityMail];
			}
			
			if (activityApproach == nil) {
				// Question: Did the old Pather have useMount set on Mail task?
				self.activityApproach = [MPActivityWalk walkToLocation:mailboxLocation forTask:self useMount:NO];
			}
			return activityApproach;
			break;
			
			
		case MailTaskMailing:
			
			// if attackTask active then
			if (activityApproach != nil) {
				
				[self clearActivityApproach];
				
			} 
			
			
			// if activityMail not created then
			if (activityMail == nil) {
				
				// create approachTask
				Node *mailbox = [self mailbox];
				self.activityMail = [MPActivityMail mailTo:mailTo withSubject:mailSubj withMessage:mailMessage usingMailbox:mailbox mailingItems:listMailItems keepItems:listProtectedItems whiteItems:mailWhite greenItems:mailGreen blueItems:mailBlue forTask:self];
				
			}
			return activityMail;
			break;
			
	}
	
	// we really shouldn't get here.
	// return 
	return nil;
}



- (BOOL) activityDone: (MPActivity*)activity {
	
	// that activity is done so release it 
	if (activity == activityApproach) {
		[self clearActivityApproach];
	}
	
	if (activity == activityMail) {
		[self clearActivityMail];
		isDone = YES;
		state = MailTaskWaiting;
	}
	return YES; // ??
}



- (void) clearBestTask {
	
	//self.selectedMailbox = nil;
	
}



- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	
	
	switch (state){
		case MailTaskWaiting:
			[text appendFormat:@"  Waiting ... \n  minBagSpace[%d] free[%d]", minFreeBagSlots, [[InventoryController sharedInventory] bagSpacesAvailable]];
			break;
			
		case MailTaskApproaching:
			[text appendFormat:@"  Approaching Mailbox\n   loc[%0.2f, %0.2f, %0.2f]",  [mailboxLocation xPosition], [mailboxLocation yPosition], [mailboxLocation zPosition]];
			break;
			
		case MailTaskMailing:
			[text appendFormat:@"  Mailing items ..."];
			break;
			
	}
	
	
	return text;
}


#pragma mark -
#pragma mark Helper Functions




- (Node *) mailbox {
	
	if (selectedMailbox == nil) {
		
		self.selectedMailbox = [[patherController nodeController] closestNodeWithName:@"mailbox"];
		
		if (selectedMailbox == nil) {
			self.selectedMailbox = [[patherController nodeController] closestNodeWithName:@"Mailbox"];
		}
	} 
	return selectedMailbox;  
	
}




- (void) clearActivityApproach {
	[activityApproach stop];
	[activityApproach autorelease];
	self.activityApproach = nil;
}



- (void) clearActivityMail {
	[activityMail stop];
	[activityMail autorelease];
	self.activityMail = nil;
}




#pragma mark -

+ (id) initWithPather: (PatherController*)controller {
	return [[[MPTaskMail alloc] initWithPather:controller] autorelease];
}


@end
