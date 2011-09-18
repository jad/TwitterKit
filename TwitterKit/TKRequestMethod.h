//
//  TRRequestMethod.h
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    TKRequestMethodGET,
    TKRequestMethodPOST,
    TKRequestMethodDELETE
} TKRequestMethod;


@interface NSString (TRRequestMethodHelpers)

+ (id)stringForRequestMethod:(TKRequestMethod)requestMethod;

@end