//
//  AIRUrlTileOverlay.h
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

#import <React/RCTComponent.h>
#import <React/RCTView.h>
#import "AIRMapCoordinate.h"
#import "AIRMap.h"
#import "RCTConvert+AirMap.h"

@class AIRMapUrlTile;

@interface KTTileOverlayRenderer : MKTileOverlayRenderer
@property (nonatomic, strong) NSCache *cache;
@property BOOL useDefaultRenderImplementation;
@property BOOL shouldDrawGridLine;
@end

@interface AIRMapUrlTile : MKAnnotationView <MKOverlay>

@property (nonatomic, weak) AIRMap *map;

@property (nonatomic, strong) MKTileOverlay *tileOverlay;
@property (nonatomic, strong) KTTileOverlayRenderer *renderer;
@property (nonatomic, copy) NSString *urlTemplate;
@property (nonatomic, strong) NSCache *cache;
@property NSInteger maximumZ;
@property NSInteger minimumZ;
@property BOOL shouldReplaceMapContent;
@property BOOL shouldDrawGridLine;
@property CGFloat tileSize;
@property CGFloat alpha;

#pragma mark MKOverlay protocol

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) MKMapRect boundingMapRect;
//- (BOOL)intersectsMapRect:(MKMapRect)mapRect;
- (BOOL)canReplaceMapContent;

@end
