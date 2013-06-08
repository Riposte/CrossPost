//
//  RPSTCrossPostManager.m
//  CrossPost
//
//  Created by Jamin Guy on 2/23/13.
//  Copyright (c) 2013 Riposte, LLC. All rights reserved.
//

#import "RPSTCrossPostManager.h"

#import <Accounts/Accounts.h>

#import "RPSTCrossPostAccount.h"

@interface RPSTCrossPostManager ()

@property (nonatomic, strong) NSArray *accounts;
@property (copy, nonatomic) NSString *facebookAppID;

@end

@implementation RPSTCrossPostManager

+ (RPSTCrossPostManager *)sharedInstance {
    static id sharedID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedID = [[self alloc] init];
    });
    return sharedID;
}

- (id)initWithFacebookAppID:(NSString *)facebookAppID {
    self = [self init];
    if(self) {
        _facebookAppID = [facebookAppID copy];
    }
    return self;
}

- (id)init {
    self = [super init];
    if(self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountStoreChanged:) name:ACAccountStoreDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [self loadAccountsAsync];
    }
    return self;
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self loadAccountsAsync];
}

- (void)accountStoreChanged:(NSNotification *)notification {
    [self loadAccountsAsync];
}

- (void)loadAccountsAsync {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self loadAccounts];
    });
}

- (void)loadAccounts {
    NSMutableArray *mutableAccounts = [[NSMutableArray alloc] init];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    
    //load twitter
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sema1 = dispatch_semaphore_create(0);
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
            if(granted) {
                @synchronized(self) {
                    NSArray *accountsArray = [accountStore accountsWithAccountType:twitterAccountType];
                    [mutableAccounts addObjectsFromArray:accountsArray];
                }
            }
            dispatch_semaphore_signal(sema1);
        }];
        
        dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
    });
    
    //load Facebook
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sema1 = dispatch_semaphore_create(0);
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        NSString *facebookAppID = self.facebookAppID;
        NSDictionary *readOptions = @{ACFacebookAppIdKey : facebookAppID, ACFacebookPermissionsKey : @[@"email"], ACFacebookAudienceKey : ACFacebookAudienceEveryone};
        [accountStore requestAccessToAccountsWithType:facebookAccountType options:readOptions completion:^(BOOL granted, NSError *error) {
            if(granted) {
                NSDictionary *writeOptions = @{ACFacebookAppIdKey : facebookAppID, ACFacebookPermissionsKey : @[@"email"], ACFacebookAudienceKey : ACFacebookAudienceEveryone};
                [accountStore requestAccessToAccountsWithType:facebookAccountType options:writeOptions completion:^(BOOL granted, NSError *error) {
                    if(granted) {
                        @synchronized(self) {
                            NSArray *accountsArray = [accountStore accountsWithAccountType:facebookAccountType];
                            [mutableAccounts addObjectsFromArray:accountsArray];
                        }
                    }
                    dispatch_semaphore_signal(sema1);
                }];
            }
            else {
                dispatch_semaphore_signal(sema1);
            }
        }];
        dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
    });
    
    //load Sina Weibo
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_t sema1 = dispatch_semaphore_create(0);
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *sinaWeiboAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierSinaWeibo];
        [accountStore requestAccessToAccountsWithType:sinaWeiboAccountType options:nil completion:^(BOOL granted, NSError *error) {
            if(granted) {
                @synchronized(self) {
                    NSArray *accountsArray = [accountStore accountsWithAccountType:sinaWeiboAccountType];
                    [mutableAccounts addObjectsFromArray:accountsArray];
                }
            }
            dispatch_semaphore_signal(sema1);
        }];
        dispatch_semaphore_wait(sema1, DISPATCH_TIME_FOREVER);
    });
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    [self blowsertAccounts:mutableAccounts];
}

- (void)blowsertAccounts:(NSArray *)acAccounts {
    NSMutableArray *mutableAccounts = [[NSMutableArray alloc] initWithCapacity:acAccounts.count];
    for (ACAccount *acAccount in acAccounts) {
        RPSTCrossPostAccount *rpstAccount = [self rpstAccountForACAccount:acAccount];
        [mutableAccounts addObject:rpstAccount];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.accounts = mutableAccounts;
    });
}

- (RPSTCrossPostAccount *)rpstAccountForACAccount:(ACAccount *)acAccount {
    RPSTCrossPostAccount *matchingAccount = nil;
    for (RPSTCrossPostAccount *rpstAccount in self.accounts) {
        if([rpstAccount.identifier isEqualToString:acAccount.identifier]) {
            matchingAccount = rpstAccount;
            matchingAccount.acAccount = acAccount;
            break;
        }
    }
    
    if(matchingAccount == nil) {
        matchingAccount = [[RPSTCrossPostAccount alloc] initWithAccount:acAccount];
    }
    return matchingAccount;
}

//			if ([accountsArray count] > 0) {
//				ACAccount *twitterAccount = [accountsArray objectAtIndex:0];
//
//				// Create a request, which in this example, posts a tweet to the user's timeline.
//				// This example uses version 1 of the Twitter API.
//				// This may need to be changed to whichever version is currently appropriate.
//				TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] parameters:[NSDictionary dictionaryWithObject:@"Hello. This is a tweet." forKey:@"status"] requestMethod:TWRequestMethodPOST];
//
//				[postRequest setAccount:twitterAccount];
//
//				[postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//					NSString *output = [NSString stringWithFormat:@"HTTP response status: %i", [urlResponse statusCode]];
//					[self performSelectorOnMainThread:@selector(displayText:) withObject:output waitUntilDone:NO];
//				}];
//			}
@end
