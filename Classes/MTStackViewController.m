//
//  MTStackViewController.m
//  Maple
//
//  Created by Andrew Carter on 10/19/12.
//
//

#import "MTStackViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

typedef enum
{
    MTStackViewControllerPositionLeft,
    MTStackViewControllerPositionRight
} MTStackViewControllerPosition;

// static CGFloat const MTSwipeVelocity = 1500.0f; // Not currently used
const char *MTStackViewControllerKey = "MTStackViewControllerKey";

#pragma mark - UIViewController VPStackNavigationController Additions

@implementation UIViewController (MTStackViewController)

#pragma mark - Accessors

- (MTStackViewController *)stackViewController
{
    MTStackViewController *stackViewController = objc_getAssociatedObject(self, &MTStackViewControllerKey);
    
    if (!stackViewController && self.parentViewController != nil)
    {
        stackViewController = [self.parentViewController stackViewController];
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
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        _overlayView = [[UIView alloc] initWithFrame:[self bounds]];
        [[self overlayView] setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
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

@end

@implementation MTStackContentContainerView

#pragma mark - UIView Overrides

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        _leftViewControllerEnabled = YES;
        _rightViewControllerEnabled = NO;
        _leftControllerParallaxEnabled = YES;
        
        _rasterizesViewsDuringAnimation = YES;
        
        [self setSlideOffset:roundf(CGRectGetWidth([[UIScreen mainScreen] bounds]) * 0.8f)];
        _leftContainerView = [[MTStackContainerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _rightContainerView = [[MTStackContainerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _contentContainerView = [[MTStackContentContainerView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        
        [[_contentContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        [[_leftContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        [[_rightContainerView layer] setRasterizationScale:[[UIScreen mainScreen] scale]];
        
        UIView *transitionView = [[UIView alloc] initWithFrame:[_contentContainerView bounds]];
        [_contentContainerView addSubview:transitionView];
        
        [_leftContainerView setBackgroundColor:[UIColor whiteColor]];
        [_rightContainerView setBackgroundColor:[UIColor whiteColor]];
        [_contentContainerView setBackgroundColor:[UIColor whiteColor]];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerDidTap:)];
        
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
        [_panGestureRecognizer setCancelsTouchesInView:YES];
        [_panGestureRecognizer setDelegate:self];
        [_contentContainerView addGestureRecognizer:_panGestureRecognizer];
        
        [self setSlideAnimationDuration:0.3f];
        [self setMinShadowRadius:3.0f];
        [self setMaxShadowRadius:10.0f];
        [self setMinShadowOpacity:0.5f];
        [self setMaxShadowOpacity:1.0f];
        [self setShadowOffset:CGSizeZero];
        [self setShadowColor:[UIColor blackColor]];
        [self setLeftViewControllerOverlayColor:[UIColor blackColor]];
        [self setRightViewControllerOverlayColor:[UIColor blackColor]];
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if (![[UIApplication sharedApplication] isStatusBarHidden])
    {
        CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
        frame.origin.y = statusBarFrame.size.height;
        frame.size.height -= statusBarFrame.size.height;
    }
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view setAutoresizesSubviews:YES];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    CGFloat leftContainerOriginX = 0.0;
    if (_leftControllerParallaxEnabled)
        leftContainerOriginX = -([self slideOffset] / 4.0f);
    
    [_leftContainerView setFrame:CGRectMake(leftContainerOriginX,
                                            CGRectGetMinY([_leftContainerView frame]),
                                            CGRectGetWidth([view bounds]),
                                            CGRectGetHeight([view bounds]))];
    [view addSubview:_leftContainerView];
    
    [_rightContainerView setFrame:CGRectMake((CGRectGetWidth([view frame]) - [self slideOffset]) + ((CGRectGetWidth([view frame]) - [self slideOffset]) / 4.0f),
                                             CGRectGetMinY([_rightContainerView frame]),
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

- (void)setLeftViewController:(UIViewController *)leftViewController
{
    [self setViewController:leftViewController position:MTStackViewControllerPositionLeft];
}

- (void)setRightViewController:(UIViewController *)rightViewController
{
    [self setViewController:rightViewController position:MTStackViewControllerPositionRight];
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
            [self transitionFromViewController:currentContentViewController toViewController:[self contentViewController] duration:0.0f options:0 animations:nil completion:^(BOOL finished) {
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
        [UIView animateWithDuration:0.05f
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
                                     containerX = (-([self slideOffset] / 4.0f)) + (percentRevealed * ([self slideOffset] / 4.0f));
                                 
                                 [self setShadowOffset:CGSizeMake(-1.0f, 0.0f)];
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
    if (CGRectGetMinX([_contentContainerView frame]) <= CGRectGetWidth([_contentContainerView frame]) / 2.0f && CGRectGetMinX([_contentContainerView frame]) >= 0.0f)
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
            [[_rightContainerView layer] setShouldRasterize:YES];
        }
        
        [UIView animateWithDuration:animated ? [self slideAnimationDuration] : 0.0f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             
                             [_contentContainerView setFrame:CGRectMake([self slideOffset],
                                                                        CGRectGetMinY([_contentContainerView frame]),
                                                                        CGRectGetWidth([_contentContainerView frame]),
                                                                        CGRectGetHeight([_contentContainerView frame]))];
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
        [[_rightContainerView layer] setShouldRasterize:YES];
    }
    
    [UIView animateWithDuration:animated ? [self slideAnimationDuration] : 0.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [_contentContainerView setFrame:CGRectMake(0.0f,
                                                                    CGRectGetMinY([_contentContainerView frame]),
                                                                    CGRectGetWidth([_contentContainerView frame]),
                                                                    CGRectGetHeight([_contentContainerView frame]))];
                         
                         CGFloat newLeftContainerOffset = 0.0;
                         
                         if (_leftControllerParallaxEnabled)
                             newLeftContainerOffset = -([self slideOffset] / 4.0f);
                         
                         [[_leftContainerView overlayView] setAlpha:0.7f];
                         [_leftContainerView setFrame:CGRectMake(newLeftContainerOffset,
                                                                 CGRectGetMinY([_leftContainerView frame]),
                                                                 CGRectGetWidth([_leftContainerView frame]),
                                                                 CGRectGetHeight([_leftContainerView frame]))];
                         
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
    
    id <MTStackChildViewController> navigationChild = [self stackChildViewControllerForViewController:[self contentViewController]];
    
    if (navigationChild)
    {
        shouldPan = [navigationChild shouldAllowPanning];
    }
    
    return shouldPan;
}

- (void)contentContainerView:(MTStackContentContainerView *)view panGestureRecognizerDidPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateEnded:
        {
            [self endPanning];
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationMaskPortrait;
    else
        return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    else
        return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
    return YES;
}


@end
