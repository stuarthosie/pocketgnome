//
//  MPActiviyLogout.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/1/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>
#import "MPActivity.h"

@class MPTimer;



typedef enum LogoutActivity { 
    LogoutActivityWaiting			= 1,	// waiting to start
	LogoutActivityQuitting			= 2,	// Wait while we are quitting 
	LogoutActivityDone				= 3		// All Done
} MPLogoutActivity; 

// This activity uses your hearthstone

@interface MPActivityLogout : MPActivity {
	
	
	MPLogoutActivity state;
	MPTimer  *timeOutClick;
}
@property (retain) MPTimer *timeOutClick;


+ (id)  logoutForTask:(MPTask *)aTask;
@end
