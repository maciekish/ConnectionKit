//
//  SVPagelet.h
//  Sandvox
//
//  Created by Mike on 11/10/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@class SVPageletBody;
@class KTPage, SVSidebar;


@interface SVPagelet : NSManagedObject  
{
}

+ (SVPagelet *)pageletWithPage:(KTPage *)page;

@property(nonatomic, retain) NSString *elementID;
@property(nonatomic, retain) NSString *titleHTMLString;
@property(nonatomic, retain, readonly) SVPageletBody *body;

@property(nonatomic, readonly) NSSet *sidebars;
@property(nonatomic, copy) NSNumber *sidebarSortKey;    // should have no need to access this directly

@end



