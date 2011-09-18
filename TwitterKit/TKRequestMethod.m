//
//  TRRequestMethod.m
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "TKRequestMethod.h"

@implementation NSString (TKRequestMethodHelpers)

+ (id)stringForRequestMethod:(TKRequestMethod)requestMethod
{
    NSString *s = nil;

    switch (requestMethod) {
        case TKRequestMethodGET:
            s = @"GET";
            break;
        case TKRequestMethodPOST:
            s = @"POST";
            break;
        case TKRequestMethodDELETE:
            s = @"DELETE";
            break;
    }

    return s;
}

@end
