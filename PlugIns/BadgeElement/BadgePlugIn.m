//
//  BadgePlugIn.m
//  BadgeElement
//
//  Copyright 2004-2011 Karelia Software. All rights reserved.
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
//  Community Note: This code is distributed under a modified BSD License.
//  We encourage you to share your Sandvox Plugins similarly.
//

#import "BadgePlugIn.h"

#import "KSSHA1Stream.h"



@interface BadgePlugIn ()
- (NSString *)generateBlurbVariant:(NSInteger)aVariant;
@property(nonatomic, retain) NSArray *altStrings;
@end


@implementation BadgePlugIn

- (void)dealloc
{
    self.badgeAltString = nil;
    self.badgeTitleString = nil;
    self.altStrings = nil;
	[super dealloc];
}

- (void)awakeFromNew;
{
    [super awakeFromNew];
    [self setShowsTitle:NO];
    [self setBadgeTypeTag:1];
    [self setIncludeReferralCode:YES];
}

- (void)pageDidChange:(id <SVPage>)page
{
    // we want all strings to be in language of site vistor
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *language = [page language];

    // determine strings based on language of page
    
    // These are various strings, randomly chosen, for the blurb on the badge.  This will help direct
    // Traffic to the Sandvox site!

    NSString *alt1 = [bundle localizedStringForString:@"The Website Builder for the Mac - publish blogs and photos on any host"
                                             language:language 
                                             fallback:SVLocalizedString(@"The Website Builder for the Mac - publish blogs and photos on any host", @"Sandvox link-back blurb")];
    NSString *alt2 = [bundle localizedStringForString:@"The easy mac web site creator - for school, family, business"
                                             language:language 
                                             fallback:SVLocalizedString(@"The easy mac web site creator - for school, family, business", @"Sandvox link-back blurb")];
    NSString *alt3 = [bundle localizedStringForString:@"Create websites on the Mac and host them anywhere"
                                             language:language 
                                             fallback:SVLocalizedString(@"Create websites on the Mac and host them anywhere", @"Sandvox link-back blurb")];
    NSString *alt4 = [bundle localizedStringForString:@"Build websites, photo albums, and blogs on the Mac"
                                             language:language 
                                             fallback:SVLocalizedString(@"Build websites, photo albums, and blogs on the Mac", @"Sandvox link-back blurb")];
    NSString *alt5 = [bundle localizedStringForString:@"Build and publish a web site with your Mac - for individuals, education, and small business"
                                             language:language 
                                             fallback:SVLocalizedString(@"Build and publish a web site with your Mac - for individuals, education, and small business", @"Sandvox link-back blurb")];
    NSString *alt6 = [bundle localizedStringForString:@"Using your Macintosh, publish your photo album / blog / website on any ISP"
                                             language:language 
                                             fallback:SVLocalizedString(@"Using your Macintosh, publish your photo album / blog / website on any ISP", @"Sandvox link-back blurb")];
    self.altStrings = [NSArray arrayWithObjects:alt1, alt2, alt3, alt4, alt5, alt6, nil];    
    

    NSString *altBlurb = [self generateBlurbVariant:0];
    NSString *variant0 = [bundle localizedStringForString:@"Created with Sandvox - %@"
                                                 language:language 
                                                 fallback:SVLocalizedString(@"Created with Sandvox - %@",@"Alt string for sandvox badge")];
    NSString *altString = [NSString stringWithFormat:variant0, altBlurb];			
    self.badgeAltString = altString;
    
    NSString *titleBlurb = [self generateBlurbVariant:1];
    NSString *variant1 = [bundle localizedStringForString:@"Learn about Sandvox - %@"
                                                 language:language 
                                                 fallback:SVLocalizedString(@"Learn about Sandvox - %@",@"title string for sandvox badge link")];
    NSString *titleString = [NSString stringWithFormat:variant1, titleBlurb];
    self.badgeTitleString = titleString;
}

- (void)awakeFromSourceProperties:(NSDictionary *)properties
{
    [super awakeFromSourceProperties:properties];
    if ( [properties objectForKey:@"anonymous"] )
    {
        self.includeReferralCode = [[properties objectForKey:@"anonymous"] boolValue];
    }
    
    // #110070 - "fix" badgeTypeTag
    // arrays are treated as 1-ordered since 0 is text-only
    // S1 defines sharedBadgeNames as
    //@"sandvox_castle_white", 
    //@"sandvox_castle_top", 
    //@"sandvox_bucket_white",
    //@"sandvox_bucket",
    //@"sandvox_icon_white"
    
    // S2 defines sharedBadgeNames as
    //@"sandvox_icon_white",
    //@"sandvox_castle", 
    //@"sandvox_castle_white", 
    //@"sandvox_castle_top", 
    //@"sandvox_castle_top_white", 
    //@"sandvox_bucket",
    //@"sandvox_bucket_white",
    
    NSUInteger oldTag = self.badgeTypeTag;
    NSUInteger newTag = oldTag;
    switch ( oldTag )
    {
        case 1:
            newTag = 3;
            break;
        case 2:
            newTag = 4;
            break;
        case 3:
            newTag = 7;
            break;
        case 4:
            newTag = 6;
            break;
        case 5:
            newTag = 1;
            break;
        default:
            break;
    }
    self.badgeTypeTag = newTag;
}


#pragma mark -
#pragma mark SVPlugIn

+ (NSArray *)plugInKeys
{ 
    return [NSArray arrayWithObjects:
            @"badgeTypeTag", 
            @"includeReferralCode", 
            @"openLinkInNewWindow",
            @"badgeAltString",
            @"badgeTitleString",
            nil];
}


#pragma mark -
#pragma mark HTML Generation

+ (NSArray *)sharedBadgeNames
{
    static NSArray *sBadgeNames = nil;
	if (nil == sBadgeNames)
	{
        // #110070 - any change to this ordering
        // needs to be reflected in -awakeFromSourceProperties:
		sBadgeNames = [[NSArray alloc] initWithObjects:
					   @"sandvox_icon_white",
					   @"sandvox_castle", 
					   @"sandvox_castle_white", 
					   @"sandvox_castle_top", 
					   @"sandvox_castle_top_white", 
					   @"sandvox_bucket",
					   @"sandvox_bucket_white",
					   nil];
	}
	return sBadgeNames;
}

+ (NSArray *)sharedBadgeSizes
{
    static NSArray *sBadgeSizes = nil;

    if ( nil == sBadgeSizes )
    {
        sBadgeSizes = [[NSArray alloc] initWithObjects:
                       [NSValue valueWithSize:NSMakeSize(88., 31.)],
                       [NSValue valueWithSize:NSMakeSize(88., 45.)],
                       [NSValue valueWithSize:NSMakeSize(88., 45.)],
                       [NSValue valueWithSize:NSMakeSize(88., 44.)],
                       [NSValue valueWithSize:NSMakeSize(88., 44.)],
                       [NSValue valueWithSize:NSMakeSize(94., 47.)],
                       [NSValue valueWithSize:NSMakeSize(94., 47.)],
                       nil];
    }
    return sBadgeSizes;
}


- (NSString *)badgePreludeString
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *language = [[[self currentContext] page] language];
    NSString *result = [bundle localizedStringForString:@"Created with"
                                               language:language 
                                               fallback:SVLocalizedString(@"Created with", @"string that goes before badgeLinkString, for badge - always BEFORE 'Sandvox' regardless of language")];
	return result;
}

- (NSString *)badgeLinkString
{
	return SVLocalizedString(@"Sandvox", @"linked text in the text badge linking back to sandvox site.  Always FOLLOWS the 'created with' regardless of language.");
}

// Use a hash to get a sort of arbitrary string for this unique document
- (NSString *)generateBlurbVariant:(NSInteger)aVariant
{
    NSAssert([self.altStrings count] > 0, @"no altStrings available for blurb");
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *seedString = NSMakeCollectable(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    
    
    NSData *hashData = [[seedString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] SHA1Digest];
    unsigned char *bytes = (unsigned char *)[hashData bytes];
    [seedString release];
    // we have a nice 20-byte hash .... now to boil this down to a very small number!
	
    // Make a quick checksum of this
    unsigned long long total = 0;
    NSInteger i;
    for ( i = 0 ; i < 20 ; i++ )
	{
		unichar theChar = bytes[i];
		total = (total << 1) ^ theChar;
	}
	
	total += aVariant;		// Offset the number just a bit
	
	NSInteger stringNumber = total % [self.altStrings count];
	NSString *blurb = [self.altStrings objectAtIndex:stringNumber];
    
	return blurb;
}

// returns title of graphic to display
- (NSString *)currentBadgeName
{
	NSString *result = nil;
	NSUInteger tag = [self badgeTypeTag]; // TAG 0 means not image...
	if (tag > BADGE_TEXT && tag <= [[BadgePlugIn sharedBadgeNames] count])
	{
		result = [[BadgePlugIn sharedBadgeNames] objectAtIndex:tag-1];
	}
	return result;
}

- (NSSize)currentBadgeSize
{
	NSSize result = NSZeroSize;
	NSUInteger tag = [self badgeTypeTag]; // TAG 0 means not image...
	if (tag > BADGE_TEXT && tag <= [[BadgePlugIn sharedBadgeNames] count])
	{
		result = [(NSValue *)[[BadgePlugIn sharedBadgeSizes] objectAtIndex:tag-1] sizeValue];
	}
	return result;
}

// returns relative URL for current badge, suitable for use in HTML template
// alternatively, in template, could do <img src="[[=writeBadgeSrc]]"…
- (NSString *)badgeURLString
{
    // find badge resource
    NSString *language = [[[self currentContext] page] language];
    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] 
                              pathForImageResource:[self currentBadgeName] 
                              language:language];
    NSURL *resourceURL = [NSURL fileURLWithPath:resourcePath];
    
    // add resource to context
    NSURL *contextURL = [[self currentContext] addResourceAtURL:resourceURL destination:SVDestinationResourcesDirectory options:0];
    
    // generate relative string for template
    NSString *result = [[self currentContext] relativeStringFromURL:contextURL];    
    return result;
}

- (void)writeHTML:(id <SVPlugInContext>)context
{
    [super writeHTML:context];
    [context addDependencyForKeyPath:@"language" ofObject:[context page]];
}

- (NSUInteger)imgWidth
{
    return [self currentBadgeSize].width;
}

- (NSUInteger)imgHeight
{
    return [self currentBadgeSize].height;
}


#pragma mark -
#pragma mark Properties

@synthesize badgeAltString = _badgeAltString;
@synthesize badgeTitleString = _badgeTitleString;
@synthesize badgeTypeTag = _badgeTypeTag;
@synthesize includeReferralCode = _includeReferralCode;
@synthesize openLinkInNewWindow = _openLinkInNewWindow;
@synthesize altStrings = _altStrings;
@end
