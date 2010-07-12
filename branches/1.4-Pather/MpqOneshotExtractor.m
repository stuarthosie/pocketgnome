//
//  MpqOneshotExtractor.m
//  Pocket Gnome
//
//  Created by William LaFrance on 7/11/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "MpqOneshotExtractor.h"


@implementation MpqOneshotExtractor

+ (BOOL) extractFile:(NSString *)filename fromMpqList:(NSArray *)mpqList toFile:(NSString *)newPath {
	/*PGLog(@"Attempting to extract file @\"%@\" to @\"%@\" from these MPQ files:\n%@",
		filename, newPath, mpqList);*/
	
	int i;
	for (i = 0; i < [mpqList count]; i++) {
		NSString *mpqFilename = [mpqList objectAtIndex:i];
		//PGLog(@"Attempting file number %i: %@", i, mpqFilename);
		
		mpq_archive_s *archive = nil;
		
		if (libmpq__archive_open(&archive, [mpqFilename cStringUsingEncoding:NSASCIIStringEncoding], -1) == 0) {
			//PGLog(@"Successfully opened archive.");
			
			uint32_t listfile_number;
			const char *listfile = "(listfile)";

			if (libmpq__file_number(archive, listfile, &listfile_number) == 0) {
				//PGLog(@"Got listfile number: #%i. Let's read it.", listfile_number);
				
				NSMutableArray *filesInMpq = [NSMutableArray arrayWithCapacity:64];
				
				off_t listfile_size;
				char *listfile;
				if (libmpq__file_unpacked_size(archive, listfile_number, &listfile_size) == 0) {
					listfile = malloc(listfile_size);
					
					if (libmpq__file_read(archive, listfile_number, (uint8_t *)listfile, listfile_size, nil) == 0) {
					
						char *nextFileName = strtok(listfile, "\r\n");
						while (nextFileName) {
							[filesInMpq addObject:[NSString stringWithCString:nextFileName encoding:NSASCIIStringEncoding]];
							nextFileName = strtok(NULL, "\r\n");
						}
						
						free(listfile);
						
						if ([filesInMpq containsObject:filename]) {
							PGLog(@"Found file. \"%@\" is in \"%@\"", filename, mpqFilename);
							return [self extractFile:filename fromArchive:mpqFilename toFile:newPath];
						} else {
							//PGLog(@"Didn't find file. Moving on.");
						}
					
					} else {	// libmpq__file_read
						PGLog(@"Failed to read listfile.");
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

+ (BOOL) extractFile:(NSString *)filename fromArchive:(NSString *)mpqFile toFile:(NSString *)newPath {
	PGLog(@"Extracting \"%@\" to \"%@\".", filename, newPath);

	mpq_archive_s *archive = nil;
	if (libmpq__archive_open(&archive, [mpqFile cStringUsingEncoding:NSASCIIStringEncoding], -1) == 0) {
		//PGLog(@"Opened archive.");
		
		uint32_t filenumber;
		if (libmpq__file_number(archive, [filename cStringUsingEncoding:NSASCIIStringEncoding], &filenumber) == 0) {
			//PGLog(@"Got file number.");
			
			off_t filesize;
			if (libmpq__file_unpacked_size(archive, filenumber, &filesize) == 0) {
				//PGLog(@"Got unpacked size.");
			
				#warning i sure hope someone doesn't try extracting a file above 512MB or so
				char *file = malloc(filesize);
				if (file) {
					//PGLog(@"Malloc'd successfully.");
					
					if (libmpq__file_read(archive, filenumber, (uint8_t *)file, filesize, nil) == 0) {
						//PGLog(@"Read file into malloc'd memory.");
					
						FILE *filehandle = fopen([newPath cStringUsingEncoding:NSASCIIStringEncoding], "w");
						if (filehandle) {
							//PGLog(@"Got file handle.");
						
							#warning add path creation
							fwrite(file, 1, filesize, filehandle);
							fclose(filehandle);
						
						} else { // file handle test
							PGLog(@"Couldn't get file handle.");
						} 
						
					} // libmpq__file_read
				
					free(file);
				} // malloc test
				
			
			}	// libmpq__file_unpacked_size
		
		} // libmpq__file_number
		
		if (libmpq__archive_close(archive) == 0) {
			// closed the archive
		}	// libmpq__archive_close
	
	} // libmpq__archive_open

	return NO;
}

@end
