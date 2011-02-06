//
//  MPActivityQuestHandin.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/10/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPActivityQuestHandin.h"
#import "BotController.h"
#import "MacroController.h"
#import "Mob.h"
#import "MPMover.h"
#import "MPTask.h"
#import "MPTimer.h"
#import "Node.h"
#import "PatherController.h"



@interface MPActivityQuestHandin (Internal)

- (void) clickQuestGiver;
- (void) clickQuestOption: (int) indx ;
- (void) clickContinue;
- (void) acceptReward;
- (void) clickAccept;

@end


@implementation MPActivityQuestHandin
@synthesize questGiver, questID, timeOutClick, mover; 


- (id)  initWithQuestGiver:(Mob *)npc andID:(NSString*) qID isAutoAccept:(BOOL) isAuto andReward:(int)oReward andTask:(MPTask *)aTask  {
	
	if ((self = [super initWithName:@"QuestHandin" andTask:aTask])) {
		
		self.questGiver	= npc;
		self.questID = qID;
		self.timeOutClick = [MPTimer timer:1000];
		self.mover = [MPMover sharedMPMover];
		
		isAutoAccept = isAuto;
		
		questReward = oReward;
		if (questReward < 0) questReward = 0;
		
		countEntries = 0;
		
		state = QuestHandinActivityStarted;
	}
	return self;
}


- (void) dealloc
{
    [questGiver release];
	[questID release];
	[timeOutClick release];
	[mover release];
	
    [super dealloc];
}


#pragma mark -



// ok Start gets called 1x when activity is started up.
- (void) start {
	
	if (questGiver == nil) {
		PGLog( @"[ActivityQuestHandin] Error: ActivityQuestHandin called with questGiver == nil");
		return;
	}
	
	
	// if questGiver is in Distance
	float distanceToQuest = [task myDistanceToPosition:[questGiver position]];
	if (distanceToQuest <= 5.0 ) {
		
		
		PGLog( @"[ActivityQuestHandin] [start] Handing in Quest ... ");
		
		// face questGiver
		[mover faceLocation:(MPLocation *)[questGiver position]];
		
		// mouse click on mob
		[self clickQuestGiver];
		
		// timeOut start
		[timeOutClick start];
		
		
		state = QuestHandinActivityOpeningQuestgiver;
		
		
		return;
		
	} else{
		
		PGLog( @"[ActivityQuestHandin]  Error: too far away to attempt setting!  MPTaskQuestHandin -> needs to do a better job on approach." );
		
	} // end if in distance
	
	// hmmmm ... if we get here then we shouldn't be training
	state = QuestHandinActivityDone;
}



// work is called repeatedly every 100ms or so.
- (BOOL) work {
	
	// switch (state)
	switch (state) {
		case QuestHandinActivityStarted:
			
			//// How did we get here???
			PGLog( @"[ActivityQuestHandin] [start] opening Quest ... ");
			
			// face questGiver
			[mover faceLocation:(MPLocation *)[questGiver position]];
			
			// mouse click on mob
			[self clickQuestGiver];
			
			// timeOut start
			[timeOutClick start];
			
			
			state = QuestHandinActivityOpeningQuestgiver;
			
			return NO;
			break;
			
			
			
		case QuestHandinActivityOpeningQuestgiver:
			// NOTE: we really need a method to detect when the Innkeeper Window appears
			
			// if ([self questGiverWindowOpen]) {
			//		state = QuestHandinActivityClickingItems;
			//		[self clickNextItem];
			// }
			
			/// until then just wait for the timer to hope the window is open
			// if timeOut ready
			if ([timeOutClick ready]) {
PGLog(@"  +++++ QuestGiver should be open now");
				if (isAutoAccept) {
					
					[self clickContinue];
					state = QuestHandinActivityClickContinue;
					return NO;
				}
				
				
				// questGivers  might have several quest options so:
				state = QuestHandinActivityClickingQuestItem;
				countEntries = 1;
				[self clickQuestOption:countEntries];
				[timeOutClick start];
				
			} // end if
			
			return NO;
			break;
			
			
		case QuestHandinActivityClickingQuestItem:
			
			
			if ([timeOutClick ready]) {
				
				if (countEntries > 3) {
					[self clickContinue];
					state = QuestHandinActivityClickContinue;
				} else {
					countEntries++;
					[self clickQuestOption:countEntries];
					[timeOutClick start];
				}
			}
			return NO;
			break;
			
			
		case QuestHandinActivityClickContinue:
			if ([timeOutClick ready]) {
				state = QuestHandinActivityAcceptQuest;
				// then jump to Accept.
				if (questReward > 0) {
					[self acceptReward];
				} else {
					[self clickAccept];
				}
				[timeOutClick start];
				return NO;
			}
			return NO;
			break;
			
			
		case QuestHandinActivityAcceptQuest:
			if ([timeOutClick ready]) {
				state = QuestHandinActivityDone;
				return YES;
			}
			return NO;
			break;
			
			
		default:
		case QuestHandinActivityDone:
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
		case QuestHandinActivityStarted:
			[text appendString:@"   starting ... "];
			break;
			
		case QuestHandinActivityOpeningQuestgiver:
			[text appendString:@"   opening Quest Giver"];
			break;
			
		case QuestHandinActivityClickingQuestItem:
			[text appendString:@"  choosing the quest "];
			break;
			
		case QuestHandinActivityClickContinue:
			[text appendString:@"  clicking Continue."];
			break;
			
		case QuestHandinActivityAcceptQuest:
			[text appendString:@"  clicking Accept."];
			break;
			
		default:
		case QuestHandinActivityDone:
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


- (void) acceptReward {
	
	NSString *macroCommand = [NSString stringWithFormat:@"/run GetQuestReward(%d);", questReward];
	PGLog(@"  +++++ questHanding : %@",  macroCommand);
	[[[task patherController] macroController] useMacroOrSendCmd:macroCommand];
	
}


- (void) clickAccept {
	
PGLog(@" ++++ clicking accept ");
	[[[task patherController] macroController] useMacro:@"QuestComplete"];
	
}





#pragma mark -

+ (id) handinQuestTo:(Mob *)npc withID:(NSString*)qID isAutoAccept:(BOOL)isAuto withReward:(int)optionReward forTask:(MPTask *)aTask {
	
	return [[[MPActivityQuestHandin alloc] initWithQuestGiver:npc andID:qID isAutoAccept:isAuto andReward:optionReward andTask:aTask] autorelease];
}


@end