//
//  AIRUrlTileOverlay.m
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import "AIRMapUrlTile.h"
#import <React/UIView+React.h>

@implementation KTTileOverlayRenderer

/* TODO: should take maximumZ of MKTileOverlay into account. */
- (MKTileOverlayPath)pathForMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale {
    MKTileOverlay *tileOverlay = (MKTileOverlay *)self.overlay;
    CGFloat factor = tileOverlay.tileSize.width / 256;
    MKMapPoint centerPoint;
    
    centerPoint.x = mapRect.origin.x + mapRect.size.width * 0.5 / self.contentScaleFactor;
    centerPoint.y = mapRect.origin.y + mapRect.size.height * 0.5 / self.contentScaleFactor;
    
    NSInteger x = round(centerPoint.x * zoomScale / (tileOverlay.tileSize.width / factor));
    NSInteger y = round(centerPoint.y * zoomScale / (tileOverlay.tileSize.height / factor));
    NSInteger z = log2(zoomScale) + 20;
    
    MKTileOverlayPath path = {
        .x = x,
        .y = y,
        .z = z,
        .contentScaleFactor = self.contentScaleFactor
    };

    return path;
}

- (BOOL)canDrawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale
{
    if (self.useDefaultRenderImplementation) {
        return [super canDrawMapRect:mapRect zoomScale:zoomScale];
    } else {
        __weak typeof(self) weakSelf = self;

        MKTileOverlayPath path = [self pathForMapRect:mapRect zoomScale:zoomScale];
        
        MKTileOverlay *overlay = self.overlay;
        NSURL *url = [overlay URLForTilePath:path];
        id cachedData = [self.cache objectForKey:[url absoluteString]];
        if (cachedData && [cachedData isKindOfClass:[NSData class]] && [cachedData length]) {
            return YES;
        } else {
            if ([cachedData isEqual:[NSNull null]]) {
                return NO;
            } else {
                [self.cache setObject:[NSNull null] forKey:[url absoluteString]];
                [overlay loadTileAtPath:path result:^(NSData * _Nullable tileData, NSError * _Nullable error) {
                    if (tileData && [tileData length]) {
                        [weakSelf.cache setObject:tileData forKey:[url absoluteString]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf setNeedsDisplayInMapRect:mapRect zoomScale:zoomScale];
                        });
                    } else {
                        [weakSelf.cache setObject:[NSNull null] forKey:[url absoluteString]];
                    }
                }];
                return NO;
            }
        }
    }
}

-(void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context
{
    if (self.alpha == 0.0) {
        return;
    }

    if (self.useDefaultRenderImplementation) {
        return [super drawMapRect:mapRect zoomScale:zoomScale inContext:context];
    } else {
        MKTileOverlayPath path = [self pathForMapRect:mapRect zoomScale:zoomScale];
        MKTileOverlay *overlay = (MKTileOverlay *)self.overlay;
        NSURL *url = [overlay URLForTilePath:path];
        CGRect rect = [self rectForMapRect:mapRect];

        if (self.shouldDrawGridLine) {
            UIGraphicsPushContext(context);
            NSString *text = [NSString stringWithFormat:@"Z=%ld\nX=%ld\nY=%ld",(long)path.z,(long)path.x,(long)path.y];
            [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20.0/zoomScale],
                                                   NSForegroundColorAttributeName:[UIColor blackColor]}];
            UIGraphicsPopContext();
        }
        

        BOOL tileDataReady;
        NSData *tileData = [self.cache objectForKey:[url absoluteString]];
        if (!tileData || [tileData isEqual:[NSNull null]]) {
            tileDataReady = NO;
        } else {
            tileDataReady = YES;
        }
        
        if (tileDataReady) {
            CGImageRef imageRef = nil;
            
            CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)tileData);
            if (provider) {
                imageRef = CGImageCreateWithPNGDataProvider(provider, nil, NO, kCGRenderingIntentDefault);
                CGDataProviderRelease(provider);
            }
            if (imageRef) {
                // Render tile image
                CGRect tileRect = CGRectMake(0, 0, overlay.tileSize.width, overlay.tileSize.height);
                UIGraphicsBeginImageContext(tileRect.size);
                CGContextDrawImage(UIGraphicsGetCurrentContext(), tileRect, imageRef);
                CGImageRelease(imageRef);
                CGImageRef flippedImageRef = UIGraphicsGetImageFromCurrentImageContext().CGImage;
                UIGraphicsEndImageContext();
                
                CGContextDrawImage(context, [self rectForMapRect:mapRect], flippedImageRef);
            }
        }
        
        if (self.shouldDrawGridLine) {
            // Stroke rect border.
            CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
            CGContextSetLineWidth(context, 1.0/zoomScale);
            CGContextStrokeRect(context, rect);
        }
    }
}

@end

@implementation AIRMapUrlTile {
    BOOL _urlTemplateSet;
    BOOL _tileSizeSet;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _alpha = 1.0;
        self.cache = [NSCache new];
    }
    return self;
}
- (void)dealloc
{
    [self.cache removeAllObjects];
    self.cache = nil;
    _tileOverlay = nil;
    _renderer = nil;
}

- (void)setShouldReplaceMapContent:(BOOL)shouldReplaceMapContent
{
  _shouldReplaceMapContent = shouldReplaceMapContent;
  if(self.tileOverlay) {
    self.tileOverlay.canReplaceMapContent = _shouldReplaceMapContent;
  }
  [self update];
}

- (void)setMaximumZ:(NSUInteger)maximumZ
{
  _maximumZ = maximumZ;
  if(self.tileOverlay) {
    self.tileOverlay.maximumZ = _maximumZ;
  }
  [self update];
}

- (void)setMinimumZ:(NSUInteger)minimumZ
{
  _minimumZ = minimumZ;
  if(self.tileOverlay) {
    self.tileOverlay.minimumZ = _minimumZ;
  }
  [self update];
}

- (void)setUrlTemplate:(NSString *)urlTemplate{
    if (![urlTemplate isEqualToString:_urlTemplate]) {
        _urlTemplate = urlTemplate;
        _urlTemplateSet = YES;
        [self createTileOverlayAndRendererIfPossible];
        [self update];
    }
}

- (void)setTileSize:(CGFloat)tileSize{
    _tileSize = tileSize;
    _tileSizeSet = YES;
    [self createTileOverlayAndRendererIfPossible];
    [self update];
}

- (void)setAlpha:(CGFloat)alpha
{
    if (_alpha != alpha) {
        _alpha = alpha;
        [self update];
    }
}

- (void)setShouldDrawGridLine:(BOOL)shouldDrawGridline
{
    _shouldDrawGridLine = shouldDrawGridline;
    if (self.renderer) {
        self.renderer.shouldDrawGridLine = shouldDrawGridline;
    }
    [self update];
}

- (void) createTileOverlayAndRendererIfPossible
{
    if (!_urlTemplateSet) return;
    
    self.tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:self.urlTemplate];
    self.tileOverlay.canReplaceMapContent = self.shouldReplaceMapContent;

    if(self.minimumZ) {
        self.tileOverlay.minimumZ = self.minimumZ;
    }
    if (self.maximumZ) {
        self.tileOverlay.maximumZ = self.maximumZ;
    }
    if (_tileSizeSet) {
        self.tileOverlay.tileSize = CGSizeMake(self.tileSize, self.tileSize);
    }
    if (self.renderer.alpha != self.alpha) {
        self.renderer.alpha = self.alpha;
    }
    self.renderer = [[KTTileOverlayRenderer alloc] initWithTileOverlay:self.tileOverlay];
    self.renderer.cache = self.cache;
    self.renderer.useDefaultRenderImplementation = NO;
    self.renderer.shouldDrawGridLine = self.shouldDrawGridLine;
}

- (void) update
{
    if (!_renderer) return;
    if (self.renderer.alpha != self.alpha) {
        self.renderer.alpha = self.alpha;
    }
    if (_map == nil) return;
    
    [_map removeOverlay:self];
    [_map addOverlay:self level:MKOverlayLevelAboveLabels];
    
    for (id<MKOverlay> overlay in _map.overlays) {
        if ([overlay isKindOfClass:[AIRMapUrlTile class]]) {
            continue;
        }
        [_map removeOverlay:overlay];
        [_map addOverlay:overlay];
    }
}

#pragma mark MKOverlay implementation

- (CLLocationCoordinate2D) coordinate
{
    return self.tileOverlay.coordinate;
}

- (MKMapRect) boundingMapRect
{
    return self.tileOverlay.boundingMapRect;
}

- (BOOL)canReplaceMapContent
{
    return self.tileOverlay.canReplaceMapContent;
}

@end
