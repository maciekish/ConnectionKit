//
//  NSString+IMStatus.m
//  IMStatusElement
//
//  Copyright 2010-11 Karelia Software. All rights reserved.
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

#import "NSString+IMStatus.h"


@implementation NSString (IMStatus)

- (NSString *)im_stringByAddingPercentEscapesWithSpacesAsPlusCharacters:(BOOL)encodeSpacesAsPlusCharacters
{
	// Add the percent escapes. If encodeSpacesAsPlusCharacters has been requested, then don't both escaping them
    NSString *charactersToLeaveUnescaped = (encodeSpacesAsPlusCharacters) ? @" " : @"";
    
    NSString *result = [self im_stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding
                                               charactersToLeaveUnescaped:charactersToLeaveUnescaped
                                            legalURLCharactersToBeEscaped:@"&+%="];
    
    
    // If the user requested it, replace spaces with + signs
    if (encodeSpacesAsPlusCharacters)
    {
        NSMutableString *mutableResult = [result mutableCopy];
        [mutableResult replaceOccurrencesOfString:@" "
                                       withString:@"+"
                                          options:NSLiteralSearch
                                            range:NSMakeRange(0, [mutableResult length])];
        
        result = [mutableResult autorelease];
    }
    
    
    return result;
}

- (NSString *)im_stringByAddingPercentEscapesUsingEncoding:(NSStringEncoding)encoding
                                charactersToLeaveUnescaped:(NSString *)unescapedCharacters
                             legalURLCharactersToBeEscaped:(NSString *)legalCharactersToEscape;
{
    NSString *result = NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 (CFStringRef)unescapedCharacters,
                                                                                 (CFStringRef)legalCharactersToEscape,
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
    
    return [result autorelease];
}

@end
