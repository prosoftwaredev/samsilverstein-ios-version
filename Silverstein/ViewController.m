//
//  ViewController.m
//  Silverstein
//
//  Created by Alexander Shvetsov on 08/07/2015.
//  Copyright (c) 2015 Yanpix - Shvetsov Alexander. All rights reserved.
//

#import "MBProgressHUD.h"
#import "ViewController.h"

#define COOKIES @"cookies"

#define BASE_URL @"http://ec2-52-25-232-140.us-west-2.compute.amazonaws.com/"

@interface ViewController ()<UIWebViewDelegate, UIAlertViewDelegate>
{
    NSURL *_lastURL;
}

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.webView setDelegate:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self loadCookies];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@user/login", BASE_URL]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    self.webView.alpha = 0;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)getUsernameCompletionHandler:(void (^)(NSString *__nullable username, NSError *__nullable error))completionHandler
{
    NSURLSession *session          = [NSURLSession sharedSession];
    NSURL *url                     = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@actions/get_auth", BASE_URL]];
    NSURLRequest *request          = [[NSURLRequest alloc] initWithURL:url];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:location];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

        NSLog(@"%@ %@", responseDictionary, [NSString stringWithFormat:@"%@/actions/get_auth", BASE_URL]);

        NSString *keyString = [[responseDictionary valueForKey:@"data"] valueForKey:@"username"];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Value for the first key: %@", keyString);

            completionHandler(keyString, error);
        });
    }];
    [task resume];
}


- (void)sendNotificationsTokenForUsername:(NSString *)username
{
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];

    if (deviceToken && (deviceToken.length > 0))
    {
        NSString *strURL = [NSString stringWithFormat:@"%@/actions/admin/content/notifications/ios/%@/%@/save", BASE_URL, deviceToken, username];

        NSLog(@"%@", strURL);

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strURL]];
        [request setHTTPMethod:@"GET"];
        [request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"content-type"];

        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSLog(@"%@ %@", response, connectionError);

            if (!connectionError)
            {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"newToken"];

                NSLog(@"Doooooone");
            }
        }];
    }
}


#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"scheme: %@", [request URL].absoluteString);

    if ([[request URL].absoluteString isEqualToString:BASE_URL])
    {
        [self getUsernameCompletionHandler:^(NSString *username, NSError *error) {
            if (username && (username.length > 0))
            {
                [self sendNotificationsTokenForUsername:username];
            }
        }];
    }

    _lastURL = request.URL;

    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    dispatch_async (dispatch_get_main_queue (), ^{
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    });
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    webView.alpha = 1;

    dispatch_async (dispatch_get_main_queue (), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });

    [self saveCookies];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    dispatch_async (dispatch_get_main_queue (), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail Load ULR"
                                                    message:error.localizedDescription
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Reload", nil];
    [alert show];
}


#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (_lastURL != nil)
    {
        [self.webView loadRequest:[NSURLRequest requestWithURL:_lastURL]];
    }
}


#pragma mark -

- (void)saveCookies
{
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:cookiesData forKey:COOKIES];
    [defaults synchronize];
}


- (void)loadCookies
{
    NSArray *cookies                   = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:COOKIES]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

    for (NSHTTPCookie *cookie in cookies)
    {
        [cookieStorage setCookie:cookie];
    }
}


@end