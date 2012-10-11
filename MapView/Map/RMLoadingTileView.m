//
//  RMTileLoadingView.m
//  MapView
//
//  Created by Justin R. Miller on 8/15/12.
//  Copyright 2012 MapBox.
//

#import "RMLoadingTileView.h"

@implementation RMLoadingTileView
{
    UIView *_contentView;
}

@synthesize mapZooming=_mapZooming;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        RMRequireAsset(@"LoadingTile.png");
        RMRequireAsset(@"LoadingTileZoom.png");

        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width * 3, frame.size.height * 3)];
        [self addSubview:_contentView];

        [self setMapZooming:YES];
        
        self.userInteractionEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
    }
    
    return self;
}

- (void)dealloc
{
     _contentView = nil;
}

- (void)setMapZooming:(BOOL)zooming
{
    if (zooming)
    {
        _contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoadingTileZoom.png"]];
    }
    else
    {
        _contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoadingTile.png"]];
        
        _contentView.frame = CGRectMake(0, 0, self.frame.size.width * 3, self.frame.size.height * 3);
        self.contentSize = _contentView.bounds.size;
        self.contentOffset = CGPointMake(self.frame.size.width, self.frame.size.height);
    }
    
    _mapZooming = zooming;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    CGPoint newContentOffset = contentOffset;
    
    if (newContentOffset.x > 2 * self.contentSize.width / 3)
    {
        newContentOffset.x = self.bounds.size.width;
    }
    else if (newContentOffset.x < self.contentSize.width / 3)
    {
        newContentOffset.x = self.bounds.size.width * 2;
    }

    if (newContentOffset.y > 2 * self.contentSize.height / 3)
    {
        newContentOffset.y = self.bounds.size.height;
    }
    else if (newContentOffset.y < self.contentSize.height / 3)
    {
        newContentOffset.y = self.bounds.size.height * 2;
    }

    [super setContentOffset:newContentOffset];
}

@end
