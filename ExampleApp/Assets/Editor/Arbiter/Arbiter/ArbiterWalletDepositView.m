//
//  ArbiterWalletDepsitView.m
//  Unity-iPhone
//
//  Created by Andy Zinsser on 9/4/14.
//
//

#import "ArbiterWalletDepositView.h"
#import "ArbiterConstants.h"
#import "ArbiterBundleSelectTableViewDelegate.h"
#import "ArbiterContactInfoTableViewDelegate.h"
#import "ArbiterBillingInfoTableViewDelegate.h"
#import "ArbiterTransactionSuccessTableViewDelegate.h"

#define BUNDLE_SELECT_UI_TAG 667
#define CONTACT_INFO_UI_TAG 668
#define BILLING_INFO_UI_TAG 669
#define GET_BUNDLE_REQUEST_TAG 671
#define POST_DEPOSIT_REQUEST_TAG 672
#define SUCCESS_MESSAGE_UI_TAG 673


@implementation ArbiterWalletDepositView

@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame andArbiterInstance:(Arbiter *)arbiterInstance
{
    self = [super initWithFrame:frame];
    if ( self ) {
        self.arbiter = arbiterInstance;
        self.activeViewIndex = 0;
        [self renderBackButton];
        [self navigateToActiveView];
    }
    return self;
}

- (void)navigateToActiveView
{
    [self removeBundleSelectUI];
    [self removeContactInfoUI];
    [self removeBillingInfoUI];
    
    if ( self.purchaseCompleted ) {
        [self.delegate handleBackButton];
    } else if ( self.activeViewIndex == 0 ) {
        [self setupBundleSelect];
    } else if ( self.activeViewIndex == 1 ) {
        [self setupEmailFieldLayout];
    } else if ( self.activeViewIndex == 2 ) {
        [self setupBillingInfoLayout];
    } else if ( self.activeViewIndex == 3 ) {
        [self getTokenAndSubmitPayment];
    } else if ( self.activeViewIndex == 4 ) {
        [self setupSuccessMessage];
    }
}


# pragma mark Rendering methods

- (void)setupBundleSelect
{
    [self.arbiter.alertWindow addRequestToQueue:GET_BUNDLE_REQUEST_TAG];
    [self.arbiter httpGet:BundleURL handler:[^(NSDictionary *responseDict) {
        NSMutableArray *availableBundles = [[NSMutableArray alloc] initWithArray:[responseDict objectForKey:@"bundles"]];
        ArbiterBundleSelectView *selectView = [[ArbiterBundleSelectView alloc] initWithBundles:availableBundles
                                                                          andSelectionCallback:[^(NSDictionary *selectedBundle) {
            _selectedBundle = selectedBundle;
            self.activeViewIndex++;
            [self navigateToActiveView];
        } copy]];
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 60.0, self.frame.size.width, 180.0) style:UITableViewStyleGrouped];
        [tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [tableView setDelegate:selectView];
        [tableView setDataSource:selectView];
        [tableView setBackgroundColor:[UIColor clearColor]];
        [tableView setBackgroundView:nil];
        [tableView setSeparatorColor:[UIColor clearColor]];
        [tableView reloadData];
        [tableView setTag:BUNDLE_SELECT_UI_TAG];
        [self addSubview:tableView];
        [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont boldSystemFontOfSize:17.0]];
        [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
        [self.arbiter.alertWindow removeRequestFromQueue:GET_BUNDLE_REQUEST_TAG];
    } copy]];
}

- (void)setupEmailFieldLayout
{
    ArbiterContactInfoTableViewDelegate *tableDelegate = [[ArbiterContactInfoTableViewDelegate alloc]
                                                          initWithCallback:[^(NSString *updatedEmail) {
        NSLog(@"updatedEmail is string: %hhd", [self.email isKindOfClass:[NSString class]]);
        if ( [updatedEmail isKindOfClass:[NSString class]]) {
            self.email = updatedEmail;
        }
        NSLog(@"self.email updated to: %@", self.email);
        self.activeViewIndex++;
        [self navigateToActiveView];
    } copy]];
    
    tableDelegate.email = [self.arbiter.user objectForKey:@"email"];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 60.0, self.frame.size.width, 80.0) style:UITableViewStyleGrouped];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [tableView setDelegate:tableDelegate];
    [tableView setDataSource:tableDelegate];
    [tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setBackgroundView:nil];
    [tableView setSeparatorColor:[UIColor clearColor]];
    [tableView reloadData];
    [tableView setAllowsSelection:false];
    [tableView setScrollEnabled:false];
    [tableView setTag:CONTACT_INFO_UI_TAG];
    [self addSubview:tableView];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont boldSystemFontOfSize:17.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
}

- (void)setupBillingInfoLayout
{
    NSString *stripePublishableKey;
    if ( self.stripeView == nil ) {
        if ( [[[self.arbiter game] objectForKey:@"is_live"] boolValue] == true ) {
            stripePublishableKey = StripeLivePublishableKey;
        } else {
            stripePublishableKey = StripeTestPublishableKey;
        }
        self.stripeView = [[STPView alloc] initWithFrame:self.frame andKey:stripePublishableKey];
        self.stripeView.delegate = self;
    }
    ArbiterBillingInfoTableViewDelegate *tableDelegate = [[ArbiterBillingInfoTableViewDelegate alloc]
                                                          initWithStripeView:self.stripeView];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 60.0, self.frame.size.width, 80.0) style:UITableViewStyleGrouped];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [tableView setDelegate:tableDelegate];
    [tableView setDataSource:tableDelegate];
    [tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setBackgroundView:nil];
    [tableView setSeparatorColor:[UIColor clearColor]];
    [tableView reloadData];
    [tableView setAllowsSelection:false];
    [tableView setScrollEnabled:false];
    [tableView setTag:BILLING_INFO_UI_TAG];
    [self addSubview:tableView];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont boldSystemFontOfSize:17.0]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor whiteColor]];
}

- (void)setupSuccessMessage
{
    ArbiterTransactionSuccessTableViewDelegate *tableDelegate = [[ArbiterTransactionSuccessTableViewDelegate alloc]
                                                          initWithCallback:[^(void) {
        [self.delegate handleBackButton];
    } copy]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 60.0, self.frame.size.width, 140.0) style:UITableViewStyleGrouped];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [tableView setDelegate:tableDelegate];
    [tableView setDataSource:tableDelegate];
    [tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setBackgroundView:nil];
    [tableView setSeparatorColor:[UIColor clearColor]];
    [tableView reloadData];
    [tableView setAllowsSelection:false];
    [tableView setScrollEnabled:false];
    [tableView setTag:SUCCESS_MESSAGE_UI_TAG];
    [self addSubview:tableView];
}

- (void)renderNextButton
{
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    float btnWidth = 50.0;
    float btnHeight = 50.0;
    [nextButton setFrame:CGRectMake(self.bounds.size.width - btnWidth, 5.0, btnWidth, btnHeight)];
    [nextButton setTitle:@"Submit" forState:UIControlStateNormal];
    [nextButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    [nextButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [nextButton setTag:BILLING_INFO_UI_TAG];
    [self addSubview:nextButton];
}

- (void)renderBackButton
{
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    float btnWidth = 50.0;
    float btnHeight = 50.0;
    [backButton setFrame:CGRectMake(0.0, 5.0, btnWidth, btnHeight)];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    [backButton.titleLabel setTextAlignment:NSTextAlignmentLeft];
    [backButton.titleLabel setFont:[UIFont systemFontOfSize:17.0]];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:backButton];
}

- (void)removeBundleSelectUI
{
    for (UIView *view in [self subviews]) {
        if (view.tag == BUNDLE_SELECT_UI_TAG) {
            [view removeFromSuperview];
        }
    }
}

- (void)removeContactInfoUI
{
    for ( UIView *view in [self subviews] ) {
        if ( view.tag == CONTACT_INFO_UI_TAG ) {
            [view removeFromSuperview];
        }
    }
}

- (void)removeBillingInfoUI
{
    for ( UIView *view in [self subviews] ) {
        if ( view.tag == BILLING_INFO_UI_TAG ) {
            [view removeFromSuperview];
        }
    }
}


# pragma mark Click Handlers

- (void)nextButtonClicked:(id)sender
{
    self.activeViewIndex++;
    [self navigateToActiveView];
}

- (void)backButtonClicked:(id)sender
{
    if ( self.activeViewIndex == 0 ) {
        [self.delegate handleBackButton];
    } else {
        self.activeViewIndex--;
        [self navigateToActiveView];
    }
}

- (void)getTokenAndSubmitPayment
{
    [self.arbiter.alertWindow addRequestToQueue:POST_DEPOSIT_REQUEST_TAG];
    [self.stripeView createToken:[^(STPToken *stripeToken, NSError *error) {
        if (error) {
            [self.arbiter.alertWindow removeRequestFromQueue:POST_DEPOSIT_REQUEST_TAG];
            [self handleError:[error localizedDescription]];
        } else {
            NSString *token = stripeToken.tokenId;
            NSString *bundleSku = [_selectedBundle objectForKey:@"sku"];
            NSString *emailValue = self.email;
            
            NSLog(@"emailValue: %@", emailValue);
            
            NSDictionary *params = @{@"card_token": token,
                                     @"bundle_sku": bundleSku,
                                     @"email": emailValue};
            [self.arbiter httpPost:APIDepositURL params:params handler:[^(NSDictionary *responseDict) {
                [self.arbiter.alertWindow removeRequestFromQueue:POST_DEPOSIT_REQUEST_TAG];
                if ([[responseDict objectForKey:@"errors"] count]) {
                    [self handleError:[[responseDict objectForKey:@"errors"] objectAtIndex:0]];
                } else {
                    self.activeViewIndex++;
                    [self navigateToActiveView];
                    self.purchaseCompleted = YES;
                }
            } copy]];
        }
    } copy]];
}


# pragma mark Stripe View Delegate Methods

- (void)stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid
{
    [self renderNextButton];
}

- (void)handleError:(NSString *)error
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:error
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    [message show];
}

@end
