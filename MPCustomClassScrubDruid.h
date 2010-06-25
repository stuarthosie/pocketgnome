//
//  MPCustomClassScrubDruid.h
//  Pocket Gnome
//
//  Created by codingMonkey on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCustomClassScrub.h"

@class MPSpell;
@class MPItem;
@class MPTimer;


@interface MPCustomClassScrubDruid : MPCustomClassScrub {

	MPSpell *abolishPoison, *curePoison, *insectSwarm, *innervate, *wrath, *mf, *motw, *rejuv, *healingTouch, *removeCurse, *starfire, *thorns;
	MPItem *drink;
	MPTimer *waitDrink, *timerRunningAction;
}
@property (retain) MPSpell *abolishPoison, *curePoison, *insectSwarm, *innervate, *wrath, *mf, *motw, *rejuv, *healingTouch, *removeCurse, *starfire, *thorns;
@property (retain) MPItem *drink;
@property (retain) MPTimer *waitDrink, *timerRunningAction;

@end
