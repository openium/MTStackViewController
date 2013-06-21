/**
 * 
 * Created by Jeff Ward on 6/20/13.
 * Portions of this code are from PaperFoldView Copyright (c) 2012 Muh Hon Cheng
 * Copyright (c) 2013 WillowTree Apps. All rights reserved.
 */

#import <UIKit/UIKit.h>

#import "MTStackViewController.h"
#import "PaperFoldConstants.h"
#import "FacingView.h"

@interface MTStackFoldView : MTStackContainerView

// each folderView consists of 2 facing views: leftView and rightView
@property (nonatomic) FacingView *leftView, *rightView;
// or topView and bottomView
@property (nonatomic) FacingView *topView, *bottomView;


// indicate whether the fold is open or closed
@property (nonatomic, assign) FoldState state;
@property (nonatomic, assign) FoldDirection foldDirection;
// optimized screenshot follows the scale of the screen
// non-optimized is always the non-retina image
@property (nonatomic, assign) BOOL useOptimizedScreenshot;


- (id)initWithFrame:(CGRect)frame foldDirection:(FoldDirection)foldDirection;


@end
