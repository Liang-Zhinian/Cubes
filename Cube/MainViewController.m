//
//  MainViewController.m
//  Cube
//
//  Created by Stuart Lynch on 09/06/2013.
//  Copyright (c) 2013 UEA. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
{
}

@end

@implementation MainViewController

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle
//////////////////////////////////////////////////////////////////////////

- (id)init
{
    if ( (self = [super init]) != nil)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	_openGLView = [[OpenGLESView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _openGLView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_openGLView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_openGLView release];
    [super dealloc];
}

@end
