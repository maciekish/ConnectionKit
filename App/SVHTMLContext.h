//
//  SVHTMLContext.h
//  Sandvox
//
//  Created by Mike on 19/10/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import "SVTemplateContext.h"


// publishing mode
typedef enum {
	kGeneratingPreview = 0,
	kGeneratingLocal,
	kGeneratingRemote,
	kGeneratingRemoteExport,
	kGeneratingQuickLookPreview = 10,
} KTHTMLGenerationPurpose;


@class KTAbstractPage, SVHTMLTextBlock;


@interface SVHTMLContext : SVTemplateContext
{
    NSUInteger  _indentation;
    
    NSURL                   *_baseURL;
    KTAbstractPage			*_currentPage;
    
	KTHTMLGenerationPurpose	_generationPurpose;
	BOOL					_includeStyling;
	BOOL                    _liveDataFeeds;
    BOOL                    _isXHTML;
    NSStringEncoding        _stringEncoding;
    
    NSMutableArray  *_iteratorsStack;
    
    NSMutableArray  *_textBlocks;
}

#pragma mark Stack

+ (SVHTMLContext *)currentContext;
+ (void)pushContext:(SVHTMLContext *)context;
+ (void)popContext;

// Convenience methods for pushing and popping that will just do the right thing when the receiver is nil
- (void)push;
- (void)pop;    // only pops if receiver is the current context


#pragma mark Writing

- (void)writeHTMLString:(NSString *)html;   // primitive method you MUST override
- (void)writeText:(NSString *)string;       // escapes the string and calls -writeHTMLString

- (void)writeNewline;   // writes a newline character and then enough tab characters to meet -indentationLevel

- (void)openTag:(NSString *)tagName idName:(NSString *)idName className:(NSString *)className;
- (void)closeTag:(NSString *)tagName;


#pragma mark Indentation

// Setting the indentation level does not write to the context in any way. It is up to methods that actually do some writing to respect the indent level. e.g. starting a new line should indent that line to match.
@property(nonatomic) NSUInteger indentationLevel;
- (void)indent;
- (void)outdent;


#pragma mark Properties

@property(nonatomic, copy) NSURL *baseURL;
@property(nonatomic) BOOL includeStyling;
@property(nonatomic) BOOL liveDataFeeds;
@property(nonatomic, getter=isXHTML) BOOL XHTML;
@property(nonatomic) NSStringEncoding encoding;   // UTF-8 by default

@property(nonatomic) KTHTMLGenerationPurpose generationPurpose;
@property(nonatomic, readonly, getter=isEditable) BOOL editable; // YES if HTML is intended to be edited directly in a Web Editor
- (BOOL)isPublishing;


#pragma mark Iterations

// It's pretty common to loop through a series of items when generating HTML. e.g. Pagelets in the Sidebar. When doing so, it's nice to generate a CSS class name that corresponds so special styling can be applied based on that. The Template Parser provides nice functions for generating these class names, but the stack of such iterations is maintained here.
// IMPORTANT: Iteration in the context is 0-based. For CSS class names you generally want it to be 1-based, so bump up values by 1. The HTML Template Parser functions do this automatically interally.

@property(nonatomic, readonly) NSUInteger currentIteration;
@property(nonatomic, readonly) NSUInteger currentIterationsCount;
- (void)nextIteration;  // increments -currentIteration. Pops the iterators stack if this was the last one.
- (void)beginIteratingWithCount:(NSUInteger)count;  // Pushes a new iterator on the stack
- (void)popIterator;  // Pops the iterators stack early


#pragma mark URLs/Paths
// These methods try to generate as simple a URL string when possible. e.g. relative path, or page ID
- (NSString *)relativeURLStringOfURL:(NSURL *)URL;
- (NSString *)relativeURLStringOfPage:(KTAbstractPage *)page;   
- (NSString *)relativeURLStringOfResourceFile:(NSURL *)resourceURL;


#pragma mark Content

// Default implementation does nothing. Subclasses can implement for introspecting the dependencies (WebView loading does)
- (void)addDependencyOnObject:(NSObject *)object keyPath:(NSString *)keyPath;
                               
@property(nonatomic, copy, readonly) NSArray *generatedTextBlocks;
- (void)didGenerateTextBlock:(SVHTMLTextBlock *)textBlock;




// In for compatibility, overrides -baseURL
@property(nonatomic, retain) KTAbstractPage *currentPage;

@end
