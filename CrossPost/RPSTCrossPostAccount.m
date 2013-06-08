//
//  RPSTCrossPostAccount.m
//  CrossPost
//
//  Created by Jamin Guy on 2/24/13.
//  Copyright (c) 2013 Riposte, LLC. All rights reserved.
//

#import "RPSTCrossPostAccount.h"

@implementation RPSTCrossPostAccount

- (id)initWithAccount:(ACAccount *)acAccount {
    self = [super init];
    if(self) {
        _identifier = [acAccount.identifier copy];
        _acAccount = acAccount;
        _crossPostingOn = NO;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", self.acAccount.accountType, self.acAccount.description];
}

@end
