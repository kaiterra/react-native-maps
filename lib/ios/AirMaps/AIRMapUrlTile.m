//
//  AIRUrlTileOverlay.m
//  AirMaps
//
//  Created by cascadian on 3/19/16.
//  Copyright © 2016. All rights reserved.
//

#import "AIRMapUrlTile.h"
#import <React/UIView+React.h>

@implementation KTTileOverlay

- (id)initWithURLTemplate:(NSString *)URLTemplate
{
    self = [super initWithURLTemplate:URLTemplate];
    if (self != nil){
        self.downloadQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self.downloadQueue cancelAllOperations];
    self.downloadQueue = nil;
    self.cache = nil;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *data, NSError *error))result
{
    if (!result)
    {
        return;
    }
    
    NSURL *tileURL = [self URLForTilePath:path];
    NSData *cachedData = [self.cache objectForKey:[tileURL absoluteString]];
    if (cachedData)
    {
        result(cachedData, nil);
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        NSURLRequest *request = [NSURLRequest requestWithURL:tileURL];
        [NSURLConnection sendAsynchronousRequest:request queue:self.downloadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSData *resultData = data;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode != 200) {
                    [weakSelf.cache setObject:[NSData data] forKey:[tileURL absoluteString]];
                } else {
                    if (data) {
                        [weakSelf.cache setObject:resultData forKey:[tileURL absoluteString]];
                    }
                    else {
                        resultData = [NSData data];
                        [weakSelf.cache setObject:resultData forKey:[tileURL absoluteString]];
                    }
                }
            } else {
                [weakSelf.cache setObject:resultData forKey:[tileURL absoluteString]];
            }
            result(resultData, connectionError);
        }];
    }
}

@end

@implementation AIRMapUrlTile {
    BOOL _urlTemplateSet;
    BOOL _tileSizeSet;
    BOOL _alphaSet;
}

- (void)dealloc
{
    _cache = nil;
    _tileOverlay = nil;
    _renderer = nil;
}

- (void)setCache:(NSCache *)cache
{
    if (_cache != cache) {
        _cache = cache;
    }
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
    _alpha = alpha;
    _alphaSet = YES;
    [self update];
}

- (void) createTileOverlayAndRendererIfPossible
{
    if (!_urlTemplateSet) return;
    
    self.tileOverlay = [[KTTileOverlay alloc] initWithURLTemplate:self.urlTemplate];
    self.tileOverlay.cache = self.cache;
    
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
    self.renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:self.tileOverlay];
    if (_alphaSet) {
        self.renderer.alpha = _alpha;
    }
}

- (void) update
{
    if (!_renderer) return;
    
    if (_map == nil) return;
    [_map removeOverlay:self];
    if (!_alphaSet || _alpha > 0.0) {
        self.renderer.alpha = _alpha;
        [_map addOverlay:self level:MKOverlayLevelAboveLabels];
    }
    
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
