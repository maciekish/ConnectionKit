//
//  SVGraphicFactory.m
//  Sandvox
//
//  Created by Mike on 04/04/2010.
//  Copyright 2010 Karelia Software. All rights reserved.
//

#import "SVGraphicFactory.h"

#import "KTDataSourceProtocol.h"
#import "KTElementPlugInWrapper.h"
#import "SVImage.h"
#import "SVMediaRecord.h"
#import "SVVideo.h"
#import "SVAudio.h"
#import "SVFlash.h"
#import "SVPlugIn.h"
#import "SVRawHTMLGraphic.h"
#import "SVTextBox.h"
#import "KTToolbars.h"

#import "KSSortedMutableArray.h"
#import "KSWebLocation.h"

#import "NSArray+Karelia.h"
#import "NSMenuItem+Karelia.h"
#import "NSSet+Karelia.h"
#import "NSImage+Karelia.h"

#import "Registration.h"


@interface SVTextBoxFactory : SVGraphicFactory
@end


@implementation SVTextBoxFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    OBPRECONDITION(context);
	
	
    // Create the pagelet
	SVTextBox *result = [NSEntityDescription insertNewObjectForEntityForName:@"TextBox"
													  inManagedObjectContext:context];
	OBASSERT(result);
    
    
    // Give title & text
    [result setTitle:NSLocalizedString(@"Untitled Text", "Text Box title")];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"loremipsum2" ofType:@"html"];
    [[result body] setString:[NSString stringWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:NULL]];
	
    
	return result;
}

- (NSString *)name { return TOOLBAR_INSERT_TEXT_BOX; }	// from a localized string macro

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_text"];
}

- (NSUInteger)priority; { return 1; }

@end


#pragma mark -


@interface SVImageFactory : SVGraphicFactory
@end


@implementation SVImageFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVMediaGraphic *result = [SVMediaGraphic insertNewGraphicInManagedObjectContext:context];
    [result setTitle:NSLocalizedString(@"Photo", "pagelet title")];
    [result setIsMediaPlaceholder:[NSNumber numberWithBool:YES]];
    
    return result;
}

- (NSString *)name { return NSLocalizedString(@"Media Placeholder", @"name of object to insert"); }

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_image"];
}

- (NSString *)identifier { return @"com.karelia.Sandvox.Image"; }

- (Class)plugInClass { return [SVImage class]; }

- (NSUInteger)priority; { return 1; }

- (NSArray *)readablePasteboardTypes;
{
    NSArray *result = [KSWebLocation webLocationPasteboardTypes];
    result = [result arrayByAddingObjectsFromArray:[NSImage imagePasteboardTypes]];
    return result;
}

- (SVPlugInPasteboardReadingOptions)readingOptionsForType:(NSString *)type
                                               pasteboard:(NSPasteboard *)pasteboard;
{
    SVPlugInPasteboardReadingOptions result = SVPlugInPasteboardReadingAsData;
    
    if ([[KSWebLocation webLocationPasteboardTypes] containsObject:type])
    {
        result = SVPlugInPasteboardReadingAsWebLocation;
    }
    
    return result;
}

- (SVGraphic *)graphicWithPasteboardContents:(id)contents
                                      ofType:(NSString *)type
              insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVImage *result = [SVImage insertNewGraphicInManagedObjectContext:context];
    [result awakeFromPasteboardContents:contents ofType:type];
    return result;
}

@end


#pragma mark -


@interface SVVideoFactory : SVGraphicFactory
@end


@implementation SVVideoFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVVideo *result = [SVVideo insertNewGraphicInManagedObjectContext:context];
    [result setWidth:[NSNumber numberWithUnsignedInt:200]];
    [result setHeight:[NSNumber numberWithUnsignedInt:150]];	// typical TV aspect ratio
    [result setIsMediaPlaceholder:[NSNumber numberWithBool:YES]];
    
    return result;
}

- (NSString *)name { return NSLocalizedString(@"Video", @"name of object to insert"); }

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_video"];
}

@end


#pragma mark -


@interface SVAudioFactory : SVGraphicFactory
@end


@implementation SVAudioFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVAudio *result = [SVAudio insertNewGraphicInManagedObjectContext:context];
    [result setWidth:[NSNumber numberWithUnsignedInt:200]];
    [result setHeight:[NSNumber numberWithUnsignedInt:25]];		// height of audio tag
    [result setIsMediaPlaceholder:[NSNumber numberWithBool:YES]];
    
    return result;
}

- (NSString *)name { return NSLocalizedString(@"Audio", @"name of object to insert"); }

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_audio"];
}

@end


#pragma mark -

@interface SVFlashFactory : SVGraphicFactory
@end


@implementation SVFlashFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVFlash *result = [SVFlash insertNewGraphicInManagedObjectContext:context];
    [result setWidth:[NSNumber numberWithUnsignedInt:200]];
    [result setHeight:[NSNumber numberWithUnsignedInt:150]];	// typical TV aspect ratio
    [result setIsMediaPlaceholder:[NSNumber numberWithBool:YES]];
    
    return result;
}

- (NSString *)name { return NSLocalizedString(@"Flash", @"name of object to insert"); }

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_flash"];
}

@end


#pragma mark -



@interface SVRawHTMLFactory : SVGraphicFactory
@end


@implementation SVRawHTMLFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVRawHTMLGraphic *result = [NSEntityDescription insertNewObjectForEntityForName:@"RawHTMLGraphic" inManagedObjectContext:context];
    
    [result setHTMLString:@"<span>[[RAW HTML]]</span>"];
    
    return result;
}

- (NSString *)name { return NSLocalizedString(@"Raw HTML", @"name of object to insert"); }

- (NSImage *)icon
{
    return [NSImage imageNamed:@"toolbar_html_element"];
}

@end


#pragma mark -


@implementation SVGraphicFactory

#pragma mark Factory Registration

static NSPointerArray       *sFactories;
static NSMutableDictionary  *sFactoriesByIdentifier;

+ (NSArray *)registeredFactories;
{
    return [sFactories allObjects];
}

+ (SVGraphicFactory *)factoryWithIdentifier:(NSString *)identifier;
{
    SVGraphicFactory *result = [sFactoriesByIdentifier objectForKey:identifier];
    return result;
}

+ (SVGraphicFactory *)graphicFactoryForTag:(NSInteger)tag;
{
    return [sFactories pointerAtIndex:tag];
}

+ (NSInteger)tagForFactory:(SVGraphicFactory *)factory;
{
    // Have to hunt through for index/tag of factory
    NSInteger result = 0;
    for (SVGraphicFactory *aFactory in sFactories)
    {
        if (aFactory == factory) break;
        result++;
    }
    
    // This would happen if factory wasn't found
    if (result >= [sFactories count]) result = 0;
    
    return result;
}

+ (void)registerFactory:(SVGraphicFactory *)factory;
{
    OBPRECONDITION(factory);
    [sFactories addPointer:factory];
    if ([factory identifier]) [sFactoriesByIdentifier setObject:factory forKey:[factory identifier]];
}

#pragma mark Shared Objects

static SVGraphicFactory *sSharedTextBoxFactory;
static SVGraphicFactory *sImageFactory;
static SVGraphicFactory *sVideoFactory;
static SVGraphicFactory *sAudioFactory;
static SVGraphicFactory *sFlashFactory;
static KSSortedMutableArray *sIndexFactories;
static KSSortedMutableArray *sBadgeFactories;
static KSSortedMutableArray *sEmbeddedFactories;
static KSSortedMutableArray *sSocialFactories;
static KSSortedMutableArray *sMoreFactories;
static SVGraphicFactory *sRawHTMLFactory;

+ (void)initialize
{
    if (!sFactories) sFactories = [[NSPointerArray pointerArrayWithStrongObjects] retain];
    if (!sFactoriesByIdentifier) sFactoriesByIdentifier = [[NSMutableDictionary alloc] init];
    
    
    // Special factories!
    if (!sSharedTextBoxFactory)
    {
        sSharedTextBoxFactory = [[SVTextBoxFactory alloc] init];
        [self registerFactory:sSharedTextBoxFactory];
    }
    
    if (!sImageFactory)
    {
        sImageFactory = [[SVImageFactory alloc] init];
        [self registerFactory:sImageFactory];
    }
    
    if (!sVideoFactory)
    {
        sVideoFactory = [[SVVideoFactory alloc] init];
        [self registerFactory:sVideoFactory];
    }
	if (!sAudioFactory)
    {
        sAudioFactory = [[SVAudioFactory alloc] init];
        [self registerFactory:sAudioFactory];
    }
	if (!sFlashFactory)
    {
        sFlashFactory = [[SVFlashFactory alloc] init];
        [self registerFactory:sFlashFactory];
    }
	
    if (!sRawHTMLFactory)
    {
        sRawHTMLFactory = [[SVRawHTMLFactory alloc] init];
        [self registerFactory:sRawHTMLFactory];
    }
    
    
    
    // Create standard groups of factories
    if (!sIndexFactories &&
        !sBadgeFactories &&
        !sEmbeddedFactories &&
        !sSocialFactories &&
        !sMoreFactories)
    {
        // Order plug-ins first by priority, then by name
        //      I've turned off priority support for now to try a pure alphabetical approach - Mike
        //NSSortDescriptor *prioritySort = [[NSSortDescriptor alloc] initWithKey:@"priority"
        //                                                             ascending:YES];
        NSSortDescriptor *nameSort = [[NSSortDescriptor alloc]
                                      initWithKey:@"name"
                                      ascending:YES
                                      selector:@selector(caseInsensitiveCompare:)];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:/*prioritySort, */nameSort, nil];
        //[prioritySort release];
        [nameSort release];
        
        
        // Iterate the pagelets filing them away
        sIndexFactories = [[KSSortedMutableArray alloc] initWithSortDescriptors:sortDescriptors];
        sBadgeFactories = [[KSSortedMutableArray alloc] initWithSortDescriptors:sortDescriptors];
        sEmbeddedFactories = [[KSSortedMutableArray alloc] initWithSortDescriptors:sortDescriptors];
        sSocialFactories = [[KSSortedMutableArray alloc] initWithSortDescriptors:sortDescriptors];
        sMoreFactories = [[KSSortedMutableArray alloc] initWithSortDescriptors:sortDescriptors];
        
        
        for (KTElementPlugInWrapper *aWrapper in [KTElementPlugInWrapper pageletPlugins])
        {
            switch ([aWrapper category])
            {
                case KTPluginCategoryIndex:
                    [sIndexFactories addObject:[aWrapper graphicFactory]];
                    break;
                /*case KTPluginCategoryBadge:
                    [sBadgeFactories addObject:[aWrapper graphicFactory]];
                    break;
                case KTPluginCategoryEmbedded:
                    [sEmbeddedFactories addObject:[aWrapper graphicFactory]];
                    break;
                case KTPluginCategorySocial:
                    [sSocialFactories addObject:[aWrapper graphicFactory]];
                    break;*/
                default:
                    [sMoreFactories addObject:[aWrapper graphicFactory]];
                    break;
            }
            
            [self registerFactory:[aWrapper graphicFactory]];
        }
    }
}

+ (NSArray *)indexFactories; { return [[sIndexFactories copy] autorelease]; }
+ (NSArray *)badgeFactories; { return [[sBadgeFactories copy] autorelease]; }
+ (NSArray *)embeddedFactories; { return [[sEmbeddedFactories copy] autorelease]; }
+ (NSArray *)socialFactories; { return [[sSocialFactories copy] autorelease]; }
+ (NSArray *)moreGraphicFactories; { return [[sMoreFactories copy] autorelease]; }

+ (SVGraphicFactory *)textBoxFactory; { return sSharedTextBoxFactory; }

+ (SVGraphicFactory *)mediaPlaceholderFactory; { return sImageFactory; }
+ (SVGraphicFactory *)videoFactory; { return sVideoFactory; }
+ (SVGraphicFactory *)audioFactory; { return sAudioFactory; }
+ (SVGraphicFactory *)flashFactory; { return sFlashFactory; }

+ (NSArray *)mediaFactories;
{
    return [NSArray arrayWithObjects:
            [self mediaPlaceholderFactory],
            [self videoFactory],
            [self audioFactory],
            [self flashFactory], nil];
}

+ (SVGraphicFactory *)rawHTMLFactory; { return sRawHTMLFactory; }

#pragma mark Menu

// nil targeted actions will be sent to firstResponder (the active document)
// representedObject is the factory
+ (void)insertItemsWithGraphicFactories:(NSArray *)factories
                                 inMenu:(NSMenu *)menu
                                atIndex:(NSUInteger)index;
{	
    for (SVGraphicFactory *factory in factories)
	{
		NSMenuItem *menuItem = [factory makeMenuItem];
		[menu insertItem:menuItem atIndex:index];   index++;
	}
}

- (NSMenuItem *)makeMenuItem;
{
    NSMenuItem *result = [[[NSMenuItem alloc] init] autorelease];
    
    
    // Tag
    [result setTag:[SVGraphicFactory tagForFactory:self]];
    
    
    // Name
    NSString *pluginName = [self name];
    if (![pluginName length])
    {
        NSLog(@"empty plugin name for %@", self);
        pluginName = @"";
    }
    [result setTitle:pluginName];
    
    
    // Icon
    //if (image)
    {
        NSImage *icon = [[self icon] copy];
#ifdef DEBUG
        if (!icon) NSLog(@"nil pluginIcon for %@", pluginName);
#endif
        
        [icon setSize:NSMakeSize(32.0f, 32.0f)];
        [result setImage:icon];
        [icon release];
    }
    
    
    // Pro status
    if (9 == [self priority] && nil == gRegistrationString)
    {
        [result setPro:YES];
    }
    
    
    
    [result setRepresentedObject:self];
    
    
    // set target/action
    [result setAction:@selector(insertPagelet:)];
    
    
    return result;
}

+ (NSMenuItem *)menuItemWithGraphicFactories:(NSArray *)factories title:(NSString *)title;
{
    NSMenuItem *result = [[NSMenuItem alloc] initWithTitle:title
													action:nil
											 keyEquivalent:@""];
    
    NSMenu *submenu = [[NSMenu alloc] initWithTitle:title];
    
    [SVGraphicFactory insertItemsWithGraphicFactories:factories
                                               inMenu:submenu
                                              atIndex:0];
	[result setSubmenu:submenu];
    [submenu release];
    
    return [result autorelease];
}

+ (SVGraphic *)graphicWithActionSender:(id <NSValidatedUserInterfaceItem>)sender
        insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVGraphicFactory *factory = [self graphicFactoryForTag:[sender tag]];
    SVGraphic *result = [factory insertNewGraphicInManagedObjectContext:context];
    
    [result setShowsTitle:YES]; // default is NO in the mom to account for inline images
    return result;
}

#pragma mark Pasteboard

+ (NSArray *)graphicsFomPasteboard:(NSPasteboard *)pasteboard
    insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVGraphic *graphic = [self graphicFromPasteboard:pasteboard
                      insertIntoManagedObjectContext:context];
    
    NSArray *result = (graphic) ? [NSArray arrayWithObject:graphic] : nil;
    return result;
}

+ (id)contentsOfPasteboard:(NSPasteboard *)pasteboard forType:(NSString *)type forFactory:(SVGraphicFactory *)aFactory;
{
    // What should I read off the pasteboard?
    id result;
    
    SVPlugInPasteboardReadingOptions readingOptions = SVPlugInPasteboardReadingAsData;
    if ([aFactory respondsToSelector:@selector(readingOptionsForType:pasteboard:)])
    {
        readingOptions = [aFactory readingOptionsForType:type pasteboard:pasteboard];
    }
    
    if (readingOptions & SVPlugInPasteboardReadingAsPropertyList)
    {
        result = [pasteboard propertyListForType:type];
    }
    else if (readingOptions & SVPlugInPasteboardReadingAsString)
    {
        result = [pasteboard stringForType:type];
    }
    else if (readingOptions & SVPlugInPasteboardReadingAsWebLocation)
    {
        result = [[pasteboard readWebLocations] firstObjectKS];
    }
    else
    {
        result = [pasteboard dataForType:type];
    }
    
    return result;
}

+ (NSUInteger)priorityForFactory:(SVGraphicFactory *)aFactory
                      pasteboard:(NSPasteboard *)pasteboard
                            type:(NSString **)outType
                        contents:(id *)outPboardContents;
{
    NSUInteger result = 0;
    
    
    NSString *type = [pasteboard availableTypeFromArray:[aFactory readablePasteboardTypes]];
    if (type)
    {
        @try    // talking to a plug-in so might fail
        {
            id propertyList = [self contentsOfPasteboard:pasteboard
                                                 forType:type
                                              forFactory:aFactory];
            
            if (propertyList)
            {
                result = [aFactory readingPriorityForPasteboardContents:propertyList
                                                                 ofType:type];
                
                if (result)
                {
                    // Pass back out results
                    if (outType) *outType = type;
                    if (outPboardContents) *outPboardContents = propertyList;
                }
            }
        }
        @catch (NSException *exception)
        {
            // TODO: Log warning
        }
    }
    
    
    return result;
}

+ (SVGraphic *)graphicFromPasteboard:(NSPasteboard *)pasteboard
      insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    SVGraphicFactory *factory = nil;
    id pasteboardContents;
    NSString *pasteboardType;
    NSUInteger readingPriority = 0;
    
    
    // Test plug-ins
    for (SVGraphicFactory *aFactory in [self registeredFactories])
    {
        NSString *type;
        id propertyList;
        NSUInteger priority = [self priorityForFactory:aFactory
                                            pasteboard:pasteboard
                                                  type:&type
                                              contents:&propertyList];
        
        if (priority > readingPriority)
        {
            factory = aFactory;
            pasteboardContents = propertyList;
            pasteboardType = type;
            readingPriority = priority;
        }
    }
    
    
    
    // Test image
    NSString *type;
    id propertyList;
    NSUInteger priority = [self priorityForFactory:[self mediaPlaceholderFactory]
                                        pasteboard:pasteboard
                                              type:&type
                                          contents:&propertyList];
    
    if (priority > readingPriority)
    {
        factory = [self mediaPlaceholderFactory];
        pasteboardContents = propertyList;
        pasteboardType = type;
        readingPriority = priority;
    }
    
    
    
    
    
    // Try to create plug-in from pasteboard contents
    if (factory)
    {        
        SVGraphic *result = [factory graphicWithPasteboardContents:pasteboardContents
                                                            ofType:pasteboardType
                                    insertIntoManagedObjectContext:context];
        
        return result;
    }
    
    
    
    return nil;
}

/*! returns unionSet of acceptedDragTypes from all known KTDataSources */
+ (NSArray *)graphicPasteboardTypes;
{
    static NSMutableArray *result;
	
    if (!result)
    {
        result = [[NSMutableArray alloc] init];
        
        for (SVGraphicFactory *aFactory in [self registeredFactories])
        {
            NSArray *acceptedTypes = [aFactory readablePasteboardTypes];
            for (NSString *aType in acceptedTypes)
            {
                if (![result containsObject:aType]) [result addObject:aType];
            }
        }
	}
    
    return result;
}

#pragma mark SVGraphicFactory

- (SVGraphic *)insertNewGraphicInManagedObjectContext:(NSManagedObjectContext *)context;
{
    return nil;
}

- (NSString *)name { SUBCLASSMUSTIMPLEMENT; return nil; }
- (NSImage *)icon { return nil; }
- (NSUInteger)priority; { return 5; }

- (BOOL)isIndex; { return NO; }

- (NSString *)identifier { return nil; }
- (Class)plugInClass; { return nil; }

#pragma mark Pasteboard

- (NSArray *)readablePasteboardTypes; { return nil; }

- (SVPlugInPasteboardReadingOptions)readingOptionsForType:(NSString *)type
                                               pasteboard:(NSPasteboard *)pasteboard;
{
    return 0;
}

- (NSUInteger)readingPriorityForPasteboardContents:(id)contents ofType:(NSString *)type;
{
    return KTSourcePriorityIdeal;
}

- (SVGraphic *)graphicWithPasteboardContents:(id)contents
                                      ofType:(NSString *)type
              insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    return nil;
}

@end
