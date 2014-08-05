//
//  ArbiterPaymentView.m
//  
//
//  Created by Andy Zinsser on 6/24/14.
//
//

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "ArbiterPaymentView.h"
#import "ArbiterConstants.h"
#import "Arbiter.h"

#define BUNDLE_SELECT_TAG 667
#define PAYMENT_INFO_TAG 668
#define EMAIL_FIELD_TAG 668

@implementation ArbiterPaymentView
{
    // Custom Arbiter
    void(^callback)(void);
    CGRect *parentFrame;
    Arbiter *arbiter;
    
    // Picker View
    UIPickerView *pickerView;
    NSMutableArray *dataArray;
    NSMutableDictionary *selectedBundle;
    
    // NSURL Connection
    void(^responseHandler)(NSDictionary *responseDict);
    NSMutableData *responseData;
    
}

- (id)initWithFrame:(CGRect)frame andCallback:(void(^)(void))handler arbiterInstance:(Arbiter *)arbiterInstance
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    BOOL isLandscape = orientation == 3 || orientation == 4 || orientation == 5;
    float trueScreenHeight = [UIScreen mainScreen].bounds.size.height;
    float trueScreenWidth = [UIScreen mainScreen].bounds.size.width;
    float maxWidth = 420.0f;
    float maxHeight = 285.0f;
    
    if ( isLandscape ) {
        trueScreenHeight = [UIScreen mainScreen].bounds.size.width;
        trueScreenWidth = [UIScreen mainScreen].bounds.size.height;
        
        float wrongWidth = frame.size.width;
        float wrongHeight = frame.size.height;
        frame.size.width = wrongHeight;
        frame.size.height = wrongWidth;
    }
    
    if ( frame.size.height > maxHeight ) {
        frame.size.height = maxHeight;
    }
    
    if ( frame.size.width > maxWidth ) {
        frame.size.width = maxWidth;
    }
    
    frame.size.width -= 25.0f;
    frame.size.height -= 25.0f;
    
    self = [super initWithFrame:CGRectMake((trueScreenWidth - frame.size.width) / 2,
                                           (trueScreenHeight - frame.size.height) / 2,
                                           frame.size.width,
                                           frame.size.height)];

    if (self) {
        parentFrame = &(frame);
        arbiter = arbiterInstance;
        callback = handler;
        
        [self setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.95f]];
        [self.layer setCornerRadius:5.0f];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.8];
        [self.layer setShadowRadius:3.0];
        [self.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
        
        [self animateIn];
        [self setupBundleSelectLayout];
    }
    return self;
}

- (void)setupBundleSelectLayout
{
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 10.0f, self.bounds.size.width, 40.0f)];
    [title setText:@"How many credits would you like?"];
    [title setFont:[UIFont boldSystemFontOfSize:17]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setTag:BUNDLE_SELECT_TAG];
    [self addSubview:title];

    [self renderCancelButton];
    [self renderSelectButton];
    [self renderBundleOptions];
}

- (void)setupEmailFieldLayout
{
    CGRect frame = self.frame;
    frame.size.height = 140.0f;
    frame.origin.y = ([UIScreen mainScreen].bounds.size.height / 2 - frame.size.height) / 2;
    [self setFrame:frame];
    
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 5.0f, self.bounds.size.width, 40.0f)];
    [message setText:@"Would you like a receipt?"];
    [message setFont:[UIFont boldSystemFontOfSize:17]];
    [message setTextAlignment:NSTextAlignmentCenter];
    [message setBackgroundColor:[UIColor clearColor]];
    [message setTag:EMAIL_FIELD_TAG];
    [self addSubview:message];
    
    self.emailField = [[UITextField alloc] initWithFrame:CGRectMake(20.0f, 40.0f, frame.size.width - 25.0f, 45.0f)];
    [self.emailField setBackgroundColor:[UIColor clearColor]];
    [self.emailField setFont:[UIFont boldSystemFontOfSize:17]];
    [self.emailField setPlaceholder:@"Email address (optional)"];
    [self.emailField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.emailField setKeyboardType:UIKeyboardTypeDefault];
    [self.emailField setReturnKeyType:UIReturnKeyDone];
    [self.emailField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.emailField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [self.emailField setDelegate:self];
    [self.emailField setTag:EMAIL_FIELD_TAG];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5.0f, 40.0f, frame.size.width - 10.0f, 45.0f)];
    backgroundImageView.image = [[UIImage imageNamed:@"textfield"]
                                 resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    [backgroundImageView setTag:EMAIL_FIELD_TAG];
    [self addSubview:backgroundImageView];
    [self addSubview:self.emailField];
    [self.emailField becomeFirstResponder];
    
    [self renderSaveEmailButton];
    [self renderCancelButton];
}

- (void)setupBillingInfoLayout
{
    NSString *stripePublishableKey;
    CGRect frame = self.frame;
    frame.size.height = 140.0f;
    frame.origin.y = ([UIScreen mainScreen].bounds.size.height / 2 - frame.size.height) / 2;
    [self setFrame:frame];

    float cardFieldWidth = 290.0f;  // taken from PKView.m
    
    if ( [[[arbiter game] objectForKey:@"is_live"] boolValue] == true ) {
        stripePublishableKey = StripeLivePublishableKey;
    } else {
        stripePublishableKey = StripeTestPublishableKey;
    }
    
    self.stripeView = [[STPView alloc] initWithFrame:CGRectMake((self.frame.size.width - cardFieldWidth) / 2, 40.0f,
                                                                frame.size.width, 40.0f)
                                              andKey:stripePublishableKey];
    self.stripeView.delegate = self;
    [self addSubview:self.stripeView];
    
    UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 5.0f, self.bounds.size.width, 40.0f)];
    [message setText:@"Enter billing details"];
    [message setFont:[UIFont boldSystemFontOfSize:17]];
    [message setTextAlignment:NSTextAlignmentCenter];
    [message setBackgroundColor:[UIColor clearColor]];
    [message setTag:PAYMENT_INFO_TAG];
    [self addSubview:message];
    
    [self renderPurchaseButton];
    [self renderCancelButton];
}


# pragma mark Click Handlers

- (void)cancelButtonClicked:(id)sender
{
    [self animateOut];
}

- (void)selectBundleButtonClicked:(id)sender
{
    NSString *email = [NSString stringWithFormat:@"%@", [arbiter.user objectForKey:@"email"]];
    [self hideBundleSelectUI];
    
    if ( email.length > 0 ) {
        [self setupBillingInfoLayout];
    } else {
        [self setupEmailFieldLayout];
    }
}

- (void)saveEmailButtonClicked:(id)sender
{
    [self hideEmailFieldUI];
    [arbiter.user setObject:self.emailField.text forKey:@"email"];
    [self setupBillingInfoLayout];
}

- (void)purchaseButtonClicked:(id)sender
{
    [self.stripeView createToken:^(STPToken *token, NSError *error) {
        if (error) {
            [self handleError:[error localizedDescription]];
        } else {
            NSLog(@"Received token %@", token.tokenId);
    
            responseHandler = [^(NSDictionary *responseDict) {
                if ([[responseDict objectForKey:@"errors"] count]) {
                    [self handleError:[[responseDict objectForKey:@"errors"] objectAtIndex:0]];
                } else {
                    callback();
                }
            } copy];
            
            NSString *arbiterEmail = [NSString stringWithFormat:@"%@", [arbiter.user objectForKey:@"email"]];
            NSString *receiptEmail;
            
            if ( arbiterEmail.length == 0 ) {
                receiptEmail = self.emailField.text;
            } else {
                receiptEmail = arbiterEmail;
            }
            
            NSDictionary *params = @{@"card_token": token.tokenId,
                                     @"bundle_sku": [selectedBundle objectForKey:@"sku"],
                                     @"email": receiptEmail};

            [arbiter httpPost:APIDepositURL params:params handler:responseHandler];
        }
    }];
}


# pragma mark UI Rendering Methods

- (void)renderSelectButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setFrame:CGRectMake(self.bounds.size.width / 2, self.bounds.size.height - 50, self.bounds.size.width / 2, 50)];
    [button setTitle:@"Next" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [button setTag:BUNDLE_SELECT_TAG];
    [button addTarget:self action:@selector(selectBundleButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, button.frame.size.width, 0.5f);
    topBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
    [button.layer addSublayer:topBorder];

    [self addSubview:button];
}

- (void)renderCancelButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setFrame:CGRectMake(0, self.bounds.size.height - 50, self.bounds.size.width / 2, 50.0f)];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [button setTag:BUNDLE_SELECT_TAG];
    [button.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [button addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, button.frame.size.width, 0.5f);
    topBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
    [button.layer addSublayer:topBorder];
    
    CALayer *rightBorder = [CALayer layer];
    rightBorder.frame = CGRectMake(button.frame.size.width - 0.5f, 0, 0.5f, button.frame.size.height);
    rightBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
    [button.layer addSublayer:rightBorder];
    
    [self addSubview:button];
}

- (void)renderBundleOptions
{
    // Once we get the current bundle prices, display them in a UIPicker
    responseHandler = [^(NSDictionary *responseDict) {
        dataArray = [[NSMutableArray alloc] initWithArray:[responseDict objectForKey:@"bundles"]];
        
        pickerView = [[UIPickerView alloc] init];
        [pickerView setTag:BUNDLE_SELECT_TAG];
        [pickerView setDataSource: self];
        [pickerView setDelegate: self];
        [pickerView setFrame: CGRectMake(0.0f, 40.0f, self.bounds.size.width, 180.0f)];
        pickerView.showsSelectionIndicator = YES;
        
        NSInteger selectedRow = 2;
        [pickerView selectRow:selectedRow inComponent:0 animated:YES];
        selectedBundle = [dataArray objectAtIndex:selectedRow];
        
        [self addSubview: pickerView];
    } copy];
    
    [arbiter httpGet:BundleURL handler:responseHandler];
}

- (void)hideBundleSelectUI
{
    for (UIView *view in [self subviews]) {
        if (view.tag == BUNDLE_SELECT_TAG) {
            [view removeFromSuperview];
        }
    }
}

- (void)hideEmailFieldUI
{
    for ( UIView *view in [self subviews] ) {
        if ( view.tag == EMAIL_FIELD_TAG ) {
            [view removeFromSuperview];
        }
    }
}

- (void)renderSaveEmailButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setFrame:CGRectMake(self.bounds.size.width / 2, self.bounds.size.height - 50, self.bounds.size.width / 2, 50)];
    [button setTitle:@"Next" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [button setTag:EMAIL_FIELD_TAG];
    [button addTarget:self action:@selector(saveEmailButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, button.frame.size.width, 0.5f);
    topBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
    [button.layer addSublayer:topBorder];
    
    [self addSubview:button];

}

- (void)renderPurchaseButton
{
    // Keep it hidden until the payment form is correct
    self.purchaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.purchaseButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.purchaseButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [self.purchaseButton setFrame:CGRectMake(self.bounds.size.width / 2, self.bounds.size.height - 50,
                                              self.bounds.size.width / 2, 50)];
    self.purchaseButton.enabled = false;
    [self.purchaseButton setTag:PAYMENT_INFO_TAG];
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, self.purchaseButton.frame.size.width, 0.5f);
    topBorder.backgroundColor = [[UIColor lightGrayColor] CGColor];
    [self.purchaseButton.layer addSublayer:topBorder];
    [self.purchaseButton addTarget:self action:@selector(purchaseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.purchaseButton];
}


# pragma mark AlertView Esqueue Animations

- (void)animateIn
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                      animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale3 = CATransform3DMakeScale(1.1, 1.1, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:
                            [NSValue valueWithCATransform3D:scale1],
                            [NSValue valueWithCATransform3D:scale2],
                            [NSValue valueWithCATransform3D:scale3],
                            [NSValue valueWithCATransform3D:scale4],
                            nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.5],
                           [NSNumber numberWithFloat:0.9],
                           [NSNumber numberWithFloat:1.0],
                           nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .2;
    
    [self.layer addAnimation:animation forKey:@"popup"];
}

- (void)animateOut
{
    [UIView animateWithDuration:0.2f
                     animations:^{ [self setAlpha:0.0f]; }
                     completion:^(BOOL finished) { callback(); }];
}


# pragma mark Stripe View Delegate Methods

- (void)stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid
{
    self.purchaseButton.enabled = true;
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


# pragma mark Picker Delegate Methods

// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [dataArray count];
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%@ credits for $%@", [self addThousandsSeparatorToString:[[dataArray objectAtIndex:row] objectForKey:@"value"]],
                                                             [[dataArray objectAtIndex:row] objectForKey:@"price"]];
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectedBundle = [dataArray objectAtIndex:row];
}


# pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingMutableLeaves
                                                           error:&error];
    responseHandler(dict);
    responseData = nil;
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection Error");
}

#pragma mark Utility Helpers

- (NSString *)addThousandsSeparatorToString:(NSString *)original
{
    NSNumberFormatter *separatorFormattor = [[NSNumberFormatter alloc] init];
    [separatorFormattor setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [separatorFormattor setNumberStyle: NSNumberFormatterDecimalStyle];
    
    NSNumberFormatter *stringToNumberFormatter = [[NSNumberFormatter alloc] init];
    [stringToNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber *origNumber = [stringToNumberFormatter numberFromString:original];
    
    return [separatorFormattor stringFromNumber:origNumber];
}

- (UIWindow*) getTopApplicationWindow
{
    UIApplication* clientApp = [UIApplication sharedApplication];
    NSArray* windows = [clientApp windows];
    UIWindow* topWindow = nil;
    
    if (windows && [windows count] > 0)
        topWindow = [[clientApp windows] objectAtIndex:0];
    
    return topWindow;
}


@end
