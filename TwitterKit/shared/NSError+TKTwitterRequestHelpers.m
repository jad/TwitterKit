//
//  NSError+TKTwitterRequestHelpers.m
//  TwitterKit
//
//  Created by John Debay on 9/16/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "NSError+TKTwitterRequestHelpers.h"

@implementation NSError (TKTwitterRequestHelpers)

+ (id)tk_twitterOvercapacityError
{
    // jad: Parameters weren't in the response, so just throw
    // up a Twitter error. I'm fixing this bug because I first
    // saw it when getting over capacity messages, so that's
    // the message I'm putting here, whether or not it's
    // actually true.
    NSString *key = NSLocalizedDescriptionKey;
    NSString *msg = NSLocalizedString(@"Twitter is over capacity.", nil);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:key];

    return [NSError errorWithDomain:@"Twitter"
                               code:500
                           userInfo:userInfo];
}

@end
