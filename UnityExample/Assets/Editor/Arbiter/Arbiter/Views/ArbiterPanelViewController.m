//
//  ArbiterPanelViewController.m
//  Unity-iPhone
//
//  Created by Andy Zinsser on 9/3/14.
//
//

#import "ArbiterPanelViewController.h"

@implementation ArbiterPanelViewController

- (id)initWithSupportedOrientations:(NSUInteger)orientations
{
    self = [super init];
    if (self) {
        self.orientations = orientations;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

# pragma mark Settings / Configs

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return self.orientations;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end