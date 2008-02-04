#include <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

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
    
    pool = [[NSAutoreleasePool alloc] init];
    
    if (QLPreviewRequestIsCancelled(preview))
        return noErr;
    
    fileRef = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
    hsColour = [[[NSTask alloc] init] autorelease];
    [hsColour setLaunchPath: @"/Users/atomb/.cabal/bin/HsColour"];
    [hsColour setArguments: [NSArray arrayWithObjects: @"-html", (NSString *)fileRef, nil]];
    pipe = [[[NSPipe alloc] init] autorelease];
    [hsColour setStandardOutput: pipe];
    [hsColour launch];

    htmlReader = [pipe fileHandleForReading];
    htmlData = [htmlReader readDataToEndOfFile];
    CFRelease(fileRef);
    
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
