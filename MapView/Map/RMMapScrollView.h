//
//  RMMapScrollView.h
//  MapView
//
//  Created by Thomas Rasch on 11.06.12.
//  Copyright (c) 2012 Alpstein. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMMapScrollView;

@protocol RMMapScrollViewDelegate <NSObject>

- (void)scrollView:(RMMapScrollView *)aScrollView correctedContentOffset:(inout CGPoint *)aContentOffset;
- (void)scrollView:(RMMapScrollView *)aScrollView correctedContentSize:(inout CGSize *)aContentSize;

@end

@interface RMMapScrollView : UIScrollView

@property (nonatomic, weak) id <RMMapScrollViewDelegate> mapScrollViewDelegate;

@end
