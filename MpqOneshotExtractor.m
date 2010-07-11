//
//  MpqOneshotExtractor.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MpqOneshotExtractor.h"


@implementation MpqOneshotExtractor


#warning actual extraction is not complete, just reading the listfile
+ (BOOL) extractFile:(NSString *)filename fromMpqList:(NSArray *)mpqList toFile:(NSString *)newPath {
	PGLog(@"Attempting to extract file @\"%@\" to @\"%@\" from these MPQ files:\n%@",
		filename, newPath, mpqList);
	
	int i;
	for (i = 0; i < [mpqList count]; i++) {
		NSString *mpqFilename = [mpqList objectAtIndex:i];
		PGLog(@"Attempting file number %i: %@", i, mpqFilename);
		
		mpq_archive_s *archive = nil;
		
		if (libmpq__archive_open(&archive, [mpqFilename cStringUsingEncoding:NSASCIIStringEncoding], -1) == 0) {
			PGLog(@"Successfully opened archive. Reading listfile.");
			
			uint32_t listfile_number;
			const char *listfile = "(listfile)";
			PGLog(@"Trying to get number for %s", listfile);

			if (libmpq__file_number(archive, listfile, &listfile_number) == 0) {
				PGLog(@"Got listfile number.");
				PGLog(@"Listfile is #%i. Let's read it.", listfile_number);
				
				NSMutableArray *filesInMpq = [NSMutableArray arrayWithCapacity:64];
				
				off_t listfile_size;
				char *listfile;
				if (libmpq__file_unpacked_size(archive, listfile_number, &listfile_size) == 0) {
					listfile = malloc(listfile_size);
					libmpq__file_read(archive, listfile_number, listfile, listfile_size, nil);
					
					char *filename = strtok(listfile, "\r\n");
					while (filename) {
						[filesInMpq addObject:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding]];
						filename = strtok(NULL, "\r\n");
					}
					
					free(listfile);
					
					PGLog(@"Found these files: %@", filesInMpq);
					
					if ([filesInMpq containsObject:filename]) {
						PGLog(@"Uber important news guys: we found our file.");
						
						#warning do extrating here
						return YES;
					} else {
						// move along
					}
					
				} else { // libmpq__file_unpacked_size
					PGLog(@"Got file number but can't get unpacked size. Wtf?");
				}
			
			} else { // libmpq__file_number
				PGLog(@"Archive has no list file, wtf?");
			}
			
			// close the archive, i really don't care if this doesn't work
			libmpq__archive_close(archive);
			
			
		} else { // libmpq__archive_open
			PGLog(@"Failed to open archive. Moving on.");
		}
		
	} // close for loop
	
	return NO;

}

@end
