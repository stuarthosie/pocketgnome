//
//  PatherController.m
//  TaskParser
//
//  Created by Coding Monkey on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PatherController.h"
//#import "WoWObject.h"
#import "MPParser.h"
#import "MPStack.h"

#import "MPPerformanceController.h"

// for testing:
#import "MPValue.h"
#import "MPTask.h"
#import "MPActivity.h"
#import "MPCustomClass.h"
#import "MPCustomClassPG.h"
#import "MPCustomClassScrubDruid.h"
#import "MPCustomClassScrubHunter.h"
#import "MPCustomClassScrubPriest.h"
#import "BotController.h"
#import "Controller.h"
#import "WaypointController.h"
#import "CombatController.h"
#import "PlayerDataController.h"
#import "Route.h"
#import "RouteSet.h"
#import "Position.h"
#import "Procedure.h"
#import "Condition.h"
#import "Rule.h"
#import "Behavior.h"
#import "MPNavMeshView.h"
#import "MPNavigationController.h"
#import "MPLocation.h"
#import "MPAVLTree.h"
#import "MPAVLRangedTree.h"
#import "MPPoint.h"
#import "MPPointTree.h"
#import "MPSquareTree.h"
#import "MPSquare.h"
#import "MovementController.h"
#import "BlacklistController.h"
#import "RouteSet.h"
#import "SynthesizeSingleton.h"
#import "MPMover.h"
#import "NodeController.h"
#import "MPToonData.h"

@interface PatherController (Internal)

- (void) doMoverAction;

- (MPLocation *) myCurrentLocation;

// for generating a Pather Task from PG info
- (NSString *) defendTaskData;
- (NSString *) lootTaskData;
- (NSString *) restTaskData;
- (NSString *) pullTaskData;
- (NSString *) routeTaskData;
- (NSString *) ghostRouteTaskData;

// Kill Count methods
- (NSString *) keyKillCount: (NSString*) mobName;

// thread for updating the NavMeshView
- (void) updateNavMeshView;
- (void) updateNavMeshAdjustment;

@end


@implementation PatherController
@synthesize taskController;
@synthesize botController, controller, macroController, movementController, mobController, playerData, combatController, lootController, waypointController, blacklistController, navigationController, nodeController;
@synthesize timerCheckPatherStopConditions, timerEvaluateTasks, timerProcessCurrentActivity, timerUpdateUI, timerPerformanceCycle,  timerGraphBuilder, timerGraphOptimizations;
@synthesize timerWorkTime;
@synthesize listCustomClasses, customClass;
@synthesize combatMover;
@synthesize unitsLootBlacklisted, unitsBlacklisted;
@synthesize listKillCountNames;
@synthesize deleteMeRouteDest;
@synthesize toonData;

@synthesize textboxManualLocation, enableManualGraphMovement, enableGraphOptimizations;


SYNTHESIZE_SINGLETON_FOR_CLASS(PatherController);

// view display related
@synthesize view, minSectionSize, maxSectionSize;
- (NSString*)sectionTitle {
    return @"Pather";
}


- (id) init {
	if ((self = [super init])) {
		self.timerCheckPatherStopConditions = nil;
		self.timerEvaluateTasks = nil;
		self.timerProcessCurrentActivity = nil;
		self.timerUpdateUI = nil;
		self.timerPerformanceCycle = nil;
//		self.timerMPMover = nil;
		self.timerGraphBuilder = nil;
		self.timerGraphOptimizations = nil;
		
		self.timerWorkTime = [MPTimer timer:1000];
		self.listCustomClasses = [NSMutableArray array];
		self.customClass = nil;
		self.combatMover = [MPMover sharedMPMover];
		
		self.unitsLootBlacklisted = [NSMutableArray array];
		self.unitsBlacklisted = [NSMutableArray array];
		
		self.listKillCountNames = [NSMutableArray array];
		
		[NSBundle loadNibNamed: @"pather" owner: self];
		
		// flags for Thread Execution
		isThreadStartedNavMeshView = NO;
		isThreadStartedNavMeshAdjustments = NO;
		
		isMoverThreadCreated = NO;
		
		doMoverAction = NO;
		
		self.deleteMeRouteDest = nil;
	
	}
	return self;
}


#pragma mark -
#pragma mark User Interface

- (void)awakeFromNib
{
	NSArray *columnArray;
	int i;
	
	// setup the panel's size
	self.minSectionSize = [self.view frame].size;
    self.maxSectionSize = [self.view frame].size;
	
	
	// clicks in our list of items will result in our
	// handleClickAction method getting called
	//	 [myTableView setAction:@selector(handleClickAction:)];
	//	 [myTableView setTarget:self];
	
	// get a list of all columns for our NSTableView
	columnArray = [taskOutlineView tableColumns];
	for (i=0;i<[columnArray count];++i)
	{
		NSTableColumn *column;
		
		column = [columnArray objectAtIndex:i];
		// set the identifier for this column to the title string
		// for the column which we've specified in Interface Builder
		// (i.e. "messageID"). We'll use this identifier as a key
		// value when filling our NSTableView. See the
		// objectValueForTableColumn method below for the details
		[column setIdentifier:[[column headerCell] stringValue]];
	}
	
	
	[averageLoadIndicator setIntValue:75];
	
	// restore the previous TaskFile settings
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"PatherDataFolder"]) {
		NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey: @"PatherDataFolder"];
		[pathDataFolderView setStringValue:fileName];
	}
	
	// restore the previous TaskFile settings
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"PatherTaskFileName"]) {
		NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey: @"PatherTaskFileName"];
		[pathView setStringValue:fileName];
	}
	
	
	//// PLUGIN
	// Scan for plug-in character classes here, put in an array to load into the 
	// list below.
	
	
	// Now populate the list of custom Classes here:
	[listCustomClasses addObject:[MPCustomClassPG classWithController:self]];
	[listCustomClasses addObject:[MPCustomClassScrubDruid classWithController:self]];
	[listCustomClasses addObject:[MPCustomClassScrubHunter classWithController:self]];
	[listCustomClasses addObject:[MPCustomClassScrubPriest classWithController:self]];
	[chooseCustomClass removeAllItems];
	for( MPCustomClass *currClass in listCustomClasses) {
		[chooseCustomClass addItemWithTitle:[currClass name]];
	}
	
	// Initialize Chosen Class to previous settings
	if ([[NSUserDefaults standardUserDefaults] objectForKey: @"PatherCustomClassChosen"]) {
		NSString *chosenClassName = [[NSUserDefaults standardUserDefaults] objectForKey: @"PatherCustomClassChosen"];
		[chooseCustomClass selectItemWithTitle:chosenClassName];
	}
	
	
	
	//// init the NavMesh display Options:
//	[scaleSlider setFloatValue:1.0f];
	[navMeshView setScaleSetting:1.0f];
	[scaleValue setStringValue:@"4"];
//	[areaSlider setFloatValue:2.0f];
	[areaValue setStringValue:@"1"];
	
	
	[textboxManualLocation setStringValue:[NSString stringWithString:@"[9807.0, 913.0, 1301.46]"]];
	

}



- (void) updateUI {
	[timerWorkTime start];
	
//	PGLog( @" [[[[updateUI() ... ]]]]" );
	
	// update the Pather Task display
	[taskOutlineView reloadData];
	
	// currentTask
	MPActivity *currentActivity = [taskController currentActivity];
	MPTask *currentTask = [currentActivity task];
	if (currentTask != nil)
		[taskDescription setStringValue:[currentTask description]];
	
	// current Activity
	if (currentActivity != nil)
		[activityDescription setStringValue:[currentActivity description]];
	
	// update XP/Hr
	// update User Stats
	// update averateLoad
//	[averageLoadIndicator setIntValue:[performanceController averageLoad]];
	
//PGLog( @" End ::: [[[[updateUI() ... ]]]]" );
	// now record our current work time.
	[performanceController storeWorkTime:[timerWorkTime elapsedTime]];
}

#pragma mark -
#pragma mark Interface Actions


- (IBAction) findFile: sender {
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
    if ([panel runModal] == NSOKButton)
    {
        NSString *filename = [panel filename];
		[pathView setStringValue:filename];
		[startBotButton setEnabled:YES];

		// Store this task file info in UserDefaults
		[[NSUserDefaults standardUserDefaults] setObject:filename forKey: @"PatherTaskFileName"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		
    }
	
}

//// Delete Me:  testing DB creation and such:
- (IBAction) loadDB: sender {

	// this is manually done, probably without WOW loaded, so manually set the zone
	[navigationController setZone:[textBoxZoneID intValue]];
	[navigationController openMeshData:[pathDataFolderView stringValue]];

//	MPLocation *testLocation = [MPLocation locationAtX:9807.0 Y:913	Z:1301.46];
//	[navigationController loadInitialGraphChunkAroundLocation:testLocation];
	[navigationController loadAllSquares];
}

- (IBAction) testDB: sender {
	
	
	//// Test Toon Data
	/*
	[toonData openToonData:[pathDataFolderView stringValue]];
	[toonData setToonName:@"Skippy"];
	[toonData loadToonData];
	NSString *key = [NSString stringWithString:@"Quest951"];
	NSString *value = [toonData valueForKey:key];
	if (value == nil) {
		PGLog(@" ++++ value was nil ++++");
	}
	int id=951;
	key = [NSString stringWithFormat:@"Quest%d", id];
	[toonData setValue:@"Pickedup" forKey:key];
	*/
	
	//// Test task loading
	/*
	 *
	[taskController loadTaskFile:[pathView stringValue] withPather:self];
	[taskOutlineView reloadData]; // reload the Task View now.
	 
	 */
	
/*
	MPSquare *currentSquare = [navigationController squareContainingLocation:(MPLocation *)[playerData position]];
	if (currentSquare != nil) {
		
		MPPoint *currentPoint = [[currentSquare points] objectAtIndex:1];  // for testing choose lowerleft point
		[navigationController optimizeGraphAtPoint:currentPoint];
	}
 
 */
	
	
}
- (IBAction) optimizePass: sender {
	
	[navigationController optimizeGraph];
}

- (IBAction) findDataPath: sender {
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	[panel setCanChooseDirectories:YES];
	[panel setCanCreateDirectories:YES]; 
	[panel setPrompt:@"Choose folder"]; 
	[panel setCanChooseFiles:NO];
	
    if ([panel runModal] == NSOKButton)
    {
        NSString *filename = [panel filename];
		[pathDataFolderView setStringValue:filename];
		
		// Store this task file info in UserDefaults
		[[NSUserDefaults standardUserDefaults] setObject:filename forKey: @"PatherDataFolder"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		
    }
	
}



- (IBAction) chooseClass: sender {
	
	NSString *chosenClassName = [chooseCustomClass titleOfSelectedItem];
	
	[chooseCustomClass synchronizeTitleAndSelectedItem];
	
	// Store this task file info in UserDefaults
	[[NSUserDefaults standardUserDefaults] setObject:chosenClassName forKey: @"PatherCustomClassChosen"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	for (MPCustomClass *currClass in listCustomClasses) {
	
		if ([[currClass name] isEqualToString:chosenClassName]) {
			
			if (![[customClass name] isEqualToString:[currClass name]]) {
				PGLog(@"  *** Changing Custom Class to [%@]", [currClass name]);
				self.customClass = currClass;
				[customClass setup];
			}
		}
	}
	
}



- (IBAction) pausePather: sender {
	
	if ([taskController currentRunningState] != RunningStateStopped) {
		
		// if runningState == paused 
		if ( [taskController currentRunningState] == RunningStatePaused) {
			
			// wantedState = running
			[taskController setWantedRunningState: RunningStateRunning];
			[pauseBotButton setTitle:@"Pause Bot"];
			
		} else {
			// wanted state = paused
			[taskController setWantedRunningState: RunningStatePaused];
			
			[pauseBotButton setTitle:@"unPause Bot"];
			
		}// end if
	}
}


- (IBAction) startPather: sender {
	
	PGLog( @"startPather");
	
	// if we are not already running ... 
	if ([taskController currentRunningState] != RunningStateRunning) {
		PGLog( @"   taskController !Running");
		
		//// BotController setup
		[botController setPatherEnabled:YES];
		[botController startBot:nil];
		
		
		//// Verify Pather Data Folder exists
		
		
		//// Load ToonData
		//// NOTE:  do this before you load your tasks, since some tasks will attemt to 
		////        initialize their data from toonData.
		[toonData openToonData:[pathDataFolderView stringValue]];
		//[toonData setToonName:[playerData playerName]];
		// playerName returns ""  ... so grab it from playerHeader:
		NSString *playerHeader = [playerData playerHeader];
		NSRange commaRange = [playerHeader rangeOfString:@","];
		toonData.toonName = [playerHeader substringToIndex:commaRange.location];
PGLog(@" +++++ playerName at start:  td[%@]  pd.pn[%@]", toonData.toonName, [playerData playerHeader]);
		[toonData loadToonData];
		
		
		//// Verify Task File is loaded
		[taskController loadTaskFile:[pathView stringValue] withPather:self];
		[taskOutlineView reloadData]; // reload the Task View now.
		
		
		//// Load up CustomClass 
		if ( customClass == nil) {
			[self chooseClass:nil];
		}
		PGLog(@"Using customClass [%@]", [customClass name]);
		if ([[customClass name] isEqualToString:@"Pocket Gnome"])
		{
			[combatController setPatherCCEnabled:NO];
			[botController setPatherCCEnabled:NO];
		} else {
			// if not using the PG custom class, then tell 
			// combatController & botController to disengage
			[combatController setPatherCCEnabled:YES];
			[botController setPatherCCEnabled:YES];
		}
		[customClass setup];
		
		
		
		
	}
	
	//// if BotController->isBotting()
	if ([botController isBotting] ) {
		PGLog( @"botController isBotting ... ");		
		switch ([taskController currentRunningState]) {
				
			case RunningStateRunning:
				
				// wantedState == stop
				[taskController setWantedRunningState:RunningStateStopped];
				
				
				// do Stop Actions here... 
				// call taskController processActivities
				// disable processActivityTimer
				// call taskController evaluateTasks
				// disable evaluateTasksTimer
				// call checkPatherStopConditions
				// disable checkPatherStopConditionsTimer
				
				
				// button text = "Start"
				[startBotButton setTitle:@"Start"];
				[startBotButton setEnabled: NO];
				break;
				
			case RunningStateStopped:
				
				// do Start Actions here ... 
				// if fileLoaded and rootTask != nil 
				if ([taskController rootTaskLoaded] ) {
					
					// load up Navigation Mesh
					[navigationController openMeshData:[pathDataFolderView stringValue]];
					PGLog(@"  ---- startPather :: loading Initial Graph Location around %@", [playerData position]);
					[navigationController setZone:[playerData zone]];
					[navigationController loadInitialGraphChunkAroundLocation:(MPLocation *)[playerData position]];
					
					// update Button Display:
					[startBotButton setTitle:@"Stop Bot"];
					[startBotButton setEnabled: NO];  // disable until state switch is actually made
					
					
					// wantedState = RunningStateRunning
					[taskController setWantedRunningState:RunningStateRunning];
					
					// call checkPatherStopConditions  (which handles the StateChange)
					[self checkPatherStopConditions];
					
					
					//// Start the Mover's action  driver
					if (!isMoverThreadCreated) {
						PGLog(@" +++++++ Starting Mover Thread +++++++");
						[self performSelectorInBackground:@selector(doMoverAction) withObject:nil];
						isMoverThreadCreated = YES;
					}
					
				} else {
					
					// Log error: no Task file loaded
					PGLog(@"Error!  Start attempted with no Task file loaded.  Read in a file first.");
				} // end if
				break;
				
			default:
				break;
		}
		
	} else {
		PGLog (@"[Pather][startPather]: botController not botting!");
	} // end if botting
	
	
}



- (IBAction) generateList: sender {
	
	NSMutableString *taskData = [NSMutableString stringWithString:@"Par {\n\t$Prio=0;\n"];
	
	if ([includeDefendTask state]) {
		[taskData appendString:[self defendTaskData]];
	}
	
	if ([includeLootTask state]) {
		[taskData appendString:[self lootTaskData]];
	}
	
	if ([includeRestTask state]) {
		[taskData appendString:[self restTaskData]];
	}
	
	if ([includePullTask state]) {
		[taskData appendString:[self pullTaskData]];
	}
	
	if ([includeRouteTask state]) {
		[taskData appendString:[self routeTaskData]];
	}
	
	if ([includeGhostRouteTask state]) {
		[taskData appendString:[self ghostRouteTaskData]];
	}
	
	
	[taskData appendString:@"}"];
	
	[generatedTask setStringValue:taskData];
	
}


// respond to the Live Update checkbox for the navMesh display
- (IBAction) changeLiveUpdate: sender {

	if ([navMeshLiveUpdating state] ) {
	
		if (!isThreadStartedNavMeshView) { // <-- make sure thread not already started
			
			// this button was just clicked to ON, so start a thread to update
			// the display:
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshView) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshView) withObject:nil];
		}
	}
	
}

// updates the scale of the NavMesh display
- (IBAction) changeNavMeshScale: sender {
	[navMeshView setScaleSetting:[scaleValue floatValue]];
}





- (IBAction) modifyManualLocationUP : sender {
	
	MPLocation *location = [self locationManualLocation];
	
	float newY = [location yPosition];
	
	newY = newY + [adjXValue floatValue];
	
	NSString *newLocationValue = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f", [location xPosition], newY, [location zPosition]];
	[textboxManualLocation setStringValue:newLocationValue];
}




- (IBAction) modifyManualLocationDOWN : sender {
	
	MPLocation *location = [self locationManualLocation];
	
	float newY = [location yPosition];
	
	newY = newY - [adjXValue floatValue];
	
	NSString *newLocationValue = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f", [location xPosition], newY, [location zPosition]];
	[textboxManualLocation setStringValue:newLocationValue];
}




- (IBAction) modifyManualLocationLEFT : sender {
	
	MPLocation *location = [self locationManualLocation];
	
	float newX = [location xPosition];
	
	newX = newX - [adjXValue floatValue];
	
	NSString *newLocationValue = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f", newX, [location yPosition], [location zPosition]];
	[textboxManualLocation setStringValue:newLocationValue];
}




- (IBAction) modifyManualLocationRIGHT : sender {
	
	MPLocation *location = [self locationManualLocation];
	
	float newX = [location xPosition];
	
	newX = newX + [adjXValue floatValue];
	
	NSString *newLocationValue = [NSString stringWithFormat:@"%0.2f, %0.2f, %0.2f", newX, [location yPosition], [location zPosition]];
	[textboxManualLocation setStringValue:newLocationValue];
}


- (MPLocation *) locationManualLocation {
	// return a MPLocation from the text entered in the textbox:
	NSString *manualPlayerPosition = [textboxManualLocation stringValue];
	NSString *cleanedPosition = [manualPlayerPosition stringByReplacingOccurrencesOfString:@"[" withString:@""];
	NSString *cleanedPosition2 = [cleanedPosition stringByReplacingOccurrencesOfString:@"]" withString:@""];
	NSArray *locations = [cleanedPosition2 componentsSeparatedByString:@","];
	if ([locations count] > 2) {
		return [MPLocation locationFromVariableData:locations];
	} 
	return nil;
}


- (IBAction) optimizeCurrentSquare: sender {
	
	MPLocation *currentLocation;
	
	currentLocation = [self myCurrentLocation];
	
	MPSquare *currentSquare = [navigationController lowestSquareContainingLocation:currentLocation];
//PGLog(@" --- currentSquare: %@", [currentSquare name]);
	if (currentSquare != nil) {
		
//		MPPoint *currentPoint = [[currentSquare points] objectAtIndex:1];  // for testing choose lowerleft point
		[navigationController optimizeGraphAtSquare:currentSquare];
	}
	
}





- (IBAction) testStartOptimizationThread: sender {
	self.timerGraphOptimizations = [NSTimer scheduledTimerWithTimeInterval:0.25 target:navigationController selector:@selector(optimizeGraph) userInfo:nil repeats:YES];
}




- (IBAction) changeZTolerance: sender {

	[navigationController setToleranceZ: [[zToleranceText stringValue] floatValue]];
	
}

- (IBAction) changeNavMeshScaleFromText: sender {
	[navMeshView setScaleSetting:[scaleValue floatValue]];
}




- (IBAction) manualGraphAdjustment: sender {
	
	// if Creating Graphs
	if ([enableGraphAdjustments state]) {
		
		if (!isThreadStartedNavMeshAdjustments) {
			// make sure our thread for updating our NavMesh is running
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshAdjustment:) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshAdjustment) withObject:nil];
			
		}
	}// end if
	
	if ([navMeshLiveUpdating state] ) {
		
		if (!isThreadStartedNavMeshView) { // <-- make sure thread not already started
			
			// this button was just clicked to ON, so start a thread to update
			// the display:
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshView) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshView) withObject:nil];
		}
	}
}





- (IBAction) deleteSquareAtCurrentPosition: sender {
	
	Position *playerPosition = (Position *)[self myCurrentLocation];
	
	MPSquare *square = [navigationController lowestSquareContainingLocation:(MPLocation *)playerPosition];
	
	if (square) {
		
		[navigationController removeSquare:square];
	}
}



- (IBAction) testNudge: sender {
	MPLocation *location = [self myCurrentLocation];
	
	[navigationController nudgeConnectionsAtLocation:location];
	
}


- (MPLocation *) myCurrentLocation {
	
	Position *playerPosition;
	
	if ([enableManualGraphMovement state]) {
		
		playerPosition = (Position *)[self locationManualLocation];
		if (playerPosition == nil) {
			playerPosition = [Position positionWithX:9804.0 Y:870.0 Z:1304.0];
		}
		
		[navigationController setZone:[textBoxZoneID intValue]];
		
	} else {
		
		playerPosition = [playerData position];
	}
	
	return (MPLocation *)playerPosition;
	
}

// updates the Area of the NavMesh being updated

#pragma mark -
#pragma mark NavMesh Display

- (void) updateNavMeshView {

	//PGLog(@"updateNavMeshView: Opening..");
	isThreadStartedNavMeshView = YES;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	MPTimer *flushTimer = [MPTimer timer:5000];
	[flushTimer start];
	
	Position *playerPosition;
	
	while ([navMeshLiveUpdating state] ) {
//		PGLog(@"updateNavMeshThread: while loop iteration");
		
		// update player position
		playerPosition = (Position *) [self myCurrentLocation];
		
		
		
		
//		Position *playerPosition = [playerData position];
//		Position *playerPosition = [Position positionWithX:9804.0 Y:870.0 Z:1304.0];
		[labelCurrentPosition setStringValue: [NSString stringWithFormat:@"[%0.2f, %0.2f, %0.2f]", [playerPosition xPosition], [playerPosition yPosition], [playerPosition zPosition]]];
		
		// get list of squares
		NSArray *listSquares = [navigationController listSquaresInView:navMeshView aroundLocation: (MPLocation *)playerPosition];
		
		// update NavMeshView with list and mark for update
		[navMeshView setDisplayedSquares:listSquares];
		[navMeshView setNeedsDisplay: YES];
		
		// show number of squares and points
		[labelNumSquares setStringValue: [NSString stringWithFormat:@"%d", [[navigationController allSquares] count]]];
//		[labelNumPoints setStringValue: [NSString stringWithFormat:@"%d", [[navigationController allPoints] count]]];
		[labelNumPoints setStringValue: [NSString stringWithFormat:@"%d", [playerData zone]]];
		
		MPSquare *currentSquare = [navigationController lowestSquareContainingLocation:(MPLocation *)playerPosition];
		if (currentSquare != nil) {
			[labelSquareDescription setStringValue:[currentSquare navViewDescription]];
		} else {
			[labelSquareDescription setStringValue:[NSString stringWithString:@" [none]"]];
		}
		
		int zDepth = [navigationController squareCountAtLocation:(MPLocation *)playerPosition];
		[labelSquareDepthAtLocation setStringValue:[NSString stringWithFormat:@"%d", zDepth]];
		
		
		listSquares = nil;
		
		// to encourage the autorelease pool to empty (and not consume all our resources)
		// we flush it every so often.
/*		if ([flushTimer ready]) {
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];
			[flushTimer start];
		}
*/ 
		
		//PGLog(@"updateNavMeshThread: sleeping");
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.18]];
		
	}
	
	//PGLog(@"updateNavMeshThread: closing thread ...");
	[pool drain];
	isThreadStartedNavMeshView = NO;
}



- (void) updateNavMeshAdjustment {
	
	PGLog(@"Starting updateNavMeshAdjustment Thread ...");
	isThreadStartedNavMeshAdjustments = YES;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while ([enableGraphAdjustments state] ) {
	
//		PGLog (@"updatingNavMeshAdjustment ... allSquares[%d]  currentPos:%@", [[navigationController allSquares] count], [playerData position]);
		
		// get which Radio Button is selected and call the proper method here:
		NSInteger tag = [updateModeOptions selectedTag];
		
		Position *playerPosition = (Position *)[self myCurrentLocation]; 
		
		float playerX, playerY, playerZ;
		float indxX, indxY;
		int valueArea = [areaValue floatValue];
		
		float currentX, currentY, currentZ;
		
		playerX = [playerPosition xPosition];
		playerY = [playerPosition yPosition];
		playerZ = [playerPosition zPosition];
		
		
//		MPLocation *testLocation;
		switch (tag) {
			case 0:
			
				
				for (indxX = -valueArea; indxX <= valueArea; indxX ++) {
				
					// for indxY = -areaValue, indxY <= areaValue, indxY ++
					for (indxY = -valueArea; indxY <= valueArea; indxY ++) {
					
						// testPosition = playerPosX + indxX, playerPosY + indxY, playerPosZ
						currentX = (playerX + (indxX*[navigationController squareWidth]) );
						currentY = (playerY + (indxY*[navigationController squareWidth]) );
						currentZ = playerZ;
						MPLocation *updateLocation = [MPLocation locationAtX: currentX Y:currentY Z:currentZ];
						
						[navigationController updateMeshAtLocation: updateLocation isTraversible:YES];
					}
				}
				
				//[navigationController updateMeshAtLocation: (MPLocation*)[playerData position] isTraversible:YES];
				break;
			case 1:
				[navigationController updateMeshAtLocation: (MPLocation*)[playerData position] isTraversible:NO];
				break;
			case 2:
				// do cost adjustment here ...
				break;
				
			case 3:
				// delete dual squares in Area
				
				for (indxX = -valueArea; indxX <= valueArea; indxX ++) {
					
					// for indxY = -areaValue, indxY <= areaValue, indxY ++
					for (indxY = -valueArea; indxY <= valueArea; indxY ++) {
						
						// testPosition = playerPosX + indxX, playerPosY + indxY, playerPosZ
						currentX = (playerX + (indxX*[navigationController squareWidth]) );
						currentY = (playerY + (indxY*[navigationController squareWidth]) );
						currentZ = playerZ;
						MPLocation *updateLocation = [MPLocation locationAtX: currentX Y:currentY Z:currentZ];
						
						// if location has > 1 squares there 
						if ([navigationController squareCountAtLocation:updateLocation] > 1) {
							
							MPSquare *square = [navigationController smallestSquareContainingLocation:updateLocation];
							
							if (square) {
								
								[navigationController removeSquare:square];
							}
						}
					}
				}
				break;
				
			case 4:
				
				// Nudge squares in Area
				
				for (indxX = -valueArea; indxX <= valueArea; indxX ++) {
					
					// for indxY = -areaValue, indxY <= areaValue, indxY ++
					for (indxY = -valueArea; indxY <= valueArea; indxY ++) {
						
						// testPosition = playerPosX + indxX, playerPosY + indxY, playerPosZ
						currentX = (playerX + (indxX*[navigationController squareWidth]) );
						currentY = (playerY + (indxY*[navigationController squareWidth]) );
						currentZ = playerZ;
						MPLocation *updateLocation = [MPLocation locationAtX: currentX Y:currentY Z:currentZ];
						
						[navigationController nudgeConnectionsAtLocation:updateLocation];
						
					}
				}

				break;
				
				
			default:
				break;
		}
		
				
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.075]];
		
	}
	
	PGLog(@"Closing updateNavMeshAdjustment Thread ...");
	[pool release];
	isThreadStartedNavMeshAdjustments = NO;
}


- (void) updateNavMeshAdjustmentByParty {
	
//	PGLog(@"Starting updateNavMeshAdjustment Thread ...");
//	isThreadStartedNavMeshAdjustments = YES;
	
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	return;
	
	// Start with making sure Player's current position is traversible.
	MPLocation *playerPosition = (MPLocation *)[playerData position];
	[navigationController updateMeshAtLocation: playerPosition isTraversible:YES];

	NSArray *listParty = [[PlayerDataController sharedController] partyMembers];
	for( Player *member in listParty) {
		
		MPLocation *position = (MPLocation *)[member position];
		[navigationController updateMeshAtLocation: position isTraversible:YES];
		
		MPLocation *adjacentLocation = [MPLocation locationAtX:[position xPosition]+1 Y:[position yPosition] Z:[position zPosition]];
		[navigationController updateMeshAtLocation: adjacentLocation isTraversible:YES];
		
		adjacentLocation = [MPLocation locationAtX:[position xPosition] Y:[position yPosition]+1 Z:[position zPosition]];
		[navigationController updateMeshAtLocation: adjacentLocation isTraversible:YES];
	}
	
//	PGLog(@"Closing updateNavMeshAdjustment Thread ...");
//	[pool release];
//	isThreadStartedNavMeshAdjustments = NO;
}


#pragma mark -
#pragma mark Mover Action



- (void) doMoverAction {
	
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while (true ) {
//PGLog(@"  +++ ");
		if (doMoverAction) {
//PGLog(@"  ++++ mover.action() called!");
			[combatMover action];
		}

		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
		
	}
	
	[pool release];
}



#pragma mark -
#pragma mark TaskFileGenerator




- (NSString *) defendTaskData {
	return @"\tDefend { $Prio=1; } // <-- Attacks back anything attacking you. \n";
}

- (NSString *) lootTaskData {
	// To Do: read Skinning Value from Controller and adjust here:
	//	return @"\tLoot {\n\t\t$Prio=2;\n\t\t$Distance=30;\n\t\t$Skin=No;\n\t}\n";
	NSMutableString *lootData = [NSMutableString stringWithString:@"\tLoot {\n\t\t$Prio=2;\n"];
	
	
	[lootData appendString:@"\t\t$Distance=30;\n"];
	
	if ([botController doSkinning]) {
		[lootData appendString:@"\t\t$Skin=Yes; // <-- skin mobs \n"];
	} 
	
	[lootData appendString:@"\t}\n"];
	
	return lootData;
}

- (NSString *) restTaskData {
	int maxHealth = 0;
	int maxMana = 0;
	int currHealthValue = 0;
	int currManaValue = 0;
	Procedure *regenProcedure = [botController procedureRegen]; //[[botController behaviorPopup] procedureForKey:RegenProcedure];
	
	int numRules = [regenProcedure ruleCount];
	
	int indx;
	for (indx=0; indx< numRules; indx++){
		
		Rule *currentRule = [regenProcedure ruleAtIndex:indx];
		
		for (Condition *currentCondition in [currentRule conditions]) {
			
			if ([currentCondition enabled]) {
				
				if ([currentCondition unit] == UnitPlayer) {
					
					if ([currentCondition quality] ==  QualityHealth) {
						
						currHealthValue = [[currentCondition value] unsignedIntValue];
						if ([currentCondition type] == TypeValue) {
							// translate currHealthValue into a percent
							currHealthValue = ( (currHealthValue * 100 )/ [playerData maxHealth] );
						}
						
						if (maxHealth < currHealthValue) {
							maxHealth = currHealthValue;
						}
					}
					if ([currentCondition quality] == QualityMana) {
						
						currManaValue = [[currentCondition value] unsignedIntValue];
						if ([currentCondition type] == TypeValue) {
							// translate currHealthValue into a percent
							currManaValue = ( (currManaValue * 100 )/ [playerData maxMana] );
						}
						
						if (maxMana < currManaValue) {
							maxMana = currManaValue;
						}
					}
					
				}
			}
		}
	}
	
	NSMutableString *restData = [NSMutableString stringWithString:@"\tRest {\n\t\t$Prio=2;\n"];
	if (maxHealth > 0) {
		[restData appendFormat:@"\t\t$MinHealth = %d; // %%\n", maxHealth];
	}
	if (maxMana > 0) {
		[restData appendFormat:@"\t\t$MinMana  = %d; // %%\n", maxMana];
	}
	if ((maxHealth == 0) && (maxMana == 0)) {
		[restData appendString:@"\t\t// Hmmm I couldn't find existing Health/Mana settings.\n\t\t// uncomment the following lines if you need them:\n\t\t//$MinHealth = 25;// %\n\t\t//$MinMana = 25; //%\n"];
	}
	[restData appendString:@"\t}\n"];
	return restData;
}

- (NSString *) pullTaskData {
	NSMutableString *pullData = [NSMutableString stringWithString:@"\tPull {\n\t\t$Prio=3;\n"];
	
	
	[pullData appendString:@"//        $Names = [\"Plainstrider\",\"Mountain Cougar\"];  // <-- list any specific mobs to attack (leaving blank will attack all)\n"];
	[pullData appendString:@"//        $Ignore = [\"this_mob\"]; // <-- list any mobs to ignore \n"];
	[pullData appendString:@"//        $Factions = [7, 49, 256];\n"];
	[pullData appendString:@"\t\t$MinLevel = $MyLevel-3;\n"];
	[pullData appendString:@"\t\t$MaxLevel = $MyLevel+1;\n"];
	[pullData appendString:@"\t\t$Distance = 40;\n"];
	[pullData appendString:@"//        // The following parameters are rarely used:\n"];
	[pullData appendString:@"//        $SkipMobsWithAdds = true;\n"];
	[pullData appendString:@"//        $AddsDistance = 15;\n"];
	[pullData appendString:@"//        $AddsCount = 3;\n"];
	[pullData appendString:@"\t}\n"];
	
	return pullData;
}


- (NSString *) routeTaskData {
	NSMutableString *routeData = [NSMutableString stringWithString:@"\tRoute {\n\t\t$Prio=5;\n"];
	
	NSMutableString *listDescription = [NSMutableString stringWithString:@"\t\t$Locations = [\n"];	
	
	Route *currentRoute = [[[self waypointController] currentRouteSet] routeForKey:PrimaryRoute];
	NSInteger numWaypoints = [currentRoute waypointCount];
	int indx;
	for (indx =0; indx< numWaypoints; indx++) {
		Position *currentPosition = [[currentRoute waypointAtIndex:indx] position];
		if (currentPosition != nil) {
			
			if (indx != 0 ) [listDescription appendString:@",\n"];
			[listDescription appendFormat:@"\t\t\t[ %0.3f, %0.3f, %0.3f]", [currentPosition xPosition], [currentPosition yPosition], [currentPosition zPosition]];
		}
		
	}
	
	[listDescription appendString:@"\n\t\t\t];\n"];
	
	[routeData appendString:listDescription];
	
	[routeData appendString:@"\t\t$Repeat = Yes;\n\t\t$Order = Order;\n\t}\n" ];
	
	return routeData;
}




- (NSString *) ghostRouteTaskData {
	NSMutableString *routeData = [NSMutableString stringWithString:@"\tGhostRoute {\n\t\t$Prio=1;\n"];
	
	NSMutableString *listDescription = [NSMutableString stringWithString:@"\t\t$Locations = [\n"];	
	
	[listDescription appendString:@"\t\t\t// CorpseRunRoute Waypoints:\n"];
	
	Route *currentRoute = [[[self waypointController] currentRouteSet] routeForKey:CorpseRunRoute];
	NSInteger numWaypoints = [currentRoute waypointCount];
	int indx;
	for (indx =0; indx< numWaypoints; indx++) {
		Position *currentPosition = [[currentRoute waypointAtIndex:indx] position];
		if (currentPosition != nil) {
			
			if (indx != 0 ) [listDescription appendString:@",\n"];
			[listDescription appendFormat:@"\t\t\t[ %0.3f, %0.3f, %0.3f]", [currentPosition xPosition], [currentPosition yPosition], [currentPosition zPosition]];
		}
		
	}
	
	
	[listDescription appendString:@",\n\n\t\t\t// PrimaryRoute Waypoints:"];
	
	currentRoute = [[[self waypointController] currentRouteSet] routeForKey:PrimaryRoute];
	numWaypoints = [currentRoute waypointCount];
	for (indx =0; indx< numWaypoints; indx++) {
		Position *currentPosition = [[currentRoute waypointAtIndex:indx] position];
		if (currentPosition != nil) {
			[listDescription appendString:@",\n"];
			[listDescription appendFormat:@"\t\t\t[ %0.3f, %0.3f, %0.3f]", [currentPosition xPosition], [currentPosition yPosition], [currentPosition zPosition]];
		}
		
	}
	
	
	[listDescription appendString:@"\n\t\t\t];\n"];
	
	[routeData appendString:listDescription];
	
	[routeData appendString:@"\t}\n" ];
	
	return routeData;
}



#pragma mark -
#pragma mark TaskController Related



- (void) checkPatherStopConditions {
	[timerWorkTime start];
	
	PGLog(@" checkPatherStopConditions ");
	

		
		// if runningState != Stopped  then check for all our special stop conditions
		if ([taskController currentRunningState] != RunningStateStopped) {
			
			// if we have a special (code Initiated Stop Condition)
				// log 
			// end if
			
			// if !inCombat
			if (![taskController inCombat] ) {
			
				// switch (runningState)
				switch ([taskController currentRunningState]) {
					case RunningStatePaused:
						[self pausedCheck];
						break;
					case RunningStateRunning:
						[self runningCheck];
						break;
					case RunningStateStopped:
						break;
				}
				
			} // end if
			
		} // end if
		
		// Handle State Changes
		if ([taskController currentRunningState] != [taskController wantedRunningState]) {
			[self processStateChange];
		}
	
	// now record our current work time.
	[performanceController storeWorkTime:[timerWorkTime elapsedTime]];
}


- (void) runningCheck {
	PGLog(@"  runningCheck ... ");
	// check Deaths
	// check Followers
	// check timer Expired
	// check level
	// Save State
	
	
	//// check for zoneChange
	UInt32 currentZone = [playerData zone];
	
	// if zoneChange then
	if( currentZone != [navigationController zone] ) {
		
		// Maps are continuous even though you switch from one zone to another.
		// Just update the navController with the current zone
		[navigationController setZone:currentZone];

	} // end if
}



- (void) pausedCheck {
	// if Creating Graphs
	if ([enableGraphAdjustments state]) {
		
		if (!isThreadStartedNavMeshAdjustments) {
			// make sure our thread for updating our NavMesh is running
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshAdjustment) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshAdjustment) withObject:nil];
			
		}
	}// end if
}


- (void) processStateChange {
PGLog( @"   >>>> Process State Change <<<<<");
	switch ([taskController wantedRunningState]) {
		case RunningStateStopped:
PGLog( @"        ---> RunningStateStopped");			
			//// nicely close off our timers
			[taskController processCurrentActivity];  // makes sure activity.stop()
			[timerProcessCurrentActivity invalidate];
			self.timerProcessCurrentActivity = nil;
			
			[taskController evaluateTasks];
			[timerEvaluateTasks invalidate];
			self.timerEvaluateTasks = nil;
			
			[timerCheckPatherStopConditions invalidate];
			self.timerCheckPatherStopConditions = nil;
			
			[timerUpdateUI invalidate];
			self.timerUpdateUI = nil;
			
			[timerPerformanceCycle invalidate];
			self.timerPerformanceCycle = nil;
			
//			[timerMPMover invalidate];
//			self.timerMPMover = nil;
			doMoverAction = NO;
			
			[timerGraphBuilder invalidate];
			self.timerGraphBuilder = nil;
			
			[timerGraphOptimizations invalidate];
			self.timerGraphOptimizations = nil;
			
			//// release any UI resources: cursor hooks?  keyboard hooks?
			
			
			// runningState = stopped
			[taskController setCurrentRunningState:RunningStateStopped];
			
			// make sure PG combat controller stops as well 
//			[combatController setCombatEnabled:NO];  // TO DO: Do we need this anymore?
			[combatController cancelAllCombat]; 
			
			// finally enable our button
			[startBotButton setEnabled:YES];
			[pauseBotButton setEnabled:NO];
			
			// return Bot Controller to Normal State:
			[botController setPatherEnabled:NO];
			[botController setPatherCCEnabled:NO];
			[combatController setPatherCCEnabled:NO];
			[botController stopBot:nil];
			
			break;
			
		case RunningStatePaused:
PGLog( @"        ---> RunningStatePaused");
			//// close off Task timers
			// call processCurrentActivity
			[taskController processCurrentActivity];  // causes currentActivity to .stop() 
			
			// stop processCurrentActivityTimer
			[timerProcessCurrentActivity invalidate];
			self.timerProcessCurrentActivity = nil;
			
			// stop evaluateTasksTimer
			[timerEvaluateTasks invalidate];
			self.timerEvaluateTasks = nil;
			
//			[timerMPMover invalidate];
//			self.timerMPMover = nil;
			doMoverAction = NO;

			//// release any UI resources: cursor hooks?  keyboard hooks?
			
			
			//// decide if we should start Graphing system
			// if graphBuilding enabled
				// start processGraphBuildingTimer
			// end if
			
			// runningState = Paused
			[taskController setCurrentRunningState:RunningStatePaused];
			break;
			
		case RunningStateRunning:
PGLog( @"        ---> RunningStateRunning");
			//// call the Task Evaluation methods to get the system primed for action
			[taskController evaluateTasks];
			[taskController processCurrentActivity];
			
			
			//// make sure all timers are active
			// setup timers:  taskController->processCurrentActivity()  every 100 ms
			if (timerProcessCurrentActivity == nil)
				self.timerProcessCurrentActivity = [NSTimer scheduledTimerWithTimeInterval:0.1 target:taskController selector:@selector(processCurrentActivity) userInfo:nil repeats:YES];
			
			// setup timers:  taskController->evaluateTasks  every 750 ms
			if (timerEvaluateTasks == nil)
				self.timerEvaluateTasks = [NSTimer scheduledTimerWithTimeInterval:0.7 target:taskController selector:@selector(evaluateTasks) userInfo:nil repeats:YES];
			
			// setup timer:   PatherController->checkPatherStopConditions()  every 2 sec
			if (timerCheckPatherStopConditions == nil)
				self.timerCheckPatherStopConditions = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkPatherStopConditions) userInfo:nil repeats:YES];
			
			// setup timer:   PatherController->updateUI()  every 1.5s
			if (timerUpdateUI == nil)
				self.timerUpdateUI = [NSTimer scheduledTimerWithTimeInterval:1.25 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
			
			if (timerPerformanceCycle == nil)
				self.timerPerformanceCycle = [NSTimer scheduledTimerWithTimeInterval:0.1 target:performanceController selector:@selector(reset) userInfo:nil repeats:YES];
		
//			if (timerMPMover == nil)
//				self.timerMPMover = [NSTimer scheduledTimerWithTimeInterval:0.05 target:combatMover selector:@selector(action) userInfo:nil repeats:YES];
			doMoverAction = YES;
			
			// setup the NavMesh Builder (temp until MPQ reading is finished)
			// PatherController->updateNavMeshAdjustmentByParty()  every 100ms
			if (timerGraphBuilder == nil) 
				self.timerGraphBuilder = [NSTimer scheduledTimerWithTimeInterval:0.075 target:self selector:@selector(updateNavMeshAdjustmentByParty) userInfo:nil repeats:YES];
			
			
			// NavMesh Optimizer
			if (timerGraphOptimizations == nil) 
				self.timerGraphOptimizations = [NSTimer scheduledTimerWithTimeInterval:1.0 target:navigationController selector:@selector(optimizeGraph) userInfo:nil repeats:YES];

				// make sure the Paused timers are disabled:
				// disable processGraphBuildingTimer
			
			// grab any UI resources: cursor hooks? keyboard hooks?
			
			// runningState = Running
			[taskController setCurrentRunningState:RunningStateRunning];
			
			[startBotButton setEnabled: YES];
			[pauseBotButton setEnabled:YES];
			break;
			
		default:
			break;
	}
	
}

#pragma mark -
#pragma mark BlackLists


// used by lootTask/Activity to ignore looted mobs when inventory full or after a loot error
- (void)lootBlacklistUnit: (WoWObject*)unit{
	
	if ( [unitsLootBlacklisted containsObject:unit] ){
		PGLog(@"[Bot] ** Why is %@ blacklisted already?", unit);
	}
	else{
		[unitsLootBlacklisted addObject:unit];
	}
	
	float delay = 300.0f;
	PGLog(@"[PPather] lootBlacklisting unit [%@] for %0.2f seconds", unit, delay);
	[self performSelector:@selector(removeUnitFromLootBlacklist:) withObject:unit afterDelay:delay];
}


- (void)removeUnitFromLootBlacklist: (WoWObject*)unit{
	if ( [unitsLootBlacklisted containsObject:unit] ){
		[unitsLootBlacklisted removeObject:unit];
		PGLog(@"[PPather] Unit %@ removed from lootBlacklist", unit);
	}
}


- (BOOL) isLootBlacklisted: (WoWObject *) unit {
	
	return [unitsLootBlacklisted containsObject:unit];
}



// used by AttackActivity to ignore mobs when attacks report an error
- (void)blacklistUnit: (WoWObject*)unit{
	
	if ( [unitsBlacklisted containsObject:unit] ){
		PGLog(@" +++++ Why is %@ blacklisted already?", unit);
	}
	else{
		[unitsBlacklisted addObject:unit];
	}
	
	float delay = 300.0f;
	PGLog(@"[PPather] blacklisting unit [%@] for %0.2f seconds", unit, delay);
	[self performSelector:@selector(removeUnitFromBlacklist:) withObject:unit afterDelay:delay];
}


- (void)removeUnitFromBlacklist: (WoWObject*)unit{
	if ( [unitsBlacklisted containsObject:unit] ){
		[unitsBlacklisted removeObject:unit];
		PGLog(@"[PPather] Unit %@ removed from Blacklist", unit);
	}
}


- (BOOL) isBlacklisted: (WoWObject *) unit {
	
	return [unitsBlacklisted containsObject:unit];
}


#pragma mark -
#pragma mark KillCounts


- (void) addKillCountMob: (NSString *)mobName {
	
	if (![listKillCountNames containsObject:mobName]) {
		
		[listKillCountNames addObject:mobName];
		NSString *value = [toonData valueForKey:[self keyKillCount:mobName]];
		if (value == nil) {
			[toonData setValue:@"0" forKey:[self keyKillCount:mobName]];
		}
	}
}



- (void) resetKillCountMob: (NSString *) mobName {
	// set count = 0;
	
	if ([listKillCountNames containsObject:mobName]) {
		
		[toonData setValue:@"0" forKey:[self keyKillCount:mobName]];
	}
}



- (int) killCount: (NSString *)mobName{
	// returns the curren # kills.  0 if not counting mobName
	if ([listKillCountNames containsObject:mobName]) {
		
		NSString *value = [toonData valueForKey:[self keyKillCount:mobName]];
		if (value == nil) {
			return 0;
		}
		return [value intValue];
	}
	return 0;
}



- (void) addKill: (NSString *)mobName {
	// increase the kill count for mobName. (only if already counting)
	if ([listKillCountNames containsObject:mobName]) {
		
		int count = [self killCount:mobName];
		count ++;
		NSString *value = [NSString stringWithFormat:@"%d", count];
		[toonData setValue:value forKey:[self keyKillCount:mobName]];
	}
	
}
		 
		 
- (NSString *) keyKillCount: (NSString*) mobName {
	return [NSString stringWithFormat:@"killCount:%@", mobName];
}



#pragma mark -
#pragma mark Function Values



- (IBAction) testRoute: sender {
	
/*
	
	// create a few squares
	int indxX, indxY;
	float posX, posY;
	MPLocation *testLocation;
	for( indxX=0; indxX < 10; indxX++) {
		posX = 0.25 + (indxX * [navigationController squareWidth]);
		
		for( indxY=0; indxY < 10; indxY++ ) {
			
			posY = 0.25 + (indxY * [navigationController squareWidth]);
			
			testLocation = [MPLocation locationAtX:posX	Y:posY Z: 1.0];
			if ( ((indxX >=1) && (indxX <=3) && indxY == 4) || 
				 ((indxY <=4) && (indxX == 3)) || 
				 ((indxX == 5) && (indxY >=1))
				){
				[navigationController updateMeshAtLocation: testLocation isTraversible:NO];
			} else {
				[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
			}
			
			
			
		}
	}

	
	testLocation = [MPLocation locationAtX:posX	Y:posY Z: 1.0];
	[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
	
	
	testLocation = [MPLocation locationAtX:0.25 Y:0.25 Z: 1.0];
	MPLocation *destLocation = [MPLocation locationAtX:posX	Y:posY Z: 1.0];
	
	Route *someRoute = [navigationController routeFromLocation:testLocation toLocation:destLocation];


	PGLog( @" someRoute = %@", someRoute);
*/	
	
	
	Position *playerPosition = (Position *)[self myCurrentLocation];
	
	
	MPLocation *testLocation = (MPLocation *)playerPosition;
	MPLocation *destLocation = deleteMeRouteDest;
	
	Route *someRoute = [navigationController routeFromLocation:testLocation toLocation:destLocation];
	
	PGLog( @" someRoute = %@", someRoute);
	
	// v1.4.4f : movementControllers now want RouteSets:
	RouteSet *someRouteSet = [RouteSet routeSetWithName:@"Some Route"];
	[someRouteSet setRoute: someRoute forKey:PrimaryRoute];
//	[movementController setPatrolRouteSet:someRouteSet];

//	[movementController setPatrolRoute:someRoute];
//	[movementController beginPatrolAndStopAtLastPoint];
	
//	Route *someRoute = [navigationController routeFromLocation:(MPLocation *)[playerData position] toLocation:(MPLocation *)deleteMeRouteDest];

}


- (IBAction) testDestLocation: sender {
	
	Position *playerPosition= (Position *)[self myCurrentLocation];
	
	self.deleteMeRouteDest = (MPLocation *)playerPosition;
	
	NSString *posString = [NSString stringWithFormat:@"[ %0.2f, %0.2f, %0.2f ]", [playerPosition xPosition], [playerPosition yPosition], [playerPosition zPosition] ];
	[textboxDestLocation setStringValue: posString];
}


- (IBAction) testStuff: sender {

//	NSOpenPanel *panel = [NSOpenPanel openPanel];
//    if ([panel runModal] == NSOKButton)
//    {
/*        NSString *filename = [panel filename];

		MPTask *testTask = [MPTask rootTaskFromFile:filename];
		
		MPValue* maxLevel = [testTask integerFromVariable:@"MaxLevel" orReturnDefault:5];
		
		PGLog(@" maxLevel= (%d)", [maxLevel value]);
*/		
		
		/*		
		MPParser *t = [MPParser initWithFile:filename];
		NSString *tok = nil;
		
		while ((tok = [t nextToken]) != nil) {
			PGLog(@" (%@)  %@  %d", tok, [t fileName], [t lineNumber]);
		}
		*/	
		
//	}

//	[self updateNavMeshAdjustment:nil];
	
	
	
	// create a few squares
//	MPLocation *testLocation = [MPLocation locationAtX: 1.75 Y:1.34 Z: 1.0];
//	[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
	
//	testLocation = [MPLocation locationAtX: 1.25 Y:1.84 Z: 1.0];
//	[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
	
//	testLocation = [MPLocation locationAtX: 1.75 Y:1.84 Z: 1.0];
//	[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
	
//	testLocation = [MPLocation locationAtX: 0.75 Y:1.84 Z: 1.0];
//	[navigationController updateMeshAtLocation: testLocation isTraversible:YES];
	

	// if Creating Graphs
	if ([enableGraphAdjustments state]) {
		
		if (!isThreadStartedNavMeshAdjustments) {
			// make sure our thread for updating our NavMesh is running
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshAdjustment:) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshAdjustment) withObject:nil];
			
		}
	}// end if
	
	if ([navMeshLiveUpdating state] ) {
		
		if (!isThreadStartedNavMeshView) { // <-- make sure thread not already started
			
			// this button was just clicked to ON, so start a thread to update
			// the display:
			//[NSThread detachNewThreadSelector:@selector(updateNavMeshView) toTarget:self withObject:nil];
			[self performSelectorInBackground:@selector(updateNavMeshView) withObject:nil];
		}
	}
 

	
	
/* 
 //// Testing MPAVLTree operations:
	MPAVLTree *testIt = [MPAVLTree tree];
	
	NSString *testObject;
	
	int indx;
	for (indx = 1; indx <= 32; indx++) {
		
		if (indx == 6) {
			PGLog(@"on node 6");
		}
		testObject = [NSString stringWithFormat:@"Node%d", indx];
		[testIt addObject:testObject withValue:indx];
	
		[testIt dump];
	}
	
	PGLog( @"Removing node 31" );
	[testIt removeObjectWithValue: 31];
	[testIt dump];
*/
	
	
/*	
	//// Testing MPAVLRangedTree operations:
	MPAVLRangedTree *testTree = [MPAVLRangedTree tree];
	
	NSString *testObject;
	NSRange testRange;
	
	int indx;
	for (indx = 1; indx <= 32; indx++) {
		
		testObject = [NSString stringWithFormat:@"Node%d", indx];
		
		testRange = NSMakeRange(indx, 1);
		
		[testTree addObject:testObject forRange:testRange];
		
		[testTree dump];
	}
	
//	PGLog( @"Removing node 31" );
//	[testTree removeObjectWithValue: 31];
//	[testTree dump];
  
	testObject = [testTree objectForValue:5.5];
	PGLog(@" testObject for value 5 : %@ ", testObject);
*/
	
	
/*
	//// Testing MPPointTree
	MPPointTree *myPoints = [MPPointTree tree];
	MPPoint *testPoint;
	
	int xIndx, yIndx, zIndx;
	for (xIndx=1; xIndx <= 3; xIndx++) {
		
		for( yIndx=1; yIndx<=3; yIndx++) {
				
			for(zIndx=1; zIndx<= 2; zIndx++) {
				
				testPoint = [MPPoint pointAtX:xIndx Y:yIndx Z:zIndx*5];
				[myPoints addPoint:testPoint];
			}
		}
	}
	
	
	testPoint = [myPoints pointAtX:2 Y:3 Z:5];
	PGLog( @" [2, 3, 5] = %@ ", [testPoint describe] );
	
	PGLog( @" removing [2, 3, 5] ");
	[myPoints removePointAtX:2 Y:3 Z:5];
	
	testPoint = [myPoints pointAtX:2 Y:3 Z:5];
	PGLog( @" [2, 3, 5] = %@ ", [testPoint describe] );
*/
/*	
	//// Testing MPSquareTree
	MPSquareTree * mySquares = [MPSquareTree treeWithSquareWidth:1 ZTolerance:2.8];
	
	MPSquare *testSquare;
	
	MPPoint *point0, *point1, *point2, *point3;
	NSMutableArray *points = [NSMutableArray array];
	NSArray *copyPoints;
	point0 = [MPPoint pointAtX:0 Y:0 Z:3]; 
	point1 = [MPPoint pointAtX:0 Y:-1 Z:3];
	point2 = [MPPoint pointAtX:1 Y:-1 Z:3];
	point3 = [MPPoint pointAtX:1 Y:0 Z:3];
	[points addObject:point0];
	[points addObject:point1];
	[points addObject:point2];
	[points addObject:point3];
	copyPoints = [points copy];
	testSquare = [MPSquare squareWithPoints:copyPoints];
	
	[mySquares addSquare:testSquare];
	[points removeAllObjects];
	
	point0 = [MPPoint pointAtX:0 Y:2 Z:3.1]; 
	point1 = [MPPoint pointAtX:0 Y:0 Z:3.1];
	point2 = [MPPoint pointAtX:2 Y:0 Z:3.1];
	point3 = [MPPoint pointAtX:2 Y:2 Z:3.1];
	[points addObject:point0];
	[points addObject:point1];
	[points addObject:point2];
	[points addObject:point3];
	copyPoints = [points copy];
	testSquare = [MPSquare squareWithPoints:copyPoints];
	
	[mySquares addSquare:testSquare];
	[points removeAllObjects];
	
	point0 = [MPPoint pointAtX:2 Y:1 Z:3.2]; 
	point1 = [MPPoint pointAtX:2 Y:0 Z:3.2];
	point2 = [MPPoint pointAtX:3 Y:0 Z:3.2];
	point3 = [MPPoint pointAtX:3 Y:1 Z:3.2];
	[points addObject:point0];
	[points addObject:point1];
	[points addObject:point2];
	[points addObject:point3];
	copyPoints = [points copy];
	testSquare = [MPSquare squareWithPoints:copyPoints];
	
	[mySquares addSquare:testSquare];
	[points removeAllObjects];
 
 
	testSquare = [mySquares squareAtX:1 Y:1 Z:4];
	PGLog( @" square 1: %@", [testSquare describe]);
	
	testSquare = [mySquares squareAtX:0.5 Y:-0.5 Z:4];
	PGLog( @" square 2: %@", [testSquare describe]);
	
	[mySquares removeSquareAtX:1 Y:1 Z:4];
	testSquare = [mySquares squareAtX:1 Y:1 Z:4];
	PGLog( @" square after Delete: %@", [testSquare describe]);
 */
	
}
@end
