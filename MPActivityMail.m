//
//  MPActivityMail.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/17/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityMail.h"

#import "BotController.h"
#import "Item.h"
#import "MacroController.h"
#import "MPActivitySell.h"
#import "MPMover.h"
#import "MPTimer.h"
#import "Node.h"
#import "PatherController.h"
#import "MPTask.h"


@interface MPActivityMail (Internal)

- (id)  initWithMailBox:(Node *)aBox andName:(NSString *)nameAlt andSubject:(NSString *)subj andMessage:(NSString *)message andListMail:(NSArray *)listMailItems andListKeep:(NSArray *)listProtectedItems andWhite:(BOOL)doWhite andGreen:(BOOL)doGreen andBlue:(BOOL) doBlue andTask:(MPTask *)aTask;

- (BOOL) allItemsClicked;
- (void) clickNextItem;
- (void) clickMailBox;
- (BOOL) isMessageFull;
- (void) sendMail;

- (void) buildListToMail;
- (BOOL) isMailableItem:(Item *)anItem;
- (BOOL) isNamedItem:(Item *)anItem;

@end


@implementation MPActivityMail
@synthesize mailBox, mailToName, mailToSubj, mailToBody, timeOutClick, mover;
@synthesize listToKeep, listNamedToMail, listToMail, luaCondition;



- (id)  initWithMailBox:(Node *)aBox andName:(NSString *)nameAlt andSubject:(NSString *)subj andMessage:(NSString *)message andListMail:(NSArray *)listMailItems andListKeep:(NSArray *)listProtectedItems andWhite:(BOOL)doWhite andGreen:(BOOL)doGreen andBlue:(BOOL) doBlue andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"Mail" andTask:aTask])) {
		self.mailBox	= aBox;
		
		self.mailToName = nameAlt;
		self.mailToSubj = subj;
		self.mailToBody = message;
		
		
		
		self.listToKeep = listProtectedItems;
		self.listNamedToMail = listMailItems;
		self.listToMail = nil;
		
		mailWhite = doWhite;
		mailGreen = doGreen;
		mailBlue = doBlue;
		
		
		state = MailActivityStarted;
		
//		self.timeOut = [MPTimer timer:2150];
		self.timeOutClick = [MPTimer timer:1250];
		numItemsInMessage = 0;
		
		self.mover = [MPMover sharedMPMover];
		
		
		
		//// Hack: to get working without item Quality available to me:
		////       Use lua macro to sell based on quality :
		
		self.luaCondition = [NSMutableString string];
		
		// if doWhite add white quality check
		if (mailWhite) {
			[luaCondition appendString:@" ql==1 "];
		}	
		
		
		// if doGreen add Green quality check
		if (mailGreen) {
			if ([luaCondition length] > 0) [luaCondition appendString:@"or"];
			[luaCondition appendString:@" ql==2 "];
		}
		
		// if doGreen add Green quality check
		if (mailBlue) {
			if ([luaCondition length] > 0) [luaCondition appendString:@"or"];
			[luaCondition appendString:@" ql==3 "];
		}
		
	}
	return self;
}


- (void) dealloc
{
    [mailBox release];
	[listToKeep release];
	[listNamedToMail release];
	[listToMail release];

	[timeOutClick release];
	[mover release];
	
	[mailToName release];
	[mailToSubj release];
	[mailToBody release];
	
	[luaCondition release];
	
    [super dealloc];
}


#pragma mark -


// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (mailBox == nil) {
		PGLog( @"[ActivityMail] Error: ActivityMail called with mailbox as NIL");
		return;
	}
	
	
	// if vendor is in Distance
	Position *mailBoxPosition = [mailBox position];
	float distanceToMailbox = [[task myPosition] distanceToPosition:mailBoxPosition];
	if (distanceToMailbox <= 5.0 ) {
		
		
		PGLog( @"[ActivityMail] [start] clicking on mailbox ... ");
		
		// face mailbox
		[mover faceLocation:(MPLocation *)[mailBox position]];
		
		// mouse click on mailBox
		[self clickMailBox];
		
		
		// timeOut start
		[timeOutClick start];
		numItemsInMessage = 0;
		
		state = MailActivityOpeningMailbox;
		return;
		
	} else{
		
		PGLog( @"[ActivityMail]  Error: too far away to attempt mailing!  MPTaskMail -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be selling
	state = MailActivityDone;
}





// work is called repeatedly every 100ms or so.
- (BOOL) work {
	//PGLog(@" ++++ mail->work() ");
	
	// switch (state)
	switch (state) {
		case MailActivityStarted:
			
			//// How did we get here???
			
			// face vendor
			[mover faceLocation:(MPLocation *)[mailBox position]];
			
			// mouse click on mob
			[self clickMailBox];
			
			
			// timeOut start
			[timeOutClick start];
			
			
			state = MailActivityOpeningMailbox;
			return NO;
			break;
			
			
			
		case MailActivityOpeningMailbox:
			// NOTE: we really need a method to detect when the Mailbox Window appears
			
			// if ([self mailboxWindowOpen]) {
			//		state = MailActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				state = MailActivityClickingItems;
				[self clickNextItem];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case MailActivityClickingItems:
			if ([self allItemsClicked]) {
				
				[self sendMail]; 
				
				state = MailActivityDone;
				return YES;
			}
			if ([timeOutClick ready]) {
				
				if ([self isMessageFull]) {
					
					// time to send the message:
					[self sendMail];
					
				} else {
					
					[self clickNextItem];
				}
				[timeOutClick start];
			}
			return NO;
			break;
			
			
		default:
		case MailActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we finished.  Make sure we stop moving.
- (void) stop{
	
	/// clear list of items to mail ... (we'll have to recalculate it when we get back)
	self.listToMail = nil;
	
	// TODO: should probably send an ESC to the UI so we clear the Mail Tab.
	
	[mover stopAllMovement];
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case MailActivityOpeningMailbox:
			[text appendString:@"   opening Mailbox window."];
			break;
			
		case MailActivityClickingItems:
			[text appendFormat:@"  %d items left to mail", [listToMail count]];
			break;
			
		default:
		case MailActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}






#pragma mark -
#pragma mark Internal


// perform an interaction with the vendor
- (void) clickMailBox {

	[[[task patherController] botController] interactWithMouseoverGUID: [mailBox GUID]];
	usleep(500000); /// <--- sigh, should probably add another state rather than stop thread ... maybe I'll get around to it
	
	[[[task patherController] macroController] useMacroOrSendCmd:@"/click MailFrameTab2"];
	usleep(100000);
}



- (BOOL) allItemsClicked {
	
	if (listToMail == nil) return NO;
	
	// return ([listItemsToSell count] == 0);
	return ([listToMail count] == 0);
}



- (void) clickNextItem {
	
	// if we haven't built our list of items to sell then do so:
	if (listToMail == nil) {
		[self buildListToMail];
	}
	
	if ([listToMail count] > 0) {
		
		// send our stored command for that item
		NSString *macroCommand = [listToMail objectAtIndex:0];
		[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
		[listToMail removeObjectAtIndex:0];
		
		numItemsInMessage++;
	}
	
}



- (BOOL) isMessageFull {
	
	return (numItemsInMessage >= 12);
}


- (void) sendMail {
	
	NSString *macroCommand = [NSString stringWithFormat:@"/script SendMail( \"%@\", \"%@\", \"%@\");", mailToName, mailToSubj, mailToBody];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];

	numItemsInMessage = 0;  // reset our message count.
}




- (void) buildListToMail {
	
	NSMutableArray *tempList = [NSMutableArray array];
	NSString *command;
	
	
	// for each Bag
	int k = 0;
	for (; k<5; k++) {
		
		// for each Slot
		int j = 0;
		for (; j<= 40; j++) {
			
			// get item at bag,slot
			Item *item = [MPActivitySell itemInBag:k atSlot:j];
			if (item) {
				
				// if item is sellable
				if ([self isMailableItem:item]) {
					
					if ([self isNamedItem:item]) {

						// add script to command list: UseContainerItem
						[tempList addObject:[NSString stringWithFormat:@"/run UseContainerItem(%d, %d); print(\"mail named - n[%@]\");", k, j, [item name]]];
					
					} else {
					
						// compile and Add script command with Quality Checks
						command = [NSString stringWithFormat:@"/run local iID = GetContainerItemID(%d,%d); if iID~= nil then  local nm, _, ql = GetItemInfo(iID);  if %@ then print(\"mail - n[\"..nm..\"] q[\"..ql..\"]\"); UseContainerItem(%d,%d); else print(\"keep \"..nm..\" q[\"..ql..\"]\"); end;  end;", k, j, luaCondition, k, j];					
						[tempList addObject:command];
						
					}
					
				}
			}
			
		}
		
	}
	
	self.listToMail = tempList;
	
}




- (BOOL) isMailableItem:(Item *)anItem {
	
	
	// if itemName is like one of the names in our protectedList  return NO;
	for (NSString *keepItem in listToKeep) {
		
		if( [[anItem name] isCaseInsensitiveLike:keepItem] ) {
			return NO;
		}
	}
	
	
	//// OK, how do we check for Item Quality???
	
	// if itemQuality is White and !mailWhite return NO;
	// if itemQuality is Green and !mailGreen return NO;
	// if itemQuality is Blue and !mailBlue return NO;
	
	return YES;
	
}




- (BOOL) isNamedItem:(Item *)anItem {
	
	
	// if itemName is like one of the names in our to mail list  return YES;
	for (NSString *namedItem in listNamedToMail) {

		
		if( [[anItem name] isCaseInsensitiveLike:namedItem] ) {
//PGLog(@" ++++ anItem[%@] // namedItem[%@] == LIKE LIKE!", [anItem name], namedItem);
			return YES;
		}
//PGLog(@" ++++ anItem[%@] // namedItem[%@] == Not Like!", [anItem name], namedItem);
	}
	
	return NO;
	
}




#pragma mark -

+ (id)  mailTo:(NSString *)name withSubject:(NSString *)subj withMessage:(NSString *)message usingMailbox:(Node *)aMailBox mailingItems:(NSArray *)listMailItems keepItems:(NSArray *)listProtectedItems whiteItems:(BOOL)doWhite greenItems:(BOOL)doGreen blueItems:(BOOL) doBlue forTask:(MPTask *)aTask {
	
	return [[[MPActivityMail alloc] initWithMailBox:aMailBox andName:name andSubject:subj andMessage:message andListMail:listMailItems andListKeep:listProtectedItems andWhite:doWhite andGreen:doGreen andBlue:doBlue andTask:aTask] autorelease];
}

@end
