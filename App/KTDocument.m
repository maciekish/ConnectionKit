//
//  KTDocument.m
//  Marvel
//
//  Copyright 2004-2009 Karelia Software. All rights reserved.
//

/*
 PURPOSE OF THIS CLASS/CATEGORY:
	Standard NSDocument subclass to handle a single web site.
	(Core functionality of the document is handled in this file)
	Deals with:
 General UI
 DataCrux
 File I/O
 Menu & Toolbar
 Accessors
 Actions
 WebView Notifications
 
 
 TAXONOMY AND RELATIONSHIP TO OTHER CLASSES:
	Inherits from NSDocument
	Delegate of the webview
 
 IMPLEMENTATION NOTES & CAUTIONS:
	The WebView notifications ought to be in a category, but for some strange reason,
	they aren't found there, so we have to put them into the main class!
 
 */

/*!
 @class KTDocument
 @abstract An NSPersistentDocument subclass that encapsulates functionality for a single website.
 @discussion An NSPersistentDocument subclass that encapsulates functionality for a single website. Major areas of responsibility include General UI, CoreData and additional File I/O, Menu and Toolbar, Accessors, Actions, and WebView Notifications.
 @updated 2005-03-12
 */

#import "KTDocument.h"

#import "KSAbstractBugReporter.h"
#import "KSSilencingConfirmSheet.h"
#import "KT.h"
#import "KTAbstractIndex.h"
#import "KTAppDelegate.h"
#import "KTElementPlugin.h"
#import "KTCodeInjectionController.h"
#import "KTDesign.h"
#import "KTDocSiteOutlineController.h"
#import "KTDocWebViewController.h"
#import "KTDocWindowController.h"
#import "KTDocumentController.h"
#import "KTSite.h"
#import "KTElementPlugin.h"
#import "KTHTMLInspectorController.h"
#import "KTHostProperties.h"
#import "KTHostSetupController.h"
#import "KTIndexPlugin.h"
#import "SVInspector.h"
#import "KTMaster+Internal.h"
#import "KTMediaManager+Internal.h"
#import "KTPage+Internal.h"
#import "SVPagelet.h"
#import "SVBody.h"
#import "SVBodyParagraph.h"
#import "KTStalenessManager.h"
#import "KTSummaryWebViewTextBlock.h"
#import "KTLocalPublishingEngine.h"

#import "NSApplication+Karelia.h"       // Karelia Cocoa additions
#import "NSArray+Karelia.h"
#import "NSBundle+Karelia.h"
#import "NSDate+Karelia.h"
#import "NSFileManager+Karelia.h"
#import "NSImage+Karelia.h"
#import "NSObject+Karelia.h"
#import "NSManagedObjectContext+KTExtensions.h"
#import "NSString+Karelia.h"
#import "NSThread+Karelia.h"
#import "NSWindow+Karelia.h"
#import "NSURL+Karelia.h"

#import <iMedia/iMedia.h>

#import "Debug.h"                       // Debugging

#import "Registration.h"                // Licensing


// Trigger Localization ... thes are loaded with the [[` ... ]] directive

// NSLocalizedStringWithDefaultValue(@"skipNavigationTitleHTML", nil, [NSBundle mainBundle], @"Site Navigation", @"Site navigation title on web pages (can be empty if link is understandable)")
// NSLocalizedStringWithDefaultValue(@"backToTopTitleHTML", nil, [NSBundle mainBundle], @" ", @"Back to top title, generally EMPTY")
// NSLocalizedStringWithDefaultValue(@"skipSidebarsTitleHTML", nil, [NSBundle mainBundle], @"Sidebar", @"Sidebar title on web pages (can be empty if link is understandable)")
// NSLocalizedStringWithDefaultValue(@"skipNavigationLinkHTML", nil, [NSBundle mainBundle], @"[Skip]", @"Skip navigation LINK on web pages"), @"skipNavigationLinkHTML",
// NSLocalizedStringWithDefaultValue(@"skipSidebarsLinkHTML", nil, [NSBundle mainBundle], @"[Skip]", @"Skip sidebars LINK on web pages"), @"skipSidebarsLinkHTML",
// NSLocalizedStringWithDefaultValue(@"backToTopLinkHTML", nil, [NSBundle mainBundle], @"[Back To Top]", @"back-to-top LINK on web pages"), @"backToTopLinkHTML",

// NSLocalizedStringWithDefaultValue(@"navigateNextHTML",		nil, [NSBundle mainBundle], @"Next",		@"alt text of navigation button"),	@"navigateNextHTML",
// NSLocalizedStringWithDefaultValue(@"navigateListHTML",		nil, [NSBundle mainBundle], @"List",		@"alt text of navigation button"),	@"navigateListHTML",
// NSLocalizedStringWithDefaultValue(@"navigatePreviousHTML",	nil, [NSBundle mainBundle], @"Previous",	@"alt text of navigation button"),	@"navigatePreviousHTML",
// NSLocalizedStringWithDefaultValue(@"navigateMainHTML",		nil, [NSBundle mainBundle], @"Main",		@"text of navigation button"),		@"navigateMainHTML",


NSString *KTDocumentDidChangeNotification = @"KTDocumentDidChange";
NSString *KTDocumentWillCloseNotification = @"KTDocumentWillClose";


@interface KTDocument ()

- (KTPage *)makeRootPage;

- (void)setupHostSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end


#pragma mark -


@implementation KTDocument

#pragma mark -
#pragma mark Init & Dealloc

/*! designated initializer for all NSDocument instances. Common initialization to new doc and opening a doc */
- (id)init
{
	if (gLicenseViolation)
	{
		NSBeep();
        [self release];
		return nil;
	}
	
    
    if (self = [super init])
	{
		[self setThread:[NSThread currentThread]];
        
        
        // Set up managed object context
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[[self managedObjectContext] setMergePolicy:NSOverwriteMergePolicy]; // Standard document-like behaviour
		
		NSManagedObjectModel *model = [[self class] managedObjectModel];
		NSPersistentStoreCoordinator *PSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
		[[self managedObjectContext] setPersistentStoreCoordinator:PSC];
		[PSC release];
        
        [super setUndoManager:[[self managedObjectContext] undoManager]];
        
        
        // Init UI accessors
		NSNumber *tmpValue = [self wrappedInheritedValueForKey:@"displaySiteOutline"];
		[self setDisplaySiteOutline:(tmpValue) ? [tmpValue boolValue] : YES];
		
		tmpValue = [self wrappedInheritedValueForKey:@"displayStatusBar"];
		[self setDisplayStatusBar:(tmpValue) ? [tmpValue boolValue] : YES];
		
		tmpValue = [self wrappedInheritedValueForKey:@"displayEditingControls"];
		[self setDisplayEditingControls:(tmpValue) ? [tmpValue boolValue] : YES];
		
		tmpValue = [self wrappedInheritedValueForKey:@"displaySmallPageIcons"];
		[self setDisplaySmallPageIcons:(tmpValue) ? [tmpValue boolValue] : NO];
		
		
        // Create media manager
        myMediaManager = [[KTMediaManager alloc] initWithDocument:self];
    }
	
    return self;
}

/*! initializer for creating a new document
	NB: this is not shown on screen
 */
- (id)initWithType:(NSString *)type error:(NSError **)error
{
	self = [super initWithType:type error:error];
    
    if (self)
    {
        // Make a new site to store document properties
        NSManagedObjectContext *context = [self managedObjectContext];
        
        KTSite *site = [NSEntityDescription insertNewObjectForEntityForName:@"Site"
                                                     inManagedObjectContext:context];
        [self setSite:site];
        
        NSDictionary *docProperties = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultDocumentProperties"];
        if (docProperties)
        {
            [[self site] setValuesForKeysWithDictionary:docProperties];
        }
        
        
        // make a new root
        // POSSIBLE PROBLEM -- THIS WON'T WORK WITH EXTERALLY LOADED BUNDLES...
        KTPage *root = [self makeRootPage];
        OBASSERTSTRING((nil != root), @"root page is nil!");
        [[self site] setValue:root forKey:@"root"];
        
        
        // Create the site Master object
        KTMaster *master = [NSEntityDescription insertNewObjectForEntityForName:@"Master" inManagedObjectContext:[self managedObjectContext]];
        [root setValue:master forKey:@"master"];
        
        
        // Set the design
        KTDesign *design = [[KSPlugin sortedPluginsWithFileExtension:kKTDesignExtension] firstObjectKS];
        [master setDesign:design];
		[self setShowDesigns:NO]; // FIXME: turned off old design chooser for now
        
        
        // Set up root properties that used to come from document defaults
        [master setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"author"] forKey:@"author"];
        [root setBool:YES forKey:@"isCollection"];
        
        // This probably should use -[NSBundle preferredLocalizationsFromArray:forPreferences:]
        // http://www.cocoabuilder.com/archive/message/cocoa/2003/4/24/84070
        // though there's a problem ... that will return a string like "English" not "en"
        NSString *language = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
        [master setValue:language forKey:@"language"];
        [master setValue:@"UTF-8" forKey:@"charset"];
        
        
        NSString *defaultRootPageTitleText = [[NSBundle mainBundle] localizedStringForString:@"defaultRootPageTitleText"
                                                                                    language:language
                                                                                    fallback:
                                              NSLocalizedStringWithDefaultValue(@"defaultRootPageTitleText", nil, [NSBundle mainBundle], @"Home Page", @"Title of initial home page")];
        [root setTitleText:defaultRootPageTitleText];
        
        
        // Set the Favicon
        NSString *faviconPath = [[NSBundle mainBundle] pathForImageResource:@"32favicon"];
        KTMediaContainer *faviconMedia = [[root mediaManager] mediaContainerWithPath:faviconPath];
        [master setValue:[faviconMedia identifier] forKey:@"faviconMediaIdentifier"];
        
        
        // Create a starter pagelet
        SVPagelet *pagelet = [SVPagelet pageletWithManagedObjectContext:[self managedObjectContext]];
        [pagelet setSortKey:[NSNumber numberWithShort:0]];
        [pagelet setTitleHTMLString:@"Test"];
        
        SVBodyParagraph *paragraph = [NSEntityDescription insertNewObjectForEntityForName:@"BodyParagraph"
                                                               inManagedObjectContext:[self managedObjectContext]];
        [paragraph setTagName:@"p"];
        [paragraph setInnerHTMLArchiveString:@"Test paragraph"];
        [paragraph setSortKey:[NSNumber numberWithShort:0]];
        
        [[pagelet body] addElement:paragraph];
        [[root sidebar] addPageletsObject:pagelet];
    }
	
	
    return self;
}

- (KTPage *)makeRootPage
{
    id result = [NSEntityDescription insertNewObjectForEntityForName:@"Root" 
                                              inManagedObjectContext:[self managedObjectContext]];
	OBASSERT(result);
	
	[result setValue:[self site] forKey:@"site"];	// point to yourself
		
    [result setBool:YES forKey:@"isCollection"];	// root is automatically a collection
    [result setAllowComments:[NSNumber numberWithBool:NO]];
    [result awakeFromBundleAsNewlyCreatedObject:YES];
    
	return result;
}

- (void)dealloc
{
	[_site release];
    
    [myMediaManager release];
	
	// release context
	[_managedObjectContext release];
    
    [_thread release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Managing the Persistence Objects

/*	The first time the model is loaded, we need to give Fetched Properties sort descriptors.
 */
+ (NSManagedObjectModel *)managedObjectModel
{
	static NSManagedObjectModel *result;
	
	if (!result)
	{
		// grab only Sandvox.mom (ignoring "previous moms" in KTComponents/Resources)
		NSBundle *componentsBundle = [NSBundle bundleForClass:[KTAbstractElement class]];
        OBASSERT(componentsBundle);
		
        NSString *modelPath = [componentsBundle pathForResource:@"Sandvox" ofType:@"mom"];
        OBASSERTSTRING(modelPath, [componentsBundle description]);
        
		NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
		OBASSERT(modelURL);
		
		result = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	}
	
	OBPOSTCONDITION(result);
	return result;
}

- (NSManagedObjectContext *)managedObjectContext { return _managedObjectContext; }

/*  Called whenever a document is opened *and* when a new document is first saved.
 */
- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)URL
                                           ofType:(NSString *)fileType
                               modelConfiguration:(NSString *)configuration
                                     storeOptions:(NSDictionary *)storeOptions
                                            error:(NSError **)outError
{
	NSPersistentStoreCoordinator *storeCoordinator = [[self managedObjectContext] persistentStoreCoordinator];
	OBPRECONDITION([[storeCoordinator persistentStores] count] == 0);   // This method should only be called the once
    
    
    BOOL result = YES;
	
	/// and we compute the sqlite URL here for both read and write
	NSURL *storeURL = [KTDocument datastoreURLForDocumentURL:URL type:nil];
	
	// these two lines basically take the place of sending [super configurePersistentStoreCoordinatorForURL:ofType:error:]
	// NB: we're not going to use the supplied configuration or options here, though we could in a Leopard-only version
	result = (nil != [storeCoordinator addPersistentStoreWithType:[self persistentStoreTypeForFileType:fileType]
									   configuration:nil
												 URL:storeURL
											 options:nil
											   error:outError]);
	
	// Also configure media manager's store
	if (result)
	{
		NSPersistentStoreCoordinator *mediaPSC = [[[self mediaManager] managedObjectContext] persistentStoreCoordinator];
		result = (nil != [mediaPSC addPersistentStoreWithType:NSXMLStoreType
												configuration:nil
														  URL:[KTMediaManager mediaStoreURLForDocumentURL:URL]
													  options:nil
														error:outError]);
	}
	
	
	return result;
}

- (NSString *)persistentStoreTypeForFileType:(NSString *)fileType
{
	return NSSQLiteStoreType;
}

- (void)setFileURL:(NSURL *)absoluteURL
{
    NSURL *oldURL = [[self fileURL] copy];
    [super setFileURL:absoluteURL];
    
    
    if (oldURL)
    {
        // Also reset the persistent stores' DB connection if needed
        NSPersistentStoreCoordinator *PSC = [[self managedObjectContext] persistentStoreCoordinator];
        OBASSERT([[PSC persistentStores] count] <= 1);
        NSPersistentStore *store = [PSC persistentStoreForURL:[[self class] datastoreURLForDocumentURL:oldURL type:nil]];
        if (store)
        {
            NSURL *newStoreURL = [[self class] datastoreURLForDocumentURL:absoluteURL type:nil];
            [PSC setURL:newStoreURL forPersistentStore:store];
        }
        
        PSC = [[[self mediaManager] managedObjectContext] persistentStoreCoordinator];
        OBASSERT([[PSC persistentStores] count] <= 1);
        store = [PSC persistentStoreForURL:[KTMediaManager mediaStoreURLForDocumentURL:oldURL]];
        if (store)
        {
            NSURL *newStoreURL = [KTMediaManager mediaStoreURLForDocumentURL:absoluteURL];
            [PSC setURL:newStoreURL forPersistentStore:store];
        }
        
        [oldURL release];
    }
}

#pragma mark -
#pragma mark Undo Support

/*  These methods are overridden in the same fashion as NSPersistentDocument
 */

- (BOOL)hasUndoManager { return YES; }

- (void)setHasUndoManager:(BOOL)flag { }

- (void)setUndoManager:(NSUndoManager *)undoManager
{
    // The correct undo manager is stored at initialisation time and can't be changed
}

#pragma mark -
#pragma mark Document Content Management

/*  Supplement the usual read behaviour by logging host properties and loading document display properties
 */
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	// Should only be called the once
    BOOL result = [self configurePersistentStoreCoordinatorForURL:absoluteURL ofType:typeName modelConfiguration:nil storeOptions:nil error:outError];
    
    
    // Grab the site object
    if (result)
	{
        KTSite *site = [[[self managedObjectContext] site] retain];
        [self setSite:site];
        if (!site)
        {
            if (outError) *outError = nil;  // TODO: Return a proper error object
            result = NO;
        }
    }
    
    
    if (result)
    {
		// Load up document display properties
		[self setDisplaySmallPageIcons:[[self site] boolForKey:@"displaySmallPageIcons"]];
		
		
        // For diagnostics, log the value of the host properties
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LogHostInfoToConsole"])
		{
			KTHostProperties *hostProperties = [[self site] hostProperties];
			NSLog(@"hostProperties = %@", [[hostProperties hostPropertiesReport] condenseWhiteSpace]);
		}
	}
    
    return result;
}

/*  Saving a document is somewhat complicated, so it's implemented in a dedicated category:
 *  KTDocument+Saving.m
 */

#pragma mark -
#pragma mark Document paths

/*	Returns the URL to the primary document persistent store. This differs dependent on the document UTI.
 *	You can pass in nil to use the default UTI for new documents.
 */
+ (NSURL *)datastoreURLForDocumentURL:(NSURL *)inURL type:(NSString *)documentUTI
{
	OBPRECONDITION(inURL);
	
	NSURL *result = nil;
	
	
	if (!documentUTI || [documentUTI isEqualToString:kKTDocumentUTI])
	{
		result = [inURL URLByAppendingPathComponent:@"datastore.sqlite3" isDirectory:NO];
	}
	else if ([documentUTI isEqualToString:kKTDocumentUTI_ORIGINAL])
	{
		result = inURL;
	}
	else
	{
		OBASSERT_NOT_REACHED("Unknown document UTI");
	}
	
	
	return result;
}

/*	Returns /path/to/document/Site
 */
+ (NSURL *)siteURLForDocumentURL:(NSURL *)inURL
{
	OBPRECONDITION(inURL);
	
	NSURL *result = [inURL URLByAppendingPathComponent:@"Site" isDirectory:YES];
	
	OBPOSTCONDITION(result);
	return result;
}

+ (NSURL *)quickLookURLForDocumentURL:(NSURL *)inURL
{
	OBASSERT(inURL);
	
	NSURL *result = [inURL URLByAppendingPathComponent:@"QuickLook" isDirectory:YES];
	
	OBPOSTCONDITION(result);
	return result;
}

/*! Returns /path/to/document/Site/_Media
 */
+ (NSURL *)mediaURLForDocumentURL:(NSURL *)inURL
{
	OBASSERT(inURL);
	
	NSURL *result = [[self siteURLForDocumentURL:inURL] URLByAppendingPathComponent:@"_Media" isDirectory:YES];
	
	OBPOSTCONDITION(result);
	return result;
}

- (NSURL *)mediaDirectoryURL;
{
	/// This could be calculated from [self fileURL], but that doesn't work when making the very first save
	NSPersistentStoreCoordinator *storeCordinator = [[self managedObjectContext] persistentStoreCoordinator];
	NSURL *storeURL = [storeCordinator URLForPersistentStore:[[storeCordinator persistentStores] firstObjectKS]];
	NSURL *docURL = [storeURL URLByDeletingLastPathComponent];
	
    NSURL *result = [[self class] mediaURLForDocumentURL:docURL];
	return result;
}

/*	Temporary media is stored in:
 *	
 *		Application Support -> Sandvox -> Temporary Media Files -> Document ID -> a file
 *
 *	This method returns the path to that directory, creating it if necessary.
 */
- (NSString *)temporaryMediaPath;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *sandvoxSupportDirectory = [NSApplication applicationSupportPath];

	NSString *mediaFilesDirectory = [sandvoxSupportDirectory stringByAppendingPathComponent:@"Temporary Media Files"];
	NSString *result = [mediaFilesDirectory stringByAppendingPathComponent:[[self site] siteID]];
	
	// Create the directory if needs be
	if (![fileManager fileExistsAtPath:result])
	{
		[fileManager createDirectoryPath:result attributes:nil];
	}
		
	OBPOSTCONDITION(result);
	return result;
}

- (NSString *)siteDirectoryPath;
{
	NSURL *docURL = [self fileURL];
	
	if (!docURL)
	{
		NSPersistentStoreCoordinator *storeCordinator = [[self managedObjectContext] persistentStoreCoordinator];
		NSURL *storeURL = [storeCordinator URLForPersistentStore:[[storeCordinator persistentStores] firstObjectKS]];
		docURL = [storeURL URLByDeletingLastPathComponent];
	}
	
	NSString *result = [[KTDocument siteURLForDocumentURL:docURL] path];
	return result;
}

#pragma mark -
#pragma mark Controller Chain

/*!	Force KTDocument to use a custom subclass of NSWindowController
 */
- (void)makeWindowControllers
{
    NSWindowController *windowController = [[KTDocWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController release];
}

- (void)addWindowController:(NSWindowController *)windowController
{
	if ( nil != windowController )
    {
		[super addWindowController:windowController];
	}
}

- (void)removeWindowController:(NSWindowController *)windowController
{
	if ( [windowController isEqual:myHTMLInspectorController] )
    {
		[self setHTMLInspectorController:nil];
	}
		
	
    [super removeWindowController:windowController];
}

#pragma mark -
#pragma mark Changes

/*  Supplement NSDocument by broadcasting a notification that the document did change
 */
- (void)updateChangeCount:(NSDocumentChangeType)changeType
{
    [super updateChangeCount:changeType];
    
    if (changeType == NSChangeDone || changeType == NSChangeUndone)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:KTDocumentDidChangeNotification object:self];
    }
}

// TODO: Is this method strictly necessary? Seems kinda hackish to me
- (void)processPendingChangesAndClearChangeCount
{
	LOGMETHOD;
	[[self managedObjectContext] processPendingChanges];
	[[self undoManager] removeAllActions];
	[self updateChangeCount:NSChangeCleared];
}

#pragma mark -
#pragma mark Closing Documents

- (void)close
{	
	LOGMETHOD;
    
    
    // Allow anyone interested to know we're closing. e.g. KTDocWebViewController uses this
	[[NSNotificationCenter defaultCenter] postNotificationName:KTDocumentWillCloseNotification object:self];

	
	// Remove temporary media files
	[[self mediaManager] deleteTemporaryMediaFiles];
	
	[super close];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"KTDocumentDidClose" object:self];
}

#pragma mark -
#pragma mark Error Presentation

/*! we override willPresentError: here largely to deal with
	any validation issues when saving the document
 */
- (NSError *)willPresentError:(NSError *)inError
{
	NSError *result = inError;
    
    // customizations for NSCocoaErrorDomain
	if ( [[inError domain] isEqualToString:NSCocoaErrorDomain] ) 
	{
		int errorCode = [inError code];
		
		// is this a Core Data validation error?
		if ( (errorCode >= NSValidationErrorMinimum) && (errorCode <= NSValidationErrorMaximum) ) 
		{
			// If there are multiple validation errors, inError will be a NSValidationMultipleErrorsError
			// and all the validation errors will be in an array in the userInfo dictionary for key NSDetailedErrorsKey
			id detailedErrors = [[inError userInfo] objectForKey:NSDetailedErrorsKey];
			if ( detailedErrors != nil ) 
			{
				unsigned numErrors = [detailedErrors count];							
				NSMutableString *errorString = [NSMutableString stringWithFormat:@"%u validation errors have occurred", numErrors];
				if ( numErrors > 3 )
				{
					[errorString appendFormat:@".\nThe first 3 are:\n"];
				}
				else
				{
					[errorString appendFormat:@":\n"];
				}
				
				unsigned i;
				for ( i = 0; i < ((numErrors > 3) ? 3 : numErrors); i++ ) 
				{
					[errorString appendFormat:@"%@\n", [[detailedErrors objectAtIndex:i] localizedDescription]];
				}
				
				NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[inError userInfo]];
				[userInfo setObject:errorString forKey:NSLocalizedDescriptionKey];
				
				result = [NSError errorWithDomain:[inError domain] code:[inError code] userInfo:userInfo];
			} 
		}
	}
    
    
    return result;
}

#pragma mark -
#pragma mark UI validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	OFF((@"KTDocument validateMenuItem:%@ %@", [menuItem title], NSStringFromSelector([menuItem action])));
	
	// File menu	
	// "Save As..." saveDocumentAs:
	if ( [menuItem action] == @selector(saveDocumentAs:) )
	{
		return YES;
	}
	
	// "Save a Copy As..." saveDocumentTo:
	else if ( [menuItem action] == @selector(saveDocumentTo:) )
	{
		return YES;
	}
	
	return [super validateMenuItem:menuItem]; 
}

#pragma mark -
#pragma mark Actions

- (IBAction)setupHost:(id)sender
{
	KTHostSetupController* sheetController
	= [[KTHostSetupController alloc] initWithHostProperties:[self valueForKeyPath:@"site.hostProperties"]];
		// LEAKING ON PURPOSE, THIS WILL BE AUTORELEASED IN setupHostSheetDidEnd:
	
	[NSApp beginSheet:[sheetController window]
	   modalForWindow:[self windowForSheet]
	modalDelegate:self
	   didEndSelector:@selector(setupHostSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:sheetController];
	[NSApp cancelUserAttentionRequest:NSCriticalRequest];
}


- (void)editSourceObject:(NSObject *)aSourceObject keyPath:(NSString *)aKeyPath  isRawHTML:(BOOL)isRawHTML;
{
	[[self HTMLInspectorController] setHTMLSourceObject:aSourceObject];	// saves will put back into this node
	[[self HTMLInspectorController] setHTMLSourceKeyPath:aKeyPath];
	
	
	NSString *title = @"";
	if (isRawHTML)
	{
		// Get title of page/pagelet we are editing
		if ([aSourceObject respondsToSelector:@selector(titleText)])
		{
			NSString *itsTitle = [((KTAbstractPage *)aSourceObject) titleText];
			if (nil != itsTitle && ![itsTitle isEqualToString:@""])
			{
				title = itsTitle;
			}
		}
	}
	[[self HTMLInspectorController] setTitle:title];
	[[self HTMLInspectorController] setFromEditableBlock:!isRawHTML];

	[[self HTMLInspectorController] showWindow:nil];
}


#pragma mark -
#pragma mark Delegate Methods

- (void)setupHostSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	KTHostSetupController* sheetController = (KTHostSetupController*)contextInfo;
	if (returnCode)
	{
		// init code only for new documents
		NSUndoManager *undoManager = [self undoManager];
		
		//[undoManager beginUndoGrouping];
		//KTStoredDictionary *hostProperties = [[self site] wrappedValueForKey:@"hostProperties"];
		KTHostProperties *hostProperties = [sheetController properties];
		[self setValue:hostProperties forKeyPath:@"site.hostProperties"];

		// For diagnostics, log the value of the host properties
		if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"LogHostInfoToConsole"] )
		{
			NSLog(@"new hostProperties = %@", [[hostProperties hostPropertiesReport] condenseWhiteSpace]);		
		}
		
		// Mark designs and media as stale (pages are handled automatically)
		NSArray *designs = [[self managedObjectContext] allObjectsWithEntityName:@"DesignPublishingInfo" error:NULL];
		[designs setValue:nil forKey:@"versionLastPublished"];
        
        [[[[self site] root] master] setPublishedDesignCSSDigest:nil];
		
		NSArray *media = [[[self mediaManager] managedObjectContext] allObjectsWithEntityName:@"MediaFileUpload" error:NULL];
		[media setBool:YES forKey:@"isStale"];
        
        
        // All page and sitemap URLs are now invalid
        [[[self site] root] recursivelyInvalidateURL:YES];
        [self willChangeValueForKey:@"publishedSitemapURL"];
        [self didChangeValueForKey:@"publishedSitemapURL"];
		
		
		
		[undoManager setActionName:NSLocalizedString(@"Host Settings", @"Undo name")];
				
		// Check encoding from host properties
		// Alas, I have no way to test this!
		
		NSString *hostCharset = [hostProperties valueForKey:@"encoding"];
		if ((nil != hostCharset) && ![hostCharset isEqualToString:@""])
		{
			NSString *rootCharset = [[[[self site] root] master] valueForKey:@"charset"];
			if (![[hostCharset lowercaseString] isEqualToString:[rootCharset lowercaseString]])
			{
				[self performSelector:@selector(warnThatHostUsesCharset:) withObject:hostCharset afterDelay:0.0];
			}
		}
	}
	[sheetController autorelease];
}

- (void)warnThatHostUsesCharset:(NSString *)hostCharset
{
	[KSSilencingConfirmSheet alertWithWindow:[self windowForSheet] silencingKey:@"ShutUpCharsetMismatch" title:NSLocalizedString(@"Host Character Set Mismatch", @"alert title when the character set specified on the host doesn't match settings") format:NSLocalizedString(@"The host you have chosen always serves its text encoded as '%@'.  In order to prevent certain text from appearing incorrectly, we suggest that you set your site's 'Character Encoding' property to match this, using the inspector.",@""), [hostCharset uppercaseString]];
}

#pragma mark -
#pragma mark screenshot for feedback

- (BOOL)mayAddScreenshotsToAttachments;
{
	NSWindow *window = [self windowForSheet];
	return (window && [window isVisible]);
}

//  screenshot1 = document window
//  screenshot2 = document sheet, if any
//  screenshot3 = inspector window, if visible
// alternative: use screencapture to write a jpeg of the entire screen to the user's temp directory

- (void)addScreenshotsToAttachments:(NSMutableArray *)attachments attachmentOwner:(NSString *)attachmentOwner;
{
	
	NSWindow *window = [self windowForSheet];
	NSImage *snapshot = [window snapshotShowingBorder:NO];
	if ( nil != snapshot )
	{
		NSData *snapshotData = [snapshot JPEG2000RepresentationWithQuality:0.40];
		NSString *snapshotName = [NSString stringWithFormat:@"screenshot-%@.jp2", attachmentOwner];
		
		KSFeedbackAttachment *attachment = [KSFeedbackAttachment attachmentWithFileName:snapshotName 
																				   data:snapshotData];
		if (attachment)
		{
			[attachments addObject:attachment];
		}
	}
	
	// Also attach any sheet (host setup, etc.)
	if (nil != [window attachedSheet])
	{
		snapshot = [[window attachedSheet] snapshotShowingBorder:NO];
		if ( nil != snapshot )
		{
			NSData *snapshotData = [snapshot JPEG2000RepresentationWithQuality:0.40];
			NSString *snapshotName = [NSString stringWithFormat:@"sheet-%@.jp2", attachmentOwner];
			
			KSFeedbackAttachment *attachment = [KSFeedbackAttachment attachmentWithFileName:snapshotName data:snapshotData];
			if (attachment)
			{
				[attachments addObject:attachment];
			}
		}
	}
	
	// Attach inspector, if visible
	NSWindowController *sharedController = [[[KSDocumentController sharedDocumentController] inspectors] lastObject];
	if ( nil != sharedController )
	{
		NSWindow *infoWindow = [sharedController window];
		if ( [infoWindow isVisible] )
		{
			snapshot = [infoWindow snapshotShowingBorder:YES];
			if ( nil != snapshot )
			{
				NSData *snapshotData = [snapshot JPEG2000RepresentationWithQuality:0.40];
				NSString *snapshotName = [NSString stringWithFormat:@"inspector-%@.jp2", attachmentOwner];
				
				KSFeedbackAttachment *attachment = [KSFeedbackAttachment attachmentWithFileName:snapshotName data:snapshotData];
				if (attachment)
				{
					[attachments addObject:attachment];
				}
			}
		}
	}
	
}

@end
