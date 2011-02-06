//
//  MPToonData.h
//  Pocket Gnome
//
//  Created by Coding Monkey on 1/23/11.
//  Copyright 2011 Savory Software, LLC
//
#import <Cocoa/Cocoa.h>

@class PLSqliteDatabase;

@interface MPToonData : NSObject {

	NSString *toonName;
	NSMutableDictionary *toonData;
	PLSqliteDatabase *db;
}
@property (readwrite, retain) NSString *toonName;
@property (retain) NSMutableDictionary *toonData;


- (void) openToonData: (NSString *) folderPatherData;
- (void) loadToonData;
- (void) loadDataWithCondition: (NSString *)condition;  // after testing move to internal declaration

- (void) setValue:(NSString *)value forKey:(NSString *)key;
- (NSString *) valueForKey:(NSString *)key;

@end
