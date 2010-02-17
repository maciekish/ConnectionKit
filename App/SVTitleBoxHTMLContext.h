//
//  SVTitleBoxHTMLContext.h
//  Sandvox
//
//  Created by Mike on 10/01/2010.
//  Copyright 2010 Karelia Software. All rights reserved.
//

//  To get HTML out of the DOM and into the model, the DOM nodes are written to an HTML context. SVHTMLContext does a pretty good job out of the box, but SVTitleBoxHTMLContext has a few extra tricks up its sleeve:
//
//  -   Writing element start tags is performed lazily; when you open an element, it is queued up on an internal stack and only actually written when it is time to write some following non-start tag content. If the element turns out to be empty, it can be removed from the DOM, and wiped from the stack without any actual writing ever having taken place.
//
//  -   Only a small whitelist of elements, attributes and styling are permitted. Anything failing to make the grade will be removed from the DOM and not actually written to the context.


#import "SVMutableStringHTMLContext.h"


@interface SVTitleBoxHTMLContext : SVMutableStringHTMLContext
{
  @private
    NSMutableArray  *_unwrittenDOMElements;
}


- (DOMNode *)replaceDOMElementIfNeeded:(DOMElement *)element;


#pragma mark Tag Whitelist
+ (BOOL)validateTagName:(NSString *)tagName;
+ (BOOL)isElementWithTagNameContent:(NSString *)tagName;


#pragma mark Attribute Whitelist
- (BOOL)validateAttribute:(NSString *)attributeName;


#pragma mark Styling Whitelist
- (BOOL)validateStyleProperty:(NSString *)propertyName;
- (void)removeUnsupportedCustomStyling:(DOMCSSStyleDeclaration *)style;


@end
