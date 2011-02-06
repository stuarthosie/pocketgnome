//
//  MPActivityMail.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/17/11.
//  Copyright 2011 Savory Software, LLC
//

#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPMover;
@class MPTimer;

@class Node;
@class MPTimer;
@class MPMover;


typedef enum MailActivity { 
    MailActivityStarted			= 1,	// haven't done Squat!
	MailActivityOpeningMailbox	= 2,	// attempting to open the Mail Window
	MailActivityClickingItems	= 3,	// clicking items to mail
	MailActivityDone			= 4		// All Done
} MPMailActivity; 


// This activity mails your stuff 
@interface MPActivityMail : MPActivity {

	Node *mailBox;
	NSString *mailToName;
	NSString *mailToSubj;
	NSString *mailToBody;
	
	NSArray *listToKeep, *listNamedToMail;
	NSMutableArray *listToMail;
	
	NSMutableString *luaCondition;
	
	BOOL mailWhite, mailGreen, mailBlue;
	
	MPMailActivity state;
	
	MPTimer *timeOutClick;
	MPMover *mover;
	
	int numItemsInMessage;
	
}

@property (retain) Node *mailBox;
@property (retain) NSString *mailToName, *mailToSubj, *mailToBody;
@property (retain) MPTimer *timeOutClick;
@property (retain) MPMover *mover;
@property (retain) NSArray *listToKeep, *listNamedToMail;
@property (retain) NSMutableArray *listToMail;
@property (retain) NSMutableString *luaCondition;


+ (id)  mailTo:(NSString *)name withSubject:(NSString *)subj withMessage:(NSString *)message usingMailbox:(Node *)aMailBox mailingItems:(NSArray *)listMailItems keepItems:(NSArray *)listProtectedItems whiteItems:(BOOL)doWhite greenItems:(BOOL)doGreen blueItems:(BOOL) doBlue forTask:(MPTask *)aTask;

@end
