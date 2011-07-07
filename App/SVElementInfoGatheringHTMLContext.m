//
//  SVElementInfoGatheringHTMLContext.m
//  Sandvox
//
//  Created by Mike on 07/07/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "SVElementInfoGatheringHTMLContext.h"


@implementation SVElementInfoGatheringHTMLContext

- (id) initWithOutputWriter:(id <KSWriter>)output;
{
    if (self = [super initWithOutputWriter:output])
    {
        _topLevelElements = [[NSMutableArray alloc] init];
        _openElementInfos = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)close;
{
    [super close];
    
    [_openElementInfos release]; _openElementInfos = nil;   // so more can't be added
}

- (void)dealloc;
{
    [_topLevelElements release];
    // _openElementInfos is handled by super calling through to -close
    
    [super dealloc];
}

#pragma mark Elements

- (NSArray *)topLevelElements; { return [[_topLevelElements copy] autorelease]; }
- (SVElementInfo *)currentElement; { return [_openElementInfos lastObject]; }

- (void)willStartElement:(NSString *)element;
{
    // Let superclasses queue up any last minute stuff as they like
    [super willStartElement:element];
    
    
    // Stash a copy of the element
    if (_openElementInfos)
    {
        SVElementInfo *info = [[SVElementInfo alloc] initWithElementInfo:[self currentElementInfo]];
        [info setName:element];
        
        [[self currentElement] addSubelement:info];
        [_openElementInfos addObject:info];
        if ([_openElementInfos count] == 1) [_topLevelElements addObject:info];
        
        [info release];
    }
}

- (void)endElement
{
    [super endElement];
    [_openElementInfos removeLastObject];
}

@end


#pragma mark -


@implementation SVElementInfo

- (id)init
{
    if (self = [super init])
    {
        _subelements = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc;
{
    [_subelements release];
    [super dealloc];
}

- (NSArray *)subelements; { return [[_subelements copy] autorelease]; }

- (void)addSubelement:(KSElementInfo *)element;
{
    [_subelements addObject:element];
}

@end
