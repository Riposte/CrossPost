//
//  RPSTCrossPostAccount.h
//  CrossPost
//
//  Created by Jamin Guy on 2/24/13.
//  Copyright (c) 2013 Riposte, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Accounts/Accounts.h>

@interface RPSTCrossPostAccount : NSObject <NSCoding>

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) BOOL crossPostingOn;
@property (nonatomic, strong) ACAccount *acAccount;

- (id)initWithAccount:(ACAccount *)acAccount;

@end
