//
//  MPMover.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 3/30/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <ScreenSaver/ScreenSaver.h>
#import <Carbon/Carbon.h>

#import "MPLocation.h"
#import "MPMover.h"
#import "MPTimer.h"
#import "PatherController.h"
#import "Controller.h"
#import "Position.h"
#import "PlayerDataController.h"
#import "SynthesizeSingleton.h"
#import "Unit.h"

@interface MPMover (Internal)

- (void) pressKey: (CGKeyCode) keyCode;
- (void) releaseKey: (CGKeyCode) keyCode;

//- (float) angleTurnTowards: (Position *)position;
- (void) calculateFacingTowards: (MPLocation *) locationFacing;
- (void) calculateMovementTowards: (MPLocation *)locationTo;
- (void) pressAndReleaseKeys;
- (void)setVerticalDirectionFacing: (float)direction;

- (BOOL) stuck;
- (void) attemptUnstick;

@end




@implementation MPMover
@synthesize destinationLocation, facingLocation, patherController;
@synthesize timerStuckCheck, referencePosition;
@synthesize lastFacingLocation;

SYNTHESIZE_SINGLETON_FOR_CLASS(MPMover);

- (id) init {
	return [self initWithController:nil];
}

- (id) initWithController: (PatherController*)controller {
	
	if ((self = [super init])) {
		
		self.destinationLocation = nil;
		self.facingLocation = nil;
		self.lastFacingLocation = nil;
		
		[self resetMovementState];
		self.patherController = controller;
		
		
		//// stuck Checking 
		self.timerStuckCheck = [MPTimer timer:333];
		[timerStuckCheck forceReady];
		
		self.referencePosition = nil;
		thinkStuck = NO;
		isStuck = NO;
		unstickAttempt = 0;
		verticleAdj = 0;
		
		closeEnough = INFINITY;
		angleTolerance = MP_PI_8;
		
	}
	return self;
}


- (void) dealloc
{
	[destinationLocation release];
	[facingLocation release];
    [patherController release];
	[timerStuckCheck release];
	[referencePosition release];
	
	[lastFacingLocation release];
	
    [super dealloc];
}


#pragma mark -


- (void) resetMovementState {
	
	runForwards = oldRunForwards	= NO;
	runBackwards = oldRunBackwards	= NO;
	strafeLeft	= oldStrafeLeft		= NO;
	strafeRight = oldStrafeRight	= NO;
	rotateLeft	= oldRotateLeft		= NO;
	rotateRight	= oldRotateRight	= NO;
	swimUp		= oldSwimUp			= NO;
	
	closeEnough = INFINITY;
	angleTolerance = MP_PI_8;
	
	referencePosition = nil;
	thinkStuck = NO;
	isStuck = NO;
	verticleAdj = 0;
}

#pragma mark -
#pragma mark Movement Info

- (BOOL) isMoving {
	return (runForwards || runBackwards || strafeLeft || strafeRight );
}

- (BOOL) isRotating {
	return (rotateLeft || rotateRight);
}

- (BOOL) isRotateingLeft {
	return rotateLeft;
}

- (BOOL) isRotatingRight {
	return rotateRight;
}



- (float) angleTurnTowards: (Position *)position {
	
	PlayerDataController *player = [PlayerDataController sharedController];
	Position *myPosition = [player position];
	float angle = [myPosition angleTo:position];
	float myDirection = [player directionFacing];
	
	if ( fabsf(angle - myDirection) > M_PI ){
		if ( angle < myDirection )	angle += (M_PI*2);
		else	myDirection += (M_PI*2);
	}
	
	return (angle - myDirection);
	
	// returns a value 0 - PI (3.14159... )
	//    0 : front
	//    PI: behind
	//	< 0 : right
	//  > 0 : left
}



- (int) directionOfPosition: (Position *)position {

	/*
		Return Values:
			0 - undefined
			1 - front
			2 - right
			3 - back
			4 - left
	 */
	
	if (position == nil) {
		return 0;
	}
	
	float angleTo = [self angleTurnTowards: position];
	
	int direction = 0;
	
	
	if ( (angleTo < M_PI_4) && (angleTo > -M_PI_4)) {
		direction = 1;
	}
	if ( (angleTo <= -M_PI_4) && (angleTo > -3*M_PI_4)) {
		direction = 2;
	}
	if ( (angleTo <= -3*M_PI_4) || (angleTo >= 3*M_PI_4) ) {
		direction = 3;
	}
	if ( (angleTo >= M_PI_4) && (angleTo < 3*M_PI_4)) {
		direction = 4;
	}
	
	return direction;
}


- (void) faceLocation: (MPLocation *) location {
	
	self.facingLocation = nil;
	self.facingLocation = location;
//	PGLog (@" facingLocation: %@", facingLocation );
	
}


- (BOOL) shouldMoveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing {
	return [self shouldMoveTowards:locDestination within:howClose facing:locFacing withinTolerance:MP_PI_8];
}


- (BOOL) shouldMoveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing withinTolerance:(float) toleranceAngle {


	BOOL shouldMove = NO;
	PlayerDataController *me = [PlayerDataController sharedController];
	float distanceTo = [[me position] distanceToPosition:locDestination ];
	
	if (distanceTo > howClose) {
		shouldMove = YES;
	}
	
	float angleTurn = [self angleTurnTowards:locFacing];
	if (fabsf(angleTurn) >= toleranceAngle) {
		shouldMove = YES;
	}
	
	return shouldMove;

}


//// Now decide if we should move and lock in movement data
- (BOOL) moveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing {

	return [self moveTowards:locDestination within:howClose facing:locFacing withinTolerance:MP_PI_8];
}

- (BOOL) moveTowards: (MPLocation *)locDestination within:(float)howClose facing:(MPLocation *)locFacing withinTolerance:(float) toleranceAngle {

	PGLog( @" moveTowards %@  within[%0.2f] while facing %@", locDestination, howClose, locFacing);
	
	
	BOOL shouldMove = [self shouldMoveTowards:locDestination within:howClose facing:locFacing withinTolerance:toleranceAngle];
	
	if (shouldMove ) {
		
		self.destinationLocation = locDestination;
		self.facingLocation = locFacing;
		closeEnough = howClose;
		angleTolerance = toleranceAngle;
		
	} else {
		PGLog(@"  Don't think I should move, so [stopMove]");
		[self stopMove];
		
		verticleAdj = 0;
/*		self.destinationLocation = nil;
		self.facingLocation = nil;
		closeEnough = 4.5f;
		angleTolerance = MP_PI_8;
 */
	}
	
	return shouldMove;
}



- (void) calculateFacingTowards: (MPLocation *) locationFacing {
	
	if (locationFacing == nil) return;
	
	float angleTo = [self angleTurnTowards:locationFacing];


	
	// if location is too far to my left
	if (angleTo > angleTolerance) {
//PGLog(@" facing angleTo[%0.4f] ---> rotate Left ", angleTo);		
		[self rotateLeft:YES];
		
	} else if (angleTo < -angleTolerance) {
		// if position is too far to my right
//PGLog(@" facing angleTo[%0.4f] ---> rotate Right ", angleTo);		
		[self rotateRight:YES];
		
	} else if (rotateLeft || rotateRight) {
		// location is in front of me, but I'm scheduled to turn still 

//PGLog(@" facing angleTo[%0.4f] ---> Stop Turning ", angleTo);
		[self rotateLeft:NO];
		[self rotateRight:NO];
	}
//else {
//PGLog(@" facing angleTo[%0.4f] ---> keep! ", angleTo);		
//}
	
}



- (void) calculateMovementTowards: (MPLocation *)locationTo {

	if (locationTo == nil) return;
	
	PlayerDataController *me = [PlayerDataController sharedController];
	float distanceToLocation = [[me position] distanceToPosition:locationTo];
	float cutoff = closeEnough;
	if (cutoff < 1.0f) cutoff = 1.0f;
	
PGLog(@" distanceTo[%0.4f] / cutoff[%0.4f] ", distanceToLocation, cutoff);
	
	if (distanceToLocation > cutoff) {
		
		// get direction to desired location
		int direction = [self directionOfPosition:locationTo];
			// 1 - forwards
			// 2 - right
			// 3 - backwards
			// 4 - left
		
		// if moving forwards or backwards (or unknown)
		if ((direction == 1) || (direction == 3) || (direction == 0)) {
			
			// stop strafing
			[self strafeLeft:NO];
			[self strafeRight:NO];
		}
		
		// if to the side then stop forward/backward
		if ((direction == 2) || (direction == 4) || (direction == 0)) {
			
			[self forwards:NO];
			[self backwards:NO];
		}
		
		if (direction == 1) {
			[self forwards:YES];
		}
		
		if (direction == 2) {
			[self strafeRight:YES];
		}
		
		if (direction == 3) {
			[self backwards:YES];	
		}
		
		if (direction == 4) {
			[self strafeLeft:YES];	
		}
		
	} else {
		
		[self forwards:NO];
		[self strafeRight:NO];
		[self backwards:NO];
		[self strafeLeft:NO];
		
	}
}



- (void) pressAndReleaseKeys {
	
		
	BOOL tempRunForwards  = runForwards;
	BOOL tempRunBackwards = runBackwards;
	BOOL tempStrafeLeft   = strafeLeft;
	BOOL tempStrafeRight  = strafeRight;
	BOOL tempRotateLeft   = rotateLeft;
	BOOL tempRotateRight  = rotateRight;
	BOOL tempSwimUp       = swimUp;
	
	////
	//// release all unpressed keys just to make sure not stuck
	////
	
	if ((!tempRunForwards) && (tempRunForwards != oldRunForwards)) {
		[self releaseKey:kVK_ANSI_W]; // Forwards
		PGLog(@"   ++Release [Forwards]++");
	}
	
	if ((!tempRunBackwards) && (tempRunBackwards != oldRunBackwards)) {
		[self releaseKey:kVK_ANSI_S]; // Backwards
		PGLog(@"   ++Release [Backwards]++");
	}
	
	if ((!tempStrafeLeft) && (tempStrafeLeft != oldStrafeLeft)) {
		[self releaseKey:kVK_ANSI_Q];
		PGLog(@"   ++Release [Strafe Left]++");
	}
	
	if ((!tempStrafeRight) && (tempStrafeRight != oldStrafeRight)) {
		[self releaseKey:kVK_ANSI_E];
		PGLog(@"   ++Release [Strafe Right]++");
	}
	
	if ((!tempRotateLeft) && (tempRotateLeft != oldRotateLeft)) {
		[self releaseKey:kVK_ANSI_A];
		PGLog(@"   ++Release [Rotate Left]++");
	}
	
	if ((!tempRotateRight) && (tempRotateRight != oldRotateRight)) {
		[self releaseKey:kVK_ANSI_D];
		PGLog(@"   ++Release [Rotate Right]++");
	}
	
	if ((!tempSwimUp) && (tempSwimUp != oldSwimUp)) {
		[self releaseKey:kVK_Space];
		PGLog(@"   ++Release [Swim Up]++");
	}
	
	////
	//// press all desired keys 
	////
	
	if ((tempRunForwards) && (tempRunForwards != oldRunForwards)) {
		[self pressKey:kVK_ANSI_W];
		PGLog(@"   ++Press [Forwards]++");
	}
	
	if ((tempRunBackwards) && (tempRunBackwards != oldRunBackwards)) {
		[self pressKey:kVK_ANSI_S];
		PGLog(@"   ++Press [Backwards]++");
	}
	
	if ((tempStrafeLeft) && (tempStrafeLeft != oldStrafeLeft)) {
		[self pressKey:kVK_ANSI_Q];
		PGLog(@"   ++Press [Strafe Left]++");
	}
	
	if ((tempStrafeRight) && (tempStrafeRight != oldStrafeRight)) {
		[self pressKey:kVK_ANSI_E];
		PGLog(@"   ++Press [Strafe Right]++");
	}
	
	if ((tempRotateLeft) && (tempRotateLeft != oldRotateLeft)) {
		[self pressKey:kVK_ANSI_A];
		PGLog(@"   ++Press [Rotate Left]++");
	}
	
	if ((tempRotateRight) && (tempRotateRight != oldRotateRight)) {
		[self pressKey:kVK_ANSI_D];
		PGLog(@"   ++Press [Rotate Right]++");
	}
	
	if ((tempSwimUp) && (tempSwimUp != oldSwimUp)) {
		[self pressKey:kVK_Space];
		PGLog(@"   ++Press [Swim Up]++");
	}
	
	////
	//// Store our keys 
	////
	
	oldRunForwards	= tempRunForwards;
	oldRunBackwards	= tempRunBackwards;
	oldStrafeLeft	= tempStrafeLeft;
	oldStrafeRight	= tempStrafeRight;
	oldRotateLeft	= tempRotateLeft;
	oldRotateRight	= tempRotateRight;
	oldSwimUp		= tempSwimUp;
	
}



- (void) action {
	
	// To Do:  make sure Pather is running, if not, return
	//PGLog(@" -- Action -- " );
	[self calculateMovementTowards:destinationLocation];
	[self calculateFacingTowards:facingLocation];
	
	if ([self stuck]) {
		[self attemptUnstick];
	}
	
	[self pressAndReleaseKeys];
	
/*	if (facingLocation != nil) {
		PlayerDataController *me = [PlayerDataController sharedController];
		Position *ourPosition = [me position];
		[self setVerticalDirectionFacing:[ourPosition verticalAngleTo:facingLocation]];
	}
*/
	
	if (facingLocation != nil) {
		if (lastFacingLocation != facingLocation) {
			PlayerDataController *me = [PlayerDataController sharedController];

//			Position *adjustedLocation = [Position positionWithX:facingLocation.xPosition Y:facingLocation.yPosition Z:(facingLocation.zPosition - verticleAdj)];

//			[me faceToward:adjustedLocation];
//PGLog(@"+++ Facing Location +++  me:%@   floc:%@", [me position], adjustedLocation);
PGLog(@"+++ Facing Location +++  me:%@   floc:%@", [me position], facingLocation);
			[me faceToward:facingLocation];
			self.lastFacingLocation = facingLocation;
		}
	}
 

}


#pragma mark -
#pragma mark Basic Movements



- (void) backwards: (BOOL) go {
	
	runBackwards = go;
	if (go) {
		if (!oldRunBackwards) {
			PGLog(@"Backing Away.");
		} 
		runForwards = NO;
	} else {
		if (oldRunBackwards) {
			PGLog(@"Stop Backing Away.");
		}
	}
}



- (void) forwards: (BOOL) go {
	
	runForwards = go;
	if (go) {
		if (!oldRunForwards) {
			PGLog(@"Running Forwards.");
		} 
		runBackwards = NO;
	} else {
		if (oldRunForwards) {
			PGLog(@"Stop Running Forwards.");
		}
	}
}



- (void) rotateLeft: (BOOL) go {
	
	rotateLeft = go;
	if (go) {
		if (!oldRotateLeft) {
			PGLog(@"Rotating Left.");
		} 
		rotateRight = NO;
	} else {
		if (oldRotateLeft) {
			PGLog(@"Stop Rotating Left.");
		}
	}
}



- (void) rotateRight: (BOOL) go {
	
	rotateRight = go;
	if (go) {
		if (!oldRotateRight) {
			PGLog(@"Rotating Right.");
		} 
		rotateLeft = NO;
	} else {
		if (oldRotateRight) {
			PGLog(@"Stop Rotating Right.");
		}
	}
}



- (void) strafeLeft: (BOOL) go {
	
	strafeLeft = go;
	if (go) {
		if (!oldStrafeLeft) {
			PGLog(@"Strafing Left.");
		} 
		strafeRight = NO;
	} else {
		if (oldStrafeLeft) {
			PGLog(@"Stop Strafing Left.");
		}
	}
}



- (void) strafeRight: (BOOL) go {
	
	strafeRight = go;
	if (go) {
		if (!oldStrafeRight) {
			PGLog(@"Strafing Right.");
		} 
		strafeLeft = NO;
	} else {
		if (oldStrafeRight) {
			PGLog(@"Stop Strafing Right.");
		}
	}
}



- (void) swimUp: (BOOL) go {
	
	swimUp = go;
	if (go) {
		if (!oldSwimUp) {
			PGLog(@"Swimming Up.");
		} 
	} else {
		if (oldSwimUp) {
			PGLog(@"Stop Swimming Up.");
		}
	}
}



// 1 write
- (void)setVerticalDirectionFacing: (float)direction {
    [[[Controller sharedController] wowMemoryAccess] saveDataForAddress: ([[PlayerDataController sharedController] baselineAddress] + BaseField_Facing_Vertical) Buffer: (Byte *)&direction BufLength: sizeof(direction)];
}



#pragma mark -
#pragma mark Stuck Detection Helpers


- (BOOL) stuck {
	
	// if timerStuckCheck ready
	if ([timerStuckCheck ready] ) {
		
		[timerStuckCheck start];
		
		// if moving
		if ([self isMoving]) {
			
			Position *currentPosition = [[PlayerDataController sharedController] position];
			
			// if referencePoint != nil
			if (referencePosition != nil) {
				
				// if I'm not debuffed 
					// if distanceTo CurrentPosition > 2
					float distance = [referencePosition distanceToPosition:currentPosition];
					
					// TO DO: should choose different values here based on 
					//   if mounted , value = a
					//	 if fast mounted, value = b
					//   if swimming, value = c
					//   if stealthed value = d
					//   ....
					// for now, pick a small enough value to catch bad stucks, but not 
					// trigger if stealthed: ~ 0.65?  
					if (distance > 0.65f) {  
						
						// all good so update reference
						self.referencePosition = currentPosition;
						thinkStuck = NO;
						
					} else {
						
						// didn't move very much so:
						thinkStuck = YES;
						unstickAttempt ++;
						if (unstickAttempt >= 8) {
							isStuck = YES;
						}
						
					} // end if
				// end if
			} else { 
				
				self.referencePosition = currentPosition;
				thinkStuck = NO;
				
			} // end if
			
		} else {
			
			self.referencePosition = nil;
			thinkStuck = NO;
			
		} // end if
		
	} // end if timerStuckCheck ready
	
	
	if (!thinkStuck) {
//		unstickAttempt = 0;
		isStuck = NO;
	}
	
	return thinkStuck;
}



- (void) attemptUnstick  {
	
	if (facingLocation) {
		if ([facingLocation zPosition] < [[[PlayerDataController sharedController] position] zPosition]) {
			verticleAdj += 1.0f;
			if (verticleAdj > 50.0f) verticleAdj = 50.0f;
			
			self.lastFacingLocation = nil;
			PGLog(@"verticleAdj[%0.4f]  %@   %@", verticleAdj, facingLocation, [[PlayerDataController sharedController] position]);
		}
	}
	
	switch (unstickAttempt) {
		case 1:
			// try jumping
			[self swimUp:YES];
			
			break;
			
		case 2:
			[self stopMove];
			
			// switch forwards/backward movement & strafe left
			if (runForwards) {
				[self backwards:YES];
			}else {
				[self forwards:YES];
			}
			[self strafeLeft:YES];
			break;
			
		case 3:
			// adds jumping to case 2
			[self stopMove];
			
			// switch forwards/backward movement & strafe left
			if (runForwards) {
				[self backwards:YES];
			}else {
				[self forwards:YES];
			}
			[self strafeLeft:YES];
			[self swimUp:YES];
			break;
			
		case 4:
			[self stopMove];
			
			// switch forwards/backwards movenet & strafe right
			if (runForwards) {
				[self backwards:YES];
			}else {
				[self forwards:YES];
			}
			[self strafeRight:YES];
			break;
			
		case 5:
			//// Add Jumping to Case 4
			[self stopMove];
			
			// switch forwards/backwards movenet & strafe right
			if (runForwards) {
				[self backwards:YES];
			}else {
				[self forwards:YES];
			}
			[self strafeRight:YES];
			[self swimUp:YES];
			break;
			
		case 6:
		default:
			[self stopMove];
			
			// moveRandom
			int r = arc4random() % 4;
			switch( r) {
				case 0:
					// forwards
					[self forwards:YES];
					break;
				case 1:
					// strafe left	
					[self strafeLeft:YES];
					break;
				case 2:
					// backwards
					[self backwards:YES];
					break;
				case 3:
					// strafe Right
					[self strafeRight:YES];
					break;
			}
			
			// reset unstickAttempt
			unstickAttempt = 0;
			break;

	}

	
}


#pragma mark -
#pragma mark Stop Commands

- (void) stopRotate {
	
	if (rotateLeft || rotateRight) {
		PGLog(@"Stop Rotate");
	}
	
	self.facingLocation = nil;
	
	[self rotateLeft:NO];
	[self rotateRight:NO];
}


- (void) stopMove {
	
	if (runForwards || runBackwards || strafeLeft || strafeRight || rotateLeft || rotateRight || swimUp){
		PGLog(@"Stop Move");
	}
	
	self.destinationLocation = nil;
//	self.facingLocation = nil;
	
	[self forwards:NO];
	[self backwards:NO];
	[self strafeLeft:NO];
	[self strafeRight:NO];
	[self rotateLeft:NO];
	[self rotateRight:NO];
	[self swimUp:NO];
	
	// should I pause here?
	
}

- (void) stopAllMovement {
	
	// release all keys
	
//	[self resetMovementState];
	
	[self stopMove];
	
	[self stopRotate];
}


#pragma mark - 
#pragma mark Key Pressing

- (void) pressKey: (CGKeyCode) keyCode {
//	[self setIsMoving: YES];
	Controller *controller = [Controller sharedController];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyDown = CGEventCreateKeyboardEvent(NULL, keyCode, TRUE);
    if(wKeyDown) {
        CGEventPostToPSN(&wowPSN, wKeyDown);
        CFRelease(wKeyDown);
    }
}


- (void) releaseKey: (CGKeyCode) keyCode {
	//	[self setIsMoving: NO];
	Controller *controller = [Controller sharedController];
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    CGEventRef wKeyUp = CGEventCreateKeyboardEvent(NULL, keyCode, FALSE);
    if(wKeyUp) {
        CGEventPostToPSN(&wowPSN, wKeyUp);
        CFRelease(wKeyUp);
    }
}

#pragma mark -
#pragma mark Convienience Constructors

//+ (id) moverWithController:(PatherController*)controller  {
	
//	MPMover *newMover = [[MPMover alloc] initWithController:controller];
//	return [newMover autorelease];
//}

@end
