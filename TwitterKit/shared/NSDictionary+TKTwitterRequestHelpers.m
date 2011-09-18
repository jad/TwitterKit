//
//  NSDictionary+TKTwitterRequestHelpers.m
//  TwitterKit
//
//  Created by John Debay on 9/16/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "NSDictionary+TKTwitterRequestHelpers.h"

@implementation NSDictionary (TKTwitterRequestHelpers)

- (NSString *)tk_URLParameterString
{
    NSMutableString *s = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:
         ^(id keyObject, id valueObject, BOOL *stop) {
             NSString *key = (NSString *) keyObject;
             NSString *value = (NSString *) valueObject;

             NSStringEncoding encoding = NSUTF8StringEncoding;
             NSString *encodedKey =
                [key stringByAddingPercentEscapesUsingEncoding:encoding];
             NSString *encodedValue =
                [value stringByAddingPercentEscapesUsingEncoding:encoding];
             [s appendFormat:@"%@=%@&", encodedKey, encodedValue];
         }];

    if ([s length] && [s characterAtIndex:[s length] - 1] == '&')
        [s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];

    return s;
}

@end
