//
//  MTStackViewController.m
//  Maple
//
//  Created by Andrew Carter on 10/19/12.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MTStackViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

typedef enum
{
    MTStackViewControllerPositionLeft,
    MTStackViewControllerPositionRight
} MTStackViewControllerPosition;

const char *MTStackViewControllerKey = "MTStackViewControllerKey";

#pragma mark - UIViewController VPStackNavigationController Additions

@implementation UIViewController (MTStackViewController)

#pragma mark - Accessors

- (MTStackViewController *)stackViewController
{
    MTStackViewController *stackViewController = objc_getAssociatedObject(self, &MTStackViewControllerKey);
    
    if (!stackViewController && [self parentViewController] != nil)
    {
        stackViewController = [[self parentViewController] stackViewController];
    }
    
    return stackViewController;
}

- (void)setStackViewController:(MTStackViewController *)stackViewController
{
    objc_setAssociatedObject(self, &MTStackViewControllerKey, stackViewController, OBJC_ASSOCIATION_ASSIGN);
}

@end

#pragma mark - VPStackLeftContainerView

@interface MTStackContainerView : UIView

@property (nonatomic, readonly) UIView *overlayView;

@end

@implementation MTStackContainerView

#pragma mark - UIView Overrides

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
        [self addSubview:_overlayView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self bringSubviewToFront:[self overlayView]];
}

@end

#pragma mark - VPStackContentContainerView

@interface MTStackContentContainerView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *separatorView;
@end

@implementation MTStackContentContainerView

#pragma mark - UIView Overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self setAutoresizesSubviews:YES];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:[self bounds]];
    [[self layer] setShadowPath:[shadowPath CGPath]];
}

@end

#pragma mark - VPStackNavigationController

@interface MTStackViewController ()
{
    MTStackContainerView *_leftContainerView;
    MTStackContainerView *_leftHeaderView;
    MTStackContainerView *_rightContainerView;
    MTStackContentContainerView *_contentContainerView;
    CGPoint _initialPanGestureLocation;
    CGRect _initialContentControllerFrame;
    UITapGestureRecognizer *_tapGestureRecognizer;
}
@end

@interface MTStackViewController () <UIGestureRecognizerDelegate>

@end

@implementation MTStackViewController

#pragma mark - UIViewController Overrides

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		[self setup];
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
		[self setup];
    }
    return self;
}

- (void)setup
{
    CGRect screenBounds = [self screenBounds];
    
    _swipeVelocity = 500.0f;
    
    _leftViewControllerEnabled = YES;
    _rightViewControllerEnabled = NO;
    _leftControllerParallaxEnabled = YES;
    _rightControllerParallaxEnabled = YES;
    _leftSnapThreshold = screenBounds.size.width / 2.0f;
    _rasterizesViewsDuringAnimation = YES;
    _hideLeftViewControllerAnimation = UIViewAnimationOptionCurveEaseOut;
    
    [self setSlideOffset:roundf(screenBounds.size.width * 0.8f)];
    [self setHeaderSlideOffset:[self slideOffset] * 0.5];
    
    _leftContainerView = [[MTStackContainerView alloc] initWithFrame:screenBounds];
    _leftHeaderView = [[MTStackContainerView alloc] initWithFrame:CGRectZero];
    _rightContainerView = [[MTStackContainerView alloc] initWithFrame:screenBounds];
    _contentContainerView = [[MTStackContentContainerView alloc] initWithFrame:screenBounds];
    
    [[_leftHeaderView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
    [[_contentContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
    [[_leftContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
    [[_rightContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
    
    UIView *transitionView = [[UIView alloc] initWithFrame:screenBounds];
    [_contentContainerView addSubview:transitionView];
    
    [_leftHeaderView setBackgroundColor:[UIColor whiteColor]];
    [_leftContainerView setBackgroundColor:[UIColor whiteColor]];
    [_rightContainerView setBackgroundColor:[UIColor whiteColor]];
    [_contentContainerView setBackgroundColor:[UIColor whiteColor]];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerDidTap:)];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
    [_panGestureRecognizer setCancelsTouchesInView:YES];
    [_panGestureRecognizer setDelegate:self];
    [_contentContainerView addGestureRecognizer:_panGestureRecognizer];
    
    [self setSlideAnimationDuration:0.3f];
    [self setTrackingAnimationDuration:0.05f];
    [self setMinShadowRadius:3.0f];
    [self setMaxShadowRadius:10.0f];
    [self setMinShadowOpacity:0.5f];
    [self setMaxShadowOpacity:1.0f];
    [self setShadowOffset:CGSizeZero];
    [self setShadowColor:[UIColor blackColor]];
    [self setLeftViewControllerOverlayColor:[UIColor blackColor]];
    [self setRightViewControllerOverlayColor:[UIColor blackColor]];
    [[_leftHeaderView overlayView] setBackgroundColor:[UIColor blackColor]];
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    frame.size.height -= MIN(statusBarFrame.size.width, statusBarFrame.size.height);
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    CGFloat leftContainerOriginX = 0.0f;
    if (_leftControllerParallaxEnabled)
    {
        leftContainerOriginX = -([self slideOffset] / 4.0f);
    }
    _leftHeaderView.frame = CGRectMake(-[self headerSlideOffset],
                                       0.0f,
                                       CGRectGetWidth([_leftHeaderView frame]),
                                       CGRectGetHeight([_leftHeaderView frame]));
    
    [view addSubview:_leftHeaderView];
    
    [_leftContainerView setFrame:CGRectMake(leftContainerOriginX,
                                            CGRectGetMaxY([_leftHeaderView frame]),
                                            CGRectGetWidth([view bounds]),
                                            CGRectGetHeight([view bounds]) - CGRectGetMaxY([_leftHeaderView frame]))];
    [view addSubview:_leftContainerView];
    
    [_rightContainerView setFrame:CGRectMake((CGRectGetWidth([view frame]) - [self slideOffset]) + ((CGRectGetWidth([view frame]) - [self slideOffset]) / 4.0f),
                                             0.0f,
                                             CGRectGetWidth([view bounds]),
                                             CGRectGetHeight([view bounds]))];
    [view addSubview:_rightContainerView];
    [_contentContainerView setFrame:[view bounds]];
    [view addSubview:_contentContainerView];
    
    [self setView:view];
}

#pragma mark - Accessors

- (void)setNoSimultaneousPanningViewClasses:(NSArray *)noSimultaneousPanningViewClasses
{
    _noSimultaneousPanningViewClasses = [noSimultaneousPanningViewClasses copy];
    
    for (id object in [self noSimultaneousPanningViewClasses])
    {
        NSAssert(class_isMetaClass(object_getClass(object)), @"Objects in this array must be of type 'Class'");
        NSAssert([(Class)object isSubclassOfClass:[UIView class]], @"Class objects in this array must be UIView subclasses");
    }
}

- (void)setShadowColor:(UIColor *)shadowColor
{
    _shadowColor = [shadowColor copy];
    [[_contentContainerView layer] setShadowColor:[[self shadowColor] CGColor]];
}

- (void)setShadowOffset:(CGSize)shadowOffset
{
    _shadowOffset = shadowOffset;
    [[_contentContainerView layer] setShadowOffset:[self shadowOffset]];
}

- (void)setMinShadowRadius:(CGFloat)minShadowRadius
{
    _minShadowRadius = minShadowRadius;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
    }
}

- (void)setMaxShadowRadius:(CGFloat)maxShadowRadius
{
    _maxShadowRadius = maxShadowRadius;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius]];
    }
}

- (void)setMinShadowOpacity:(CGFloat)minShadowOpacity
{
    _minShadowOpacity = minShadowOpacity;
    if ([self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
    }
}

- (void)setMaxShadowOpacity:(CGFloat)maxShadowOpacity
{
    _maxShadowOpacity = maxShadowOpacity;
    if (![self isLeftViewControllerVisible])
    {
        [[_contentContainerView layer] setShadowOpacity:[self maxShadowOpacity]];
    }
}

- (void)setLeftViewControllerOverlayColor:(UIColor *)leftViewControllerOverlayColor
{
    _leftViewControllerOverlayColor = [leftViewControllerOverlayColor copy];
    [[_leftContainerView overlayView] setBackgroundColor:[self leftViewControllerOverlayColor]];
}

- (void)setRightViewControllerOverlayColor:(UIColor *)rightViewControllerOverlayColor
{
    _rightViewControllerOverlayColor = [rightViewControllerOverlayColor copy];
    [[_rightContainerView overlayView] setBackgroundColor:[self rightViewControllerOverlayColor]];
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    _separatorColor = separatorColor;
    
    if (!_contentContainerView.separatorView)
    {
        CGRect frame = CGRectMake(-1,
                                  0,
                                  1,
                                  CGRectGetHeight(self.view.frame));

        UIView *separatorView = [[UIView alloc] initWithFrame:frame];
        [_contentContainerView addSubview:separatorView];
        _contentContainerView.separatorView = separatorView;
    }
    
    _contentContainerView.separatorView.backgroundColor = separatorColor;

}

- (void)setLeftViewController:(UIViewController *)leftViewController
{
    [self setViewController:leftViewController position:MTStackViewControllerPositionLeft];
}

- (void)setRightViewController:(UIViewController *)rightViewController
{
    [self setViewController:rightViewController position:MTStackViewControllerPositionRight];
}

- (void)setLeftHeaderView:(UIView*)leftHeaderView {
    
    for (UIView *view in [_leftHeaderView subviews]) {
        if (![view isEqual:[_leftHeaderView overlayView]]) {
            [view removeFromSuperview];
        }
    }
    
    [_leftHeaderView addSubview:leftHeaderView];
    CGFloat leftHeaderX = -[self headerSlideOffset];
    [_leftHeaderView setFrame:CGRectMake(leftHeaderX,
                                         0.0f,
                                         CGRectGetWidth([leftHeaderView frame]),
                                         CGRectGetHeight([leftHeaderView frame]))];
    
    
    [[_leftHeaderView overlayView] setFrame:CGRectMake(0.0f,
                                                       0.0f,
                                                       CGRectGetWidth([leftHeaderView frame]),
                                                       CGRectGetHeight([leftHeaderView frame]) + [[UIApplication sharedApplication] statusBarFrame].size.height)];
    
    [_leftContainerView setFrame:CGRectMake(0.0f,
                                            CGRectGetMaxY([leftHeaderView frame]),
                                            [_leftContainerView frame].size.width,
                                            [_leftContainerView frame].size.height - CGRectGetMaxY([leftHeaderView frame]))];
    
}

- (void)setViewController:(UIViewController *)newViewController position:(MTStackViewControllerPosition)position
{
    UIViewController *currentViewController  =  nil;
    UIView *containerView = nil;
    switch (position) {
        case MTStackViewControllerPositionLeft:
        {
            currentViewController = [self leftViewController];
            _leftViewController = newViewController;
            containerView = _leftContainerView;
        }
            break;
        case MTStackViewControllerPositionRight:
        {
            currentViewController = [self rightViewController];
            _rightViewController = newViewController;
            containerView = _rightContainerView;
        }
            break;
    }
    
    if (newViewController)
    {
        [newViewController setStackViewController:self];
        [self addChildViewController:newViewController];
        [[newViewController view] setFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth([containerView frame]), CGRectGetHeight([containerView frame]))];
        
        if (currentViewController)
        {
            [self transitionFromViewController:currentViewController toViewController:newViewController duration:0.0f options:0 animations:nil completion:^(BOOL finished) {
                [currentViewController removeFromParentViewController];
                [currentViewController setStackViewController:nil];
            }];
        }
        else
        {
            [containerView addSubview:[newViewController view]];
        }
    }
    else if (currentViewController)
    {
        [[currentViewController view] removeFromSuperview];
        [currentViewController removeFromParentViewController];
        [currentViewController setStackViewController:nil];
    }
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController snapToContentViewController:YES animated:YES];
}

- (BOOL)isLeftViewControllerVisible
{
    return CGRectGetMinX([_contentContainerView frame]) == [self slideOffset];
}

- (BOOL)isRightViewControllerVisible
{
    return CGRectGetMinX([_contentContainerView frame]) == -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (void)panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:panGestureRecognizer];
    
    if (shouldPan)
    {
        [self contentContainerView:_contentContainerView panGestureRecognizerDidPan:panGestureRecognizer];
    }
    
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    BOOL shouldRecognize = YES;
    
    if ([[[otherGestureRecognizer view] superview] isKindOfClass:[UISwitch class]])
    {
        shouldRecognize = NO;
    }
    
    for (Class class in [self noSimultaneousPanningViewClasses])
    {
        if ([[otherGestureRecognizer view] isKindOfClass:class] || [[[otherGestureRecognizer view] superview] isKindOfClass:class])
        {
            shouldRecognize = NO;
        }
    }
    
    return shouldRecognize;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = [self contentContainerView:_contentContainerView panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)gestureRecognizer];
    
    return shouldBegin;
}

#pragma mark - Instance Methods

- (void)tapGestureRecognizerDidTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self hideLeftViewController];
}

- (void)setContentViewController:(UIViewController *)contentViewController hideLeftViewController:(BOOL)hideLeftViewController animated:(BOOL)animated
{
    [self setContentViewController:contentViewController snapToContentViewController:hideLeftViewController animated:animated];
}

- (void)setContentViewController:(UIViewController *)contentViewController snapToContentViewController:(BOOL)snapToContentViewController animated:(BOOL)animated
{
    UIViewController *currentContentViewController = [self contentViewController];
    
    _contentViewController = contentViewController;
    
    if ([self contentViewController])
    {
        [[self contentViewController] setStackViewController:self];
        [self addChildViewController:[self contentViewController]];
        [[[self contentViewController] view] setFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth([_contentContainerView frame]), CGRectGetHeight([_contentContainerView frame]))];
        
        if (currentContentViewController)
        {
            [self transitionFromViewController:currentContentViewController toViewController:[self contentViewController] duration:[self contentViewControllerAnimationDuration] options:[self contentViewControllerAnimationOption] animations:nil completion:^(BOOL finished) {
                
                [currentContentViewController removeFromParentViewController];
                [currentContentViewController setStackViewController:nil];
                if (snapToContentViewController)
                {
                    if ([self isLeftViewControllerVisible])
                    {
                        [self hideLeftViewControllerAnimated:animated];
                    }
                    else if ([self isRightViewControllerVisible])
                    {
                        [self hideRightViewControllerAnimated:animated];
                    }
                }
            }];
        }
        else
        {
            [_contentContainerView addSubview:[[self contentViewController] view]];
            if (snapToContentViewController)
            {
                if ([self isLeftViewControllerVisible])
                {
                    [self hideLeftViewControllerAnimated:animated];
                }
                else if ([self isRightViewControllerVisible])
                {
                    [self hideRightViewControllerAnimated:animated];
                }
            }
        }
    }
    else if (currentContentViewController)
    {
        [[currentContentViewController view] removeFromSuperview];
        [currentContentViewController removeFromParentViewController];
        [currentContentViewController setStackViewController:nil];
        if (snapToContentViewController)
        {
            if ([self isLeftViewControllerVisible])
            {
                [self hideLeftViewControllerAnimated:animated];
            }
            else if ([self isRightViewControllerVisible])
            {
                [self hideRightViewControllerAnimated:animated];
            }
        }
    }
}

- (void)panWithPanGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint location = [panGestureRecognizer locationInView:[self view]];
    
    if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) < 0.0f)
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
    }
    else
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:YES];
    }
    
    MTStackContainerView *containerView = CGRectGetMinX([_contentContainerView frame]) >= 0.0f ? _leftContainerView : _rightContainerView;
    
    CGFloat contentViewFrameX = CGRectGetMinX(_initialContentControllerFrame) - (_initialPanGestureLocation.x - location.x);
    if (contentViewFrameX < -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]))
    {
        contentViewFrameX = -CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]);
    }
    if (contentViewFrameX > [self slideOffset])
    {
        contentViewFrameX = [self slideOffset];
    }
    
    if (
        ([self isLeftViewControllerEnabled] && contentViewFrameX > 0.0f) ||
        ([self isRightViewControllerEnabled] && contentViewFrameX < 0.0f)
        )
    {
        [UIView animateWithDuration:[self trackingAnimationDuration]
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake(contentViewFrameX,
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
                             
                             CGFloat percentRevealed = fabsf(CGRectGetMinX([_contentContainerView frame]) / [self slideOffset]);
                             [[containerView overlayView] setAlpha:0.7f - (1.0f * fminf(percentRevealed, 0.7f))];
                             
                             CGFloat containerX = 0.0f;
                             if (containerView == _leftContainerView)
                             {
                                 if (_leftControllerParallaxEnabled)
                                 {
                                     containerX = (-([self slideOffset] / 4.0f)) + (percentRevealed * ([self slideOffset] / 4.0f));
                                 }
                                 
                                 [self setShadowOffset:CGSizeMake(-1.0f, 0.0f)];
                                 
                                 CGFloat headerX = -[self headerSlideOffset] + (percentRevealed * [self headerSlideOffset]);
                                 [_leftHeaderView setFrame:CGRectMake(headerX,
                                                                      CGRectGetMinY([_leftHeaderView frame]),
                                                                      CGRectGetWidth([_leftHeaderView frame]),
                                                                      CGRectGetHeight([_leftHeaderView frame]))];
                                 
                                 [[_leftHeaderView overlayView] setAlpha:0.7f - (1.0f * fminf(percentRevealed, 0.7f))];
                             }
                             else
                             {
                                 containerX = (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]) + ((1.0f - percentRevealed) * ([self slideOffset] / 4.0f));
                                 [self setShadowOffset:CGSizeMake(1.0f, 0.0f)];
                                 
                             }
                             [containerView setFrame:CGRectMake(containerX,
                                                                CGRectGetMinY([containerView frame]),
                                                                CGRectGetWidth([containerView frame]),
                                                                CGRectGetHeight([containerView frame]))];
                             [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius] - (([self maxShadowRadius] - [self minShadowRadius]) * percentRevealed)];
                             [[_contentContainerView layer] setShadowOpacity:1.0f - (0.5 * percentRevealed)];
                             
                         } completion:^(BOOL finished) {
                             
                             id <MTStackChildViewController> childViewController = [self stackChildViewControllerForViewController:[self contentViewController]];
                             if ([childViewController respondsToSelector:@selector(stackViewController:didPanToOffset:)])
                             {
                                 [childViewController stackViewController:self didPanToOffset:CGRectGetMinX([_contentContainerView frame])];
                             }
                             
                         }];
    }
}

- (void)endPanning
{
    [self snapContentViewController];
}

- (void)snapContentViewController
{
    if (CGRectGetMinX([_contentContainerView frame]) <= _leftSnapThreshold && CGRectGetMinX([_contentContainerView frame]) >= 0.0f)
    {
        [self hideLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
    {
        [self revealLeftViewControllerAnimated:YES];
    }
    else if (CGRectGetMaxX([_contentContainerView frame]) <= CGRectGetWidth([_contentContainerView frame]) / 2.0f)
    {
        [self revealRightViewControllerAnimated:YES];
    }
    else
    {
        [self hideRightViewController];
    }
}

- (void)revealLeftViewController
{
    [self revealLeftViewControllerAnimated:YES];
}

- (void)revealLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerEnabled])
    {
        [_rightContainerView setHidden:YES];
        [_leftContainerView setHidden:NO];
        
        [self setShadowOffset:CGSizeMake(-1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_leftHeaderView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        NSTimeInterval animationDuration = 0.0f;
        
        if (animated)
        {
            if ([self animationDurationProportionalToPosition])
            {
                animationDuration = [self slideAnimationDuration] * ([self slideOffset] - [_contentContainerView frame].origin.x) / [self slideOffset];
                animationDuration = fmax(animationDuration, 0.15f);
            }
            else
                animationDuration = [self slideAnimationDuration];
        }
        
        [UIView animateWithDuration:animationDuration
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake([self slideOffset],
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
                             [[_leftHeaderView overlayView] setAlpha:0.0f];
                             [_leftHeaderView setFrame:CGRectMake(0.0f,
                                                                  CGRectGetMinY([_leftHeaderView frame]),
                                                                  CGRectGetWidth([_leftHeaderView frame]),
                                                                  CGRectGetHeight([_leftHeaderView frame]))];
                             [[_leftContainerView overlayView] setAlpha:0.0f];
                             [_leftContainerView setFrame:CGRectMake(0.0f,
                                                                     CGRectGetMinY([_leftContainerView frame]),
                                                                     CGRectGetWidth([_leftContainerView frame]),
                                                                     CGRectGetHeight([_leftContainerView frame]))];
                             [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
                             [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
                             
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[_contentContainerView layer] setShouldRasterize:NO];
                                 [[_leftContainerView layer] setShouldRasterize:NO];
                                 [[_leftHeaderView layer] setShouldRasterize:NO];
                                 [[_rightContainerView layer] setShouldRasterize:NO];
                             }
                             
                             [self setContentViewUserInteractionEnabled:NO];
                             [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                             
                             if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealLeftViewController:)])
                             {
                                 [[self delegate] stackViewController:self didRevealLeftViewController:[self leftViewController]];
                             }
                             
                         }];
    }
}

- (void)revealRightViewController
{
    [self revealRightViewControllerAnimated:YES];
}

- (void)revealRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerEnabled])
    {
        [_rightContainerView setHidden:NO];
        [_leftContainerView setHidden:YES];
        
        [self setShadowOffset:CGSizeMake(1.0f, 0.0f)];
        
        if ([self rasterizesViewsDuringAnimation])
        {
            [[_contentContainerView layer] setShouldRasterize:YES];
            [[_leftContainerView layer] setShouldRasterize:YES];
            [[_leftHeaderView layer] setShouldRasterize:YES];
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        [UIView animateWithDuration:animated ? [self slideAnimationDuration] : 0.0f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake(-CGRectGetWidth([_contentContainerView bounds]) + (CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]),
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
                             [[_rightContainerView overlayView] setAlpha:0.0f];
                             [_rightContainerView setFrame:CGRectMake(CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset],
                                                                      CGRectGetMinY([_rightContainerView frame]),
                                                                      CGRectGetWidth([_rightContainerView frame]),
                                                                      CGRectGetHeight([_rightContainerView frame]))];
                             [[_contentContainerView layer] setShadowRadius:[self minShadowRadius]];
                             [[_contentContainerView layer] setShadowOpacity:[self minShadowOpacity]];
                             
                         } completion:^(BOOL finished) {
                             
                             if ([self rasterizesViewsDuringAnimation])
                             {
                                 [[_contentContainerView layer] setShouldRasterize:NO];
                                 [[_leftContainerView layer] setShouldRasterize:NO];
                                 [[_leftHeaderView layer] setShouldRasterize:NO];
                                 [[_rightContainerView layer] setShouldRasterize:NO];
                             }
                             
                             [self setContentViewUserInteractionEnabled:NO];
                             [_contentContainerView addGestureRecognizer:_tapGestureRecognizer];
                             
                             if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealLeftViewController:)])
                             {
                                 [[self delegate] stackViewController:self didRevealRightViewController:[self leftViewController]];
                             }
                             
                         }];
    }
}

- (void)hideLeftViewController
{
    [self hideLeftViewControllerAnimated:YES];
}

- (void)hideLeftViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideRightViewController
{
    [self hideRightViewControllerAnimated:YES];
}

- (void)hideRightViewControllerAnimated:(BOOL)animated
{
    [self hideLeftOrRightViewControllerAnimated:animated];
}

- (void)hideLeftOrRightViewControllerAnimated:(BOOL)animated
{
    if ([self rasterizesViewsDuringAnimation])
    {
        [[_contentContainerView layer] setShouldRasterize:YES];
        [[_leftContainerView layer] setShouldRasterize:YES];
        [[_leftHeaderView layer] setShouldRasterize:YES];
        [[_rightContainerView layer] setShouldRasterize:YES];
    }
    
    NSTimeInterval animationDuration = 0.0f;
    
    if (animated)
    {
        if ([self animationDurationProportionalToPosition])
        {
            if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
            {
                animationDuration = [self slideAnimationDuration] * (CGRectGetMinX([_contentContainerView frame]) / [self slideOffset]);
            } 
            else
            {
                animationDuration = [self slideAnimationDuration] * ((CGRectGetWidth([_contentContainerView bounds]) - CGRectGetMaxX([_contentContainerView frame])) / [self slideOffset]);
            }
            animationDuration = fmax(0.15f, animationDuration);
        }
        else
        {
            animationDuration = [self slideAnimationDuration];
        }
    }
    
    [UIView animateWithDuration:animationDuration
                          delay:0.0f
                        options:_hideLeftViewControllerAnimation | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [_contentContainerView setFrame:CGRectMake(0.0f,
                                                                    CGRectGetMinY([_contentContainerView frame]),
                                                                    CGRectGetWidth([_contentContainerView frame]),
                                                                    CGRectGetHeight([_contentContainerView frame]))];
                         
                         CGFloat newLeftContainerOffset = 0.0f;
                         
                         if (_leftControllerParallaxEnabled)
                             newLeftContainerOffset = -([self slideOffset] / 4.0f);
                         
                         [[_leftContainerView overlayView] setAlpha:0.7f];
                         [_leftContainerView setFrame:CGRectMake(newLeftContainerOffset,
                                                                 CGRectGetMinY([_leftContainerView frame]),
                                                                 CGRectGetWidth([_leftContainerView frame]),
                                                                 CGRectGetHeight([_leftContainerView frame]))];
                         
                         [_leftHeaderView setFrame:CGRectMake(-[self headerSlideOffset],
                                                              CGRectGetMinY([_leftHeaderView frame]),
                                                              CGRectGetWidth([_leftHeaderView frame]),
                                                              CGRectGetHeight([_leftHeaderView frame]))];
                         [[_leftHeaderView overlayView] setAlpha:0.7f];
                         
                         [[_rightContainerView overlayView] setAlpha:0.7f];
                         [_rightContainerView setFrame:CGRectMake((CGRectGetWidth([_contentContainerView bounds]) - [self slideOffset]) + ([self slideOffset] / 4.0f),
                                                                  CGRectGetMinY([_rightContainerView frame]),
                                                                  CGRectGetWidth([_rightContainerView frame]),
                                                                  CGRectGetHeight([_rightContainerView frame]))];
                         
                         [[_contentContainerView layer] setShadowRadius:[self maxShadowRadius]];
                         [[_contentContainerView layer] setShadowOpacity:[self maxShadowOpacity]];
                         
                         
                         
                     } completion:^(BOOL finished) {
                         
                         if ([self rasterizesViewsDuringAnimation])
                         {
                             [[_contentContainerView layer] setShouldRasterize:NO];
                             [[_leftContainerView layer] setShouldRasterize:NO];
                             [[_leftHeaderView layer] setShouldRasterize:NO];
                             [[_rightContainerView layer] setShouldRasterize:NO];
                         }
                         
                         [self setContentViewUserInteractionEnabled:YES];
                         [_contentContainerView removeGestureRecognizer:_tapGestureRecognizer];
                         
                         if ([[self delegate] respondsToSelector:@selector(stackViewController:didRevealContentViewController:)])
                         {
                             [[self delegate] stackViewController:self didRevealContentViewController:[self contentViewController]];
                         }
                         
                     }];
}

- (void)toggleLeftViewController
{
    [self toggleLeftViewControllerAnimated:YES];
}

- (void)toggleLeftViewControllerAnimated:(BOOL)animated
{
    if ([self isLeftViewControllerVisible])
    {
        [self hideLeftViewControllerAnimated:animated];
    }
    else
    {
        [self revealLeftViewControllerAnimated:animated];
    }
}

- (void)toggleLeftViewController:(id)sender event:(UIEvent *)event
{
    [self toggleLeftViewController];
}

- (void)toggleRightViewController
{
    [self toggleRightViewControllerAnimated:YES];
}

- (void)toggleRightViewControllerAnimated:(BOOL)animated
{
    if ([self isRightViewControllerVisible])
    {
        [self hideRightViewControllerAnimated:animated];
    }
    else
    {
        [self revealRightViewControllerAnimated:animated];
    }
}

- (void)toggleRightViewController:(id)sender event:(UIEvent *)event
{
    [self toggleRightViewController];
}

- (void)setContentViewUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    UIViewController *contentViewController = [self contentViewController];
    if ([contentViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)contentViewController;
        
        if ([[navigationController viewControllers] count] > 1 && [self disableNavigationBarUserInterationWhenDrilledDown])
        {
            [[navigationController view] setUserInteractionEnabled:userInteractionEnabled];
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *currentViewController = [[navigationController viewControllers] lastObject];
            [[currentViewController view] setUserInteractionEnabled:userInteractionEnabled];
        }
    }
    else
    {
        [[[self contentViewController] view] setUserInteractionEnabled:userInteractionEnabled];
    }
}

#pragma mark - VPStackContentContainerView Methods

- (id <MTStackChildViewController>)stackChildViewControllerForViewController:(UIViewController *)childViewController
{
    id <MTStackChildViewController> navigationChild = nil;
    
    if ([childViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navigationController = (UINavigationController *)childViewController;
        if ([navigationController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)navigationController;
        }
        else if ([[navigationController viewControllers] count])
        {
            UIViewController *viewController = [[navigationController viewControllers] lastObject];
            if ([viewController conformsToProtocol:@protocol(MTStackChildViewController)])
            {
                navigationChild = (id <MTStackChildViewController>)viewController;
            }
        }
    }
    else if ([childViewController isKindOfClass:[UIViewController class]])
    {
        if ([childViewController conformsToProtocol:@protocol(MTStackChildViewController)])
        {
            navigationChild = (id <MTStackChildViewController>)childViewController;
        }
    }
    
    return navigationChild;
}

- (BOOL)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerShouldPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    BOOL shouldPan = YES;
    
    if ([self disableSwipeWhenContentNavigationControllerDrilledDown] &&
        [_contentViewController isKindOfClass:[UINavigationController class]] &&
        [[(UINavigationController *)_contentViewController viewControllers] count] > 1)
    {
        shouldPan = NO;
    }
    else
    {
        id <MTStackChildViewController> navigationChild = [self stackChildViewControllerForViewController:[self contentViewController]];
        
        if (navigationChild)
        {
            shouldPan = [navigationChild shouldAllowPanning];
        }
    }
    
    return shouldPan;
}

- (CGRect)screenBounds
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (UIInterfaceOrientationIsLandscape([self interfaceOrientation]))
        screenBounds.size = CGSizeMake(screenBounds.size.height, screenBounds.size.width);
    
    return screenBounds;
}

- (void)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch ([panGestureRecognizer state])
    {
        case UIGestureRecognizerStateEnded:
        {
            if (![self handleSwipe:panGestureRecognizer])
            {
                [self endPanning];
            }
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerDidEndPanning:)])
            {
                [controller stackViewControllerDidEndPanning:self];
            }
        }
            break;
        case UIGestureRecognizerStateBegan:
        {
            if ([self rasterizesViewsDuringAnimation])
            {
                [[_contentContainerView layer] setShouldRasterize:YES];
                [[_leftContainerView layer] setShouldRasterize:YES];
                [[_leftHeaderView layer] setShouldRasterize:YES];
                [[_rightContainerView layer] setShouldRasterize:YES];
            }
            _initialPanGestureLocation = [panGestureRecognizer locationInView:[self view]];
            _initialContentControllerFrame = [_contentContainerView frame];
            id <MTStackChildViewController> controller = [self stackChildViewControllerForViewController:[self contentViewController]];
            if ([controller respondsToSelector:@selector(stackViewControllerWillBeginPanning:)])
            {
                [controller stackViewControllerWillBeginPanning:self];
            }
        }
        case UIGestureRecognizerStateChanged:
            [self panWithPanGestureRecognizer:panGestureRecognizer];
            break;
        default:
            break;
    }
}

- (BOOL)handleSwipe:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGFloat velocity = [panGestureRecognizer velocityInView:[self view]].x;
    if (velocity >= [self swipeVelocity])
    {
        if (CGRectGetMinX([_contentContainerView frame]) > 0.0f)
        {
            [self revealLeftViewController];
        }
        else
        {
            [self hideRightViewController];
        }
    }
    else if (velocity <= [self swipeVelocity] * -1.0f)
    {
        if (CGRectGetMinX([_contentContainerView frame]) < 0.0f)
        {
            [self revealRightViewController];
        }
        else
        {
            [self hideLeftViewController];
        }
    }
    
    return NO;
}

// Defaults to portrait only, subclass and override these methods, if you want to support landscape
// Also make sure your content view controller overrides these methods to support registration, so it resizes correctly
// for UINavigationController, the autoresizing mask needs to be flexible width and height (may need to be set in viewWillAppear:)

#pragma mark - Support Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
