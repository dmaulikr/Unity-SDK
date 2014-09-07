//
//  ArbiterFullContactInfoTableViewDelegate.m
//  Unity-iPhone
//
//  Created by Andy Zinsser on 9/7/14.
//
//

#import "ArbiterFullContactInfoTableViewDelegate.h"

#define EMAIL_FIELD_TAG 1
#define NAME_FIELD_TAG 2


@implementation ArbiterFullContactInfoTableViewDelegate

- (id)initWithCallback:(void(^)(NSDictionary *))callbackBlock
{
    self = [super init];
    if ( self ) {
        self.callback = callbackBlock;
    }
    return self;
}


# pragma mark TableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Please enter your contact info";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITextField *field;
    CALayer *topBorder = [CALayer layer];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = [UIColor clearColor];
    
    if ( indexPath.row == 0 ) {
        self.emailField = [[UITextField alloc] initWithFrame:cell.frame];
        field = self.emailField;
        if ( self.email != nil ) {
            field.text = self.email;
        } else {
            field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email"
                                                                          attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        }
        field.tag = EMAIL_FIELD_TAG;
        [field becomeFirstResponder];
    } else {
        self.nameField = [[UITextField alloc] initWithFrame:cell.frame];
        field = self.nameField;
        if ( self.fullName != nil ) {
            field.text = self.fullName;
        } else {
            field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Name as it appears on your debit card"
                                                                          attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        }
        field.tag = NAME_FIELD_TAG;
    }
    
    field.textColor = [UIColor whiteColor];
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.keyboardType = UIKeyboardTypeEmailAddress;
    field.returnKeyType = UIReturnKeyNext;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.delegate = self;
    [cell.contentView addSubview:field];
    
    topBorder.frame = CGRectMake(0.0, 0.0, cell.frame.size.width + 80.0, 0.5f);
    topBorder.backgroundColor = [[UIColor whiteColor] CGColor];
    [cell.contentView.layer addSublayer:topBorder];
    
    return cell;
}


#pragma mark TextField Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( textField.tag == EMAIL_FIELD_TAG ) {
        [self.nameField becomeFirstResponder];
    } else {
        if ( self.email == nil || self.fullName == nil ) {
            NSLog(@"email: %@", self.email);
            NSLog(@"fullname: %@", self.fullName);
        } else {
            self.callback(@{@"email": self.email, @"fullName": self.fullName});
            [textField resignFirstResponder];
        }
    }
    return YES;
}


@end
