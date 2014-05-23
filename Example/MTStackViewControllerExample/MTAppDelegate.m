//
//  MTAppDelegate.m
//  MTStackViewControllerExample
//
//  Created by Andrew Carter on 1/31/13.
//  Copyright (c) 2013 WillowTree Apps. All rights reserved.
//

#import "MTAppDelegate.h"

#import "MTStackViewController.h"
#import "MTMenuViewController.h"

#import "MTStackDefaultContainerView.h"
#import "MTStackFoldView.h"
#import "MTZoomContainerView.h"

@implementation MTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
    [[self window] setBackgroundColor:[UIColor whiteColor]];

    MTStackViewController *stackViewController = [[MTStackViewController alloc] initWithNibName:nil bundle:nil];
    [stackViewController setAnimationDurationProportionalToPosition:YES];
    
    MTMenuViewController *menuViewController = [[MTMenuViewController alloc] initWithNibName:nil bundle:nil];
    //UINavigationController *menuNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
    CGRect foldFrame = CGRectMake(0, 0, stackViewController.slideOffset,
                                  CGRectGetHeight(self.window.bounds));
    menuViewController.view.frame = foldFrame;
    
    [stackViewController setLeftContainerView:[[MTStackFoldView alloc] initWithFrame:foldFrame foldDirection:FoldDirectionHorizontalLeftToRight]];
//    [stackViewController setLeftContainerView:[[MTZoomContainerView alloc] initWithFrame:foldFrame]];
    [stackViewController setLeftViewController:menuViewController];
    
    

    
    UITableViewController* tableViewController = [[UITableViewController alloc] initWithNibName:nil bundle:nil];
    [stackViewController setRightViewController:tableViewController];
    stackViewController.rightViewControllerEnabled = YES;
    
    UINavigationController *contentNavigationController = [UINavigationController new];
    [stackViewController setContentViewController:contentNavigationController];
    
    [[self window] setRootViewController:stackViewController];
    [[self window] makeKeyAndVisible];
    
    return YES;
}


@end
