// 
//  SVPageletBody.m
//  Sandvox
//
//  Created by Mike on 18/11/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import "SVBody.h"

#import "SVPagelet.h"
#import "SVBodyElement.h"
#import "SVBodyTextDOMController.h"

#import "NSArray+Karelia.h"
#import "NSError+Karelia.h"
#import "NSSet+Karelia.h"
#import "NSSortDescriptor+Karelia.h"


@interface SVBody ()
@end

@interface SVBody (CoreDataGeneratedAccessors)
- (void)addElementsObject:(SVBodyElement *)value;
- (void)removeElementsObject:(SVBodyElement *)value;
- (void)addElements:(NSSet *)value;
- (void)removeElements:(NSSet *)value;
@end


#pragma mark -


@implementation SVBody 

#pragma mark Init

+ (SVBody *)insertPageBodyIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"PageBody"
                                         inManagedObjectContext:context];
}

+ (SVBody *)insertPageletBodyIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"TextBoxBody"
                                         inManagedObjectContext:context];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    
    // Should we take the opportinity to create a starter paragraph?
}

#pragma mark Elements

+ (NSArray *)orderedElementsWithElements:(NSSet *)elements
{
    static NSArray *sortDescriptors;
    if (!sortDescriptors)
    {
        sortDescriptors = [NSSortDescriptor sortDescriptorArrayWithKey:@"sortKey" ascending:YES];
        [sortDescriptors retain];
    }
    
    NSArray *result = [elements KS_sortedArrayUsingDescriptors:sortDescriptors];
    return result;
}

@dynamic elements;
- (BOOL)validateElements:(NSSet **)elements error:(NSError **)error
{
    //  The set is only valid if it matches up to the ordered version. i.e. want to make sure nothing in the set is orphaned from the link list.
    BOOL result = YES;
    
    NSUInteger expectedCount = [[[self class] orderedElementsWithElements:*elements] count];
    if ([*elements count] > expectedCount)
    {
        result = NO;
        
        if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:NSValidationRelationshipExceedsMaximumCountError
                                localizedDescription:@"There are more objects in elements than expected, suggesting some elements have been removed from the linked list, but not the relationship."];
    }
    else if ([*elements count] < expectedCount)
    {
        result = NO;
        
        if (error) *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:NSValidationRelationshipLacksMinimumCountError
                                localizedDescription:@"There are fewer objects in elements than expected, suggesting some elements have been inserted into the linked list, but not the relationship."];
    }
    
    return result;
}

- (NSArray *)orderedElements;
{
    NSArray *result = [[self class] orderedElementsWithElements:[self elements]];
    return result;
}

- (void)addElement:(SVBodyElement *)element;
{
    SVBodyElement *lastElement = [[self orderedElements] lastObject];
    [element setSortKey:[NSNumber numberWithShort:[[lastElement sortKey] shortValue] + 1]];
    [self addElementsObject:element];
}

- (NSSet *)graphics;
{
    // Just those elements that are graphics
    NSMutableSet *result = [NSMutableSet set];
    for (SVBodyElement *anElement in [self elements])
    {
        if ([anElement isKindOfClass:[SVGraphic class]]) [result addObject:anElement];
    }
    
    return result;
}

#pragma mark HTML

- (void)writeHTML
{
    //  Piece together each of our elements to generate the HTML
    [[self class] writeContentObjects:[self orderedElements]];
}

#pragma mark Editing

- (Class)DOMControllerClass; { return [SVBodyTextDOMController class]; }

@end
