//
//  MTZoomContainerView.m
//  MTStackViewControllerExample
//
//  Created by Erik LaManna on 7/23/13.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//

#import "MTZoomContainerView.h"
#import <QuartzCore/QuartzCore.h>


@interface MTZoomContainerView ()

@property (nonatomic, readonly) UIView *overlayView;

@end

@implementation MTZoomContainerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizesSubviews:YES];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        
        _overlayView = [[UIView alloc] initWithFrame:[self bounds]];
        [[self overlayView] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [[self overlayView] setAlpha:1.0f];
        self.overlayView.backgroundColor = [UIColor blackColor];
        [self addSubview:_overlayView];
        
        self.transform = CGAffineTransformMakeScale(0.7f, 0.7f);
        
        [self.layer setRasterizationScale:[UIScreen mainScreen].scale];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self bringSubviewToFront:[self overlayView]];
}

-(void)stackViewController:(MTStackViewController *)stackViewController show:(BOOL)show
                      side:(MTStackViewControllerPosition)side toFrame:(CGRect)rect
              withDuration:(CGFloat)duration
{
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.overlayView.alpha = show ? 0.0f : 0.7f;
                         if (show)
                         {
                             self.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         }
                         else
                         {
                             self.transform = CGAffineTransformMakeScale(0.7f, 0.7f);

                         }
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)stackViewController:(MTStackViewController *)stackViewController anmimateToFame:(CGRect)rect side:(MTStackViewControllerPosition)side withOffset:(CGFloat)offset
{
    [self.overlayView setAlpha:0.7f - (1.0f * fminf(offset, 0.7f))];
    
    self.transform = CGAffineTransformMakeScale(0.7f + (0.3f * offset), 0.7f + (0.3f * offset));
}

@end
