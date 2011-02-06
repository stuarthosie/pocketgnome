//
//  MPActivityQuestPickup.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityQuestPickup.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "Node.h"
#import "PatherController.h"



@interface MPActivityQuestPickup (Internal)

- (void) clickQuestGiver;
- (void) clickQuestNode;
- (void) clickQuestItem;
- (void) clickQuestOption: (int) indx;
- (void) clickContinue;
- (void) clickAccept;

- (Position *) questPosition;

@end


@implementation MPActivityQuestPickup
@synthesize questGiver, questNode, questItem, questID, timeOutClick, mover; 


- (id)  initWithQuestGiver:(Mob *)npc orObject: (Node *)qNode orItem:(Item *)qItem andID:(NSString*)qID isAutoAccept:(BOOL) isAuto andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"QuestPickup" andTask:aTask])) {
		
		self.questGiver	= npc;
		self.questNode = qNode;
		self.questItem = qItem;
		self.questID = qID;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		isAutoAccept = isAuto;
		
		state = QuestPickupActivityStarted;
		count = 0;
	}
	return self;
}


- (void) dealloc
{
    [questGiver release];
	[questNode release];
	[questItem release];
	[questID release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if ((questGiver == nil) && (questNode == nil) && (questItem == nil)) {
		PGLog( @"[ActivityQuestPickup] Error: ActivityQuestPickup called with questGiver,questNode,questItem == nil");
		return;
	}
	
	
	// if questGiver is in Distance
	Position *questPosition = [self questPosition];
	float distanceToQuest = [task myDistanceToPosition:questPosition];
	if (distanceToQuest <= 5.0 ) {
		
		
		PGLog( @"[ActivityQuestPickup] [start] opening Quest ... ");
		
		// face questGiver
		[mover faceLocation:(MPLocation *)questPosition];
		
		// mouse click on mob
		if (questGiver != nil) { [self clickQuestGiver]; }
		if (questNode != nil)  { [self clickQuestNode];  }
		if (questItem != nil)  { [self clickQuestItem];  }
		
		// timeOut start
		[timeOutClick start];
		

		state = QuestPickupActivityOpeningQuestgiver;

		
		return;
		
	} else{
		
		PGLog( @"[ActivityQuestPickup]  Error: too far away to attempt setting!  MPTaskQuestPickup -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = QuestPickupActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case QuestPickupActivityStarted:
			
			//// How did we get here???
			PGLog( @"[ActivityQuestPickup] [start] opening Quest ... ");
			
			// face questGiver
			[mover faceLocation:(MPLocation *)[self questPosition]];
			
			// mouse click on mob
			if (questGiver != nil) { [self clickQuestGiver]; }
			if (questNode != nil)  { [self clickQuestNode];  }
			if (questItem != nil)  { [self clickQuestItem];  }
			
			// timeOut start
			[timeOutClick start];
			
			
			state = QuestPickupActivityOpeningQuestgiver;

			return NO;
			break;
			
			
			
		case QuestPickupActivityOpeningQuestgiver:
			// NOTE: we really need a method to detect when the Innkeeper Window appears
			
			// if ([self questGiverWindowOpen]) {
			//		state = QuestPickupActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
				
				// if quest is from an item then just jump into continue/Accept
				if ((isAutoAccept) || (questItem != nil)) {
					// AutoAccept actually means that clicking the quest giver jumps directly into 
					// the Quest Dialogue, you don't have to find the quest from the list first
					
					// questItems also jump you directly into the Quest Dialogue so ... 
					state = QuestPickupActivityClickContinue;
					[self clickContinue];
					[timeOutClick start];
					return NO;
				}
				
				// questGivers and questNodes might have several options so:
				count ++;
				state = QuestPickupActivityClickingQuestItem;
				[self clickQuestOption:count];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case QuestPickupActivityClickingQuestItem:
			
			
			if ([timeOutClick ready]) {
				
				if (count > 3) {
					[self clickContinue];
					state = QuestPickupActivityClickContinue;
				} else {
					count++;
					[self clickQuestOption:count];
					[timeOutClick start];
				}
			}
			return NO;
			break;
			
			
		case QuestPickupActivityClickContinue:
			if ([timeOutClick ready]) {
				state = QuestPickupActivityAcceptQuest;
				[self clickAccept];
				[timeOutClick start];
			}
			return NO;
			break;
			
			
		case QuestPickupActivityAcceptQuest:
			if ([timeOutClick ready]) {
				state = QuestPickupActivityDone;


				return YES;
			}
			return NO;
			break;
			
			
		default:
		case QuestPickupActivityDone:
			return YES;
			break;
			
	}
	
	// otherwise, we exit (but we are not "done"). 
	return NO;
}



// we are interrupted before we arrived.  Make sure we stop moving.
- (void) stop{
	
	
	[mover stopAllMovement];
	
}

#pragma mark -


- (NSString *) description {
	NSMutableString *text = [NSMutableString string];
	
	[text appendFormat:@"%@\n", self.name];
	switch (state) {
		case QuestPickupActivityStarted:
			[text appendString:@"   starting ... "];
			break;
			
		case QuestPickupActivityOpeningQuestgiver:
			[text appendString:@"   opening Quest Giver"];
			break;
			
		case QuestPickupActivityClickingQuestItem:
			[text appendString:@"  choosing the quest "];
			break;
			
		case QuestPickupActivityClickContinue:
			[text appendString:@"  clicking Continue."];
			break;
			
		case QuestPickupActivityAcceptQuest:
			[text appendString:@"  clicking Accept."];
			break;
			
		default:
		case QuestPickupActivityDone:
			[text appendString:@"  Done!"];
			break;
			
	}
	
	return text;
}

#pragma mark -
#pragma mark Internal


// perform an interaction with the questGiver
- (void) clickQuestGiver {
	[[[task patherController] botController] interactWithMouseoverGUID: [questGiver GUID]];
}


- (void) clickQuestNode {
	[[[task patherController] botController] interactWithMouseoverGUID: [questNode GUID]];
}


- (void) clickQuestItem {
	// TODO: implement clicking on an inventory item
}



- (void) clickQuestOption: (int) indx {
	
	
	// OK, there has got to be a better way to do this!  Anyone .... ?
	
	NSMutableString *text = [NSMutableString stringWithString:@""];
	
	// add a set of placeholders for index 2+
	int i;
	for (i=1; i<indx; i++) {
		[text appendString:@"_,_,_,_,"];
	}
	
	
	
	// Should really clean this command up and see if I can put it in a loop ... 
	NSString *macroCommand = [NSString stringWithFormat:@"/run local t; %@t=GetGossipActiveQuests(); if (string.find(t, \"%@\")) then SelectGossipActiveQuest(%d); end;", text, questID, indx];
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
	PGLog(@"  +++++ clickQuestOption[%d] macroCommand[%@]", indx, macroCommand);
	
}



- (void) clickContinue {
	
	PGLog(@"    +++++ clicking Continue ... " );
	[[[task patherController] macroController] useMacro:@"QuestContinue"];
	
}


- (void) clickAccept {
	
	PGLog(@" ++++ clicking accept ");
	[[[task patherController] macroController] useMacro:@"QuestAccept"];
	
}


- (Position *) questPosition {
	
	Position *questPosition = nil;
	if (questGiver != nil) { questPosition = [questGiver position]; }
	if (questNode != nil)  { questPosition = [questNode position]; }
	if (questItem != nil)  { questPosition = [task myPosition]; }
	
	return questPosition;
	
}



#pragma mark -

+ (id) pickupQuestFrom:(Mob *)npc  orNode: (Node*) qNode orItem:(Item *)qItem withID:(NSString*)qID isAutoAccept:(BOOL) isAuto forTask:(MPTask *)aTask {
	
	return [[[MPActivityQuestPickup alloc] initWithQuestGiver:npc orObject:qNode orItem:qItem andID:qID isAutoAccept:isAuto andTask:aTask] autorelease];
}


@end