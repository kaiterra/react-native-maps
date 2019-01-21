//
//  AIRMapUrlTileManager.m
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTViewManager.h>
#import <React/UIView+React.h>
#import "AIRMapMarker.h"
#import "AIRMapUrlTile.h"

#import "AIRMapUrlTileManager.h"

@implementation AIRMapUrlTileManager


RCT_EXPORT_MODULE()

- (UIView *)view
{
    AIRMapUrlTile *tile = [AIRMapUrlTile new];
    tile.bridge = self.bridge;
    return tile;
}

RCT_EXPORT_VIEW_PROPERTY(backgroundTile,BOOL)
RCT_EXPORT_VIEW_PROPERTY(urlTemplate, NSString)
RCT_EXPORT_VIEW_PROPERTY(maximumZ, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(minimumZ, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(shouldReplaceMapContent, BOOL)
RCT_EXPORT_VIEW_PROPERTY(tileSize, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(alpha, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(shouldDrawGridLine, BOOL)

@end
