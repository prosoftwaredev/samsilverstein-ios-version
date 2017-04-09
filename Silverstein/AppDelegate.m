//
//  AppDelegate.m
//  Silverstein
//
//  Created by Alexander Shvetsov on 08/07/2015.
//  Copyright (c) 2015 Yanpix - Shvetsov Alexander. All rights reserved.
//

#import "AppDelegate.h"

#define BASE_URL @"http://ec2-52-25-232-140.us-west-2.compute.amazonaws.com"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        NSLog(@"iOS 8 Requesting permission for push notifications...");
        
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
    else {
        NSLog(@"iOS 7 Registering device for push notifications...");
        
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    
    application.applicationIconBadgeNumber = 0;

    return YES;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIApplicationState state = [application applicationState];

    if (state == UIApplicationStateActive)
    {
        NSLog(@"received a notification while active...");
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notification"
                                                        message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"Reload", nil];
        [alert show];
    }
    else if ((application.applicationState == UIApplicationStateInactive) || (application.applicationState == UIApplicationStateBackground)) {
        // opened from a push notification when the app was on background
        NSLog(@"i received a notification...");
        NSLog(@"Message: %@", [[userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
        NSLog(@"whole data: %@", userInfo);
    }
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (token && (token.length > 0))
    {
        NSLog(@"TOKEN:%@", token);
        
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"deviceToken"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"newToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // Respond to any push notification registration errors here.
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)notification completionHandler:(void (^)())completionHandler
{
    NSLog(@"Received push notification: %@, identifier: %@", notification, identifier); // iOS 8 s
    completionHandler();
}



@end