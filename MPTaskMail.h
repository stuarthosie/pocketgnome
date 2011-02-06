//
//  MPTaskMail.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/19/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPTask.h"

@class Node;
@class MPActivityMail;
@class MPActivityWalk;



typedef enum MailTask {
	MailTaskWaiting		= 1,	// waiting for start condition
    MailTaskApproaching	= 2,	// getting withing range of given mailbox
	MailTaskMailing		= 3 	// In process of mailing
} MPMailTask;



/*!
 * @class      MPTaskMail
 * @abstract   Mail your stuff to another toon
 * @discussion 
 * Approaches a given mailbox and sends items in your bags that match the given criteria.
 * Parameters:
 *	$Location  : the location of the mailbox [x, y, z];
 *	$To		   : exact name of toon to mail to
 *  $Subj	   : (Optional) Subj line for mail messages
 *  $Message   : (Optional) Message body for mail messages
 *	$Items	   : list of items to Mail (no quality checks on these) (partial names ok)
 *	$Protected : list of itmes NOT to mail
 *	$MailWhites: Mail White Quality items?  (YES, NO)
 *	$MailGreens: Mail Green Quality items?  (YES, NO)
 *  $MailBlue  : Mail Blue Qaulity items?   (YES, NO)
 *	$MinFreeBagSlots : Go mail when # free bags slots <= this value
 * 
 * Example
 * <code>
 *	Mail
 *	{	
 *		$Prio = 5;
 *		$Location = [9853.06, 957.44, 1306.64];
 *
 *		$To = "Spanky";
 *		$Subj = "Here is some Stuff";	// optional
 *	    $Message = "Enjoy!";			// optional
 *
 *		$Items = [
 *					"Ore", "Stone", "leather", "Cloth",
 *					"Mote of", "Primal", "Eternal", "crystallized"
 *				 ];
 *
 *		$Protected = [
 *			 "Juice", "Gnomish Army Knife", "Blacksmith Hammer", "Crystalized",
 *			"Mote Extractor", "Rune", "Arcane Powder", "Cobalt Frag Bomb", "Arclight Spanner",
 *			"Conjured", "Mining Pick", "Skinning Knife",  "Potion",  
 *		];
 *		
 *		$MailWhite = true;
 *		$MailGreen = true;
 *		$MailBlue = true;
 *		$MinFreeBagSlots = 3;     // optional but leaving out changes how it works
 *	}
 * </code>
 *
 * Note: if you leave $MinFreeBagSlots out, then this task will only operate 1 time, then will
 *		 need to be reset before it will operate again.
 *		
 */

@interface MPTaskMail : MPTask {
	
	MPLocation *mailboxLocation;
	NSString *mailTo, *mailSubj, *mailMessage;
	
	NSArray *listMailItems;
	NSArray *listProtectedItems;
	BOOL mailWhite, mailGreen, mailBlue;
	
	BOOL isDone;
	
	MPMailTask state;
	
	NSInteger minFreeBagSlots;
	
	Node *selectedMailbox;
	
	MPActivityMail *activityMail;
	MPActivityWalk *activityApproach;
	
	

}

@property (retain) MPLocation *mailboxLocation;
@property (retain) NSString *mailTo, *mailSubj, *mailMessage;
@property (retain) NSArray *listMailItems, *listProtectedItems;
@property (retain) MPActivityMail *activityMail;
@property (retain) MPActivityWalk *activityApproach;
@property (retain) Node *selectedMailbox;

+ (id) initWithPather: (PatherController*)controller;

@end
