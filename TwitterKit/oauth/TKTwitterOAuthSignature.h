//
//  TwitterOAuthSignature.h
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKRequestMethod.h"

@interface TKTwitterOAuthSignature : NSObject

@property (nonatomic, copy, readonly) NSString *consumerKey;
@property (nonatomic, copy, readonly) NSString *consumerSecret;

@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *tokenSecret;

#pragma mark - Initialization

- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret
                    token:(NSString *)token
              tokenSecret:(NSString *)tokenSecret;

#pragma mark - Getting a signed request

//- (NSURLRequest *)signedRequestForURL:(NSURL *)url
//                           parameters:(NSDictionary *)parameters
//                        requestMethod:(TKRequestMethod)requestMethod;

#pragma mark - Obtaining the authorization request header

- (NSString *)authorizationRequestHeaderForMethod:(TKRequestMethod)requestMethod
                                              url:(NSURL *)url
                                       parameters:(NSDictionary *)parameters;

@end
