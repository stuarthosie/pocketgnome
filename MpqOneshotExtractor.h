//
//  MpqOneshotExtractor.h
//  Pocket Gnome
//
//  Created by William LaFrance on 7/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PPather.h"
#import "mpq.h"

@interface MpqOneshotExtractor : NSObject {

}

+ (BOOL) extractFile:(NSString *)filename fromMpqList:(NSArray *)mpqList toFile:(NSString *)newPath;

@end
