//
//  RPSTCrossPostManager.h
//  CrossPost
//
//  Created by Jamin Guy on 2/23/13.
//  Copyright (c) 2013 Riposte, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPSTCrossPostManager : NSObject

+ (RPSTCrossPostManager *)sharedInstance;

- (id)initWithFacebookAppID:(NSString *)facebookAppID;

@end
