/*
 *  PPather.h
 *  Pocket Gnome
 *
 *  Created by wjlafrance@gmail.com on 7/9/10.
 *  Copyright 2010 Savory Software, LLC. All rights reserved.
 *
 *  This header has all necessary includes for my Objective-C port of PPather
 *  for use with PocketGnome.
 */
 
// ---- PPATHER COCOA ADDITIONS ----

#ifndef Cocoa_Addition_NSData_ByteAtIndex_h
	#import "NSData+ByteAtIndex.h"
	#define Cocoa_Addition_NSData_ByteAtIndex_h
#endif

#ifndef Cocoa_Addition_NSString_StringWithPadding_h
	#import "NSString+StringWithPadding.h"
	#define Cocoa_Addition_NSString_StringWithPadding_h
#endif

// ---- PPATHER HEADERS ----

#ifndef Pather_MpqTriangleSupplier_h
	#import "MpqTriangleSupplier.h"
	#define Pather_MpqTriangleSupplier_h
#endif

#ifndef Pather_DBC_h
	#import "DBC.h"
	#define Pather_DBC_h
#endif

#ifndef Pather_MpqOneshotExtractor_h
	#import "MpqOneshotExtractor.h"
	#define Pather_MpqOneshotExtractor_h
#endif

#ifndef Pather_WDT_h
	#import "WDT.h"
	#define Pather_WDT_h
#endif

// ---- PPATHER C FUNCTIONS ----
#ifndef Pather_h
#define Pather_h

uint fgetui32(FILE *fh);
NSData *fgetdata(FILE *fh, int length);
NSString *fgetstr(FILE *fh, int length);

#endif
