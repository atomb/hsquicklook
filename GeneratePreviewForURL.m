#include <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

NSString *FindHsColour()
{
    NSArray *searchDirs;
    NSString *homeDir;
    NSFileManager *fm;
    
    fm = [NSFileManager defaultManager];
    
    // 1. If configuration variable is set, use it. XXX: implement this last.
    // 2. If it's in any one of a predefined list of paths, use it. (Search in order)
    homeDir = NSHomeDirectory();
    searchDirs = [NSArray arrayWithObjects:
                  @"/usr/local/bin/",
                  @"/opt/local/bin/",
                  @"/sw/bin/",
                  [homeDir stringByAppendingString: @"/.cabal/bin/"],
                  [homeDir stringByAppendingString: @"/bin/"],
                  nil ];
    for(NSString *dir in searchDirs) {
        NSString *execPath = [dir stringByAppendingString: @"HsColour"];
        //NSLog(@"HsColour path: %@", execPath);
        if([fm isExecutableFileAtPath: execPath]) {
            //NSLog(@"Found");
            return execPath;
        }
        //NSLog(@"Not found");
    }
    
    // 3. Otherwise, return NULL to indicate that HsColour can't be found.
    return NULL;
}

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url,
                               CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSAutoreleasePool *pool;
    NSMutableDictionary *props;
    CFStringRef fileRef;
    NSTask *hsColour;
    id htmlReader;
    NSData *htmlData;
    NSPipe *pipe;
    NSString *hsColourPath;
    
    pool = [[NSAutoreleasePool alloc] init];
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    hsColourPath = FindHsColour();
 
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;

    if(hsColourPath != NULL) {
        fileRef = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
        hsColour = [[[NSTask alloc] init] autorelease];
        [hsColour setLaunchPath: FindHsColour()];
        [hsColour setArguments: [NSArray arrayWithObjects: @"-html", (NSString *)fileRef, nil]];
        pipe = [[[NSPipe alloc] init] autorelease];
        [hsColour setStandardOutput: pipe];
        [hsColour launch];

        htmlReader = [pipe fileHandleForReading];
        htmlData = [htmlReader readDataToEndOfFile];
        CFRelease(fileRef);
    } else {
        NSString *notFound = @"<p>HsColour not found</p>";
        htmlData = [notFound dataUsingEncoding: NSUTF8StringEncoding];
    }
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;

    props=[[[NSMutableDictionary alloc] init] autorelease];
    [props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
    [props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];

    QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)htmlData,
                                          kUTTypeHTML, (CFDictionaryRef)props);
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
