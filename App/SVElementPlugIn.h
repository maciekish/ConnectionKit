//
//  SVContentPlugIn.h
//  Sandvox
//
//  Created by Mike on 20/10/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SVElementPlugIn;
@protocol SVElementPlugInFactory
+ (SVElementPlugIn *)elementPlugInWithArguments:(NSDictionary *)propertyStorage;
@end


#pragma mark -


@class KTPage;
@protocol SVPage, SVElementPlugInContainer;


@interface SVElementPlugIn : NSObject <SVElementPlugInFactory>
{
  @private
    id <SVElementPlugInContainer>   _container;
    
    id  _delegateOwner;
}

- (id)initWithArguments:(NSDictionary *)storage;


// Default implementation generates a <span> or <div> (with an appropriate id) that contains the result of -writeInnerHTML. There is generally NO NEED to override this, and if you do, you MUST write HTML with an enclosing element of the specified ID.
- (void)writeHTML;
@property(nonatomic, readonly) NSString *elementID;

// Default implementation parses the template specified in Info.plist
- (void)writeInnerHTML;


#pragma mark Storage

/*
 Returns the list of KVC keys representing the internal settings of the plug-in. At the moment you must override it in all plug-ins that have some kind of storage, but at some point I'd like to make it automatically read the list in from bundle's Info.plist.
 This list of keys is used for automatic serialization of these internal settings.
 */
+ (NSSet *)plugInKeys;

/*
 Override these methods if the plug-in needs to handle internal settings of an unusual type (typically if the result of -valueForKey: does not conform to the <NSCoding> protocol).
 The serialized object must be a non-container Plist compliant object i.e. exclusively NSString, NSNumber, NSDate, NSData.
 The default implementation of -serializedValueForKey: calls -valueForKey: to retrieve the value for the key, then does nothing for NSString, NSNumber, NSDate and uses <NSCoding> encoding for others.
 The default implementation of -setSerializedValue:forKey calls -setValue:forKey: after decoding the serialized value if necessary.
 */
- (id)serializedValueForKey:(NSString *)key;
- (void)setSerializedValue:(id)serializedValue forKey:(NSString *)key;

/*  FAQ:    How do I reference a page from a plug-in?
 *
 *      Once you've gotten hold of an SVPage object, it's fine to hold it in memory like any other object; just shove it in an instance variable and retain it. You should then also observe SVPageWillBeDeletedNotification and use it discard your reference to the page, as it will become invalid ater that.
 *      To persist your reference to the page, override -serializedValueForKey: to use the page's -identifier property. Likewise, override -setSerializedValue:forKey: to take the serialized ID string and convert it back into a SVPage using -pageWithIdentifier:
 *      All of these methods are documented in SVPageProtocol.h
 */


#pragma mark The Wider World

@property(nonatomic, readonly) NSBundle *bundle;    // the object representing the plug-in's bundle

- (id <SVPage>)page;   // TODO: define a SVPage protocol


#pragma mark Undo Management
// TODO: Should these be methods on some kind of SVPlugInHost or SVPlugInManager object?
- (void)disableUndoRegistration;
- (void)enableUndoRegistration;


#pragma mark UI

// If your plug-in wants an inspector, override to return an SVInspectorViewController subclass. Default implementation returns nil.
+ (Class)inspectorViewControllerClass;

// Return a subclass of SVDOMController. Default implementation returns SVDOMController.
+ (Class)DOMControllerClass;


#pragma mark Registration
// Plug-ins normally get registered automatically from searching the bundles, but you could perhaps register additional classes manually
//+ (void)registerClass:(Class)plugInClass;


#pragma mark Other

@property(nonatomic, retain, readonly) id <SVElementPlugInContainer> elementPlugInContainer;

// Legacy I'd like to get rid of
- (void)awakeFromBundleAsNewlyCreatedObject:(BOOL)isNewlyCreatedObject;

@end
