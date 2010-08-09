//
//  IFramePlugIn.m
//  IFrameElement
//
//  Copyright 2004-2010 Karelia Software. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  *  Redistribution of source code must retain the above copyright notice,
//     this list of conditions and the follow disclaimer.
//
//  *  Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other material provided with the distribution.
//
//  *  Neither the name of Karelia Software nor the names of its contributors
//     may be used to endorse or promote products derived from this software
//     without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS-IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUR OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Community Note: This code is distrubuted under a modified BSD License.
//  We encourage you to share your Sandvox Plugins similarly.
//

#import "IFramePlugIn.h"

// LocalizedStringInThisBundle(@"Placeholder for:", "String_On_Page_Template- followed by a URL")

@implementation IFramePlugIn


#pragma mark -
#pragma mark SVPlugIn

+ (NSArray *)plugInKeys
{ 
    return [NSArray arrayWithObjects:
            @"iFrameHeight", 
            @"iFrameWidth", 
            @"iFrameIsBordered",
            @"linkURL",
            nil];
}


- (void)dealloc
{
    self.linkURL = nil;
	[super dealloc]; 
}

- (void)awakeFromNew;
{
    [super awakeFromNew];
    
    // Attempt to automatically grab the URL from the user's browser
    id<SVWebLocation> location = [[NSWorkspace sharedWorkspace] fetchBrowserWebLocation];
    if ( location )
    {
        self.linkURL = [location URL];
        [[self container] setTitle:[location title]];
    }
    
    // Set our "show border" checkbox from the defaults
    self.iFrameIsBordered = [[NSUserDefaults standardUserDefaults] boolForKey:@"iFramePageletIsBordered"];
}


-(BOOL)validateiFrameWidth:(id *)ioValue error:(NSError **)outError 
{
    if ( *ioValue == nil || [*ioValue isEqual:@""] ) 
    {
        *ioValue = [NSNumber numberWithFloat:0.0];
    }
    return YES;
}


#pragma mark -
#pragma mark Properties

@synthesize iFrameHeight = _iFrameHeight;
@synthesize iFrameWidth = _iFrameWidth;
@synthesize linkURL = _linkURL;

@synthesize iFrameIsBordered = _iFrameIsBordered;
- (void)setIFrameIsBordered:(BOOL)yn
{
    [self willChangeValueForKey:@"iFrameIsBordered"];
    _iFrameIsBordered = yn;
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:@"iFramePageletIsBordered"];
    [self didChangeValueForKey:@"iFrameIsBordered"];
}

@end
