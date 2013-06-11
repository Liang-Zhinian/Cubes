//
//  InfiniteScrollView.m
//  Cube
//
//  Created by Stuart Lynch on 09/06/2013.
//  Copyright (c) 2013 UEA. All rights reserved.
//

#import "InfiniteScrollView.h"

@interface InfiniteScrollView () <UIScrollViewDelegate>

@end

@implementation InfiniteScrollView

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle
//////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    if ( (self = [super initWithFrame:frame]))
    {
        self.delegate = self;
        self.contentSize = CGSizeMake(frame.size.width*20, frame.size.height/12);
        self.contentOffset = CGPointMake(frame.size.width*4, 0);
        self.showsHorizontalScrollIndicator = YES;
    }
    return self;
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollViewDelegate
//////////////////////////////////////////////////////////////////////////

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    targetContentOffset->x = roundf(targetContentOffset->x/self.frame.size.width)*self.frame.size.width;
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Overwridden Methods
//////////////////////////////////////////////////////////////////////////

- (void)layoutSubviews
{
    CGFloat rightThreshold = self.contentSize.width*3/5;
    CGFloat leftThreshold = self.contentSize.width*1/5;
    
    if (self.contentOffset.x > rightThreshold)
    {
        CGPoint contentOffset = self.contentOffset;
        contentOffset.x -= self.contentSize.width*1/5;
        self.contentOffset = contentOffset;
    }
    else if(self.contentOffset.x < leftThreshold)
    {
        CGPoint contentOffset = self.contentOffset;
        contentOffset.x += self.contentSize.width*1/5;
        self.contentOffset = contentOffset;
    }
}


@end
