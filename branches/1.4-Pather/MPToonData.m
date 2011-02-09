//
//  MPToonData.m
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import "MPToonData.h"

#import "PlausibleDatabase/PlausibleDatabase.h"
#import "PlayerDataController.h"



@interface MPToonData (internal)

- (void) verifyToonName;

@end



@implementation MPToonData
@synthesize toonName, toonData;

-(id) init {
	
	if ((self = [super init])) {
		
		self.toonName = nil;
		self.toonData = [NSMutableDictionary dictionary];
		db = nil;
		
		
		// make sure our DB is closed upon application exit
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(applicationWillTerminate:) 
                                                     name: NSApplicationWillTerminateNotification 
                                                   object: nil];
		
	}
	return self;
}



- (void) dealloc
{
	[toonName release];
	[toonData release];
	[db release];
	
	[super dealloc];
}




#pragma mark -
#pragma mark DB Routines


- (void) openToonData: (NSString *) folderPatherData {
	
	
	NSString* pathToonDir = [folderPatherData stringByAppendingFormat:@"/toondata"];
	
	
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	BOOL isDir;
	
	
    if (!([fileManager fileExistsAtPath:pathToonDir isDirectory:&isDir] && isDir)) {
		
		// create the mesh directory:
		[fileManager createDirectoryAtPath:pathToonDir withIntermediateDirectories:NO attributes:nil error:NULL ];
		
		
	}
	
	
	NSString* path = [pathToonDir stringByAppendingFormat:@"/toon.db"];
	db = [[PLSqliteDatabase alloc] initWithPath: path];
	
	if (![db open]) {
		PGLog(@" ---- Could not open database [%@]",path);
	}
	
	
	// now verify our navigation tables are there.
	if (![db tableExists:@"toondata"]) {
		
		// not there so make them:
		NSString * sqlCreateTable = [NSString stringWithString:@"CREATE TABLE toondata ( id INTEGER PRIMARY KEY, name TEXT, key TEXT, value TEXT);"];
		if (![db executeUpdate: sqlCreateTable]) {
			PGLog(@" ---- Error!  Can't create table 'toondata'!");
		}
		
	}
	
	
	[fileManager release];
	
}



- (void) loadToonData {
	
	NSString *condition = [NSString stringWithFormat:@"name=\"%@\"", toonName];
	[self loadDataWithCondition:condition];
}



- (void) loadDataWithCondition: (NSString *)condition  {
	
	NSString *sql = [NSString stringWithFormat:@"SELECT * FROM toondata WHERE %@", condition];
	
	PGLog(@"---- loading data with sql[%@] ---", sql);
	NSError *error=nil;
	
	id<PLResultSet> results = [db executeQueryAndReturnError:&error statement:sql];
	if (results == nil) {
		PGLog(@"    ---- error executing sql statement: e[%@]", error);
		[NSApp presentError:error];
		
	}else {
		
		NSString *key, *value;
		while ([results next]) {
			
			key =  [results stringForColumn:@"key"];
			value = [results stringForColumn:@"value"];
			
			[toonData setObject:value forKey:key];
			
			//PGLog(@"   ---- LOADING square [%@] created", square.name);
		}
		
		
		
		[results close];
		
	}
	
}




- (void) setValue:(NSString *)value forKey:(NSString *)key {
	
	//// make sure toonName is valid name:
	[self verifyToonName];
	
	
	NSString *currentValue = [toonData objectForKey:key];
	BOOL isNew = NO;
	
	// if current value is nil  then isNew == true
	if (currentValue == nil) isNew = YES;
	
	[toonData setObject:value forKey:key];
	
	NSString *sql;
	// if isNew sql = insert data
	if (isNew) {
		sql = [NSString stringWithFormat:@"INSERT INTO toondata (id, name, key, value) VALUES (null, \"%@\", \"%@\", \"%@\")", toonName, key, value];
	} else {
	// else sql = update data
		sql = [NSString stringWithFormat:@"UPDATE toondata SET value=\"%@\" WHERE name=\"%@\" AND key=\"%@\"", value, toonName, key];
	}
	
PGLog(@" ++++ sql[%@]", sql);
	NSError *error = nil;
	BOOL result = YES;
	// run SQL
//   [dbLock lock];
   result = [db executeUpdateAndReturnError:(&error) statement:sql];
//   [dbLock unlock];
	
	if (!result ){
		PGLog(@"   ++++-!!! Data insert failed. error[%@]", error );
		if (error) {
			[NSApp presentError:error];	
		}
		
	}
}



- (NSString *) valueForKey:(NSString *)key {
	
	[self verifyToonName];
	
	return [toonData objectForKey:key];
}


- (void) verifyToonName {
	
	// if we don't have a valid name, try to load it from the PlayerDataController ...
	if ([toonName isEqualToString:@""] || toonName == nil) {
		self.toonName = [[PlayerDataController sharedController] playerName];
		
		
		// load the data for this toon now:
		[self loadToonData];
	}
}


- (void)applicationWillTerminate: (NSNotification*)notification {
//	[dbLock lock];
	[db close];
//	[dbLock unlock];
}

@end
