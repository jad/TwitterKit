//
//  TwitterRequest.h
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKRequestMethod.h"


typedef void(^TKRequestHandler)(NSHTTPURLResponse *response,
                                NSData *responseData,
                                NSError *error);


@interface TKTwitterRequest : NSObject

@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSDictionary *parameters;
@property (nonatomic, assign, readonly) TKRequestMethod requestMethod;

@property (nonatomic, copy, readonly) NSString *consumerKey;
@property (nonatomic, copy, readonly) NSString *consumerSecret;

#pragma mark - Configuration

+ (void)setDefaultConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark - Initialization

- (id)initWithURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
    requestMethod:(TKRequestMethod)requestMethod;

#pragma mark - OAuth

//
// The request will use the default credentials unless specified here
//
- (void)setConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark - Getting a signed request

- (NSURLRequest *)signedRequestWithOAuthToken:(NSString *)token
                                  tokenSecret:(NSString *)tokenSecret;

#pragma mark - Sending the request

- (void)performUnsignedRequestWithHandler:(TKRequestHandler)handler;
- (void)performSignedRequestWithOAuthToken:(NSString *)token
                               tokenSecret:(NSString *)tokenSecret
                                   handler:(TKRequestHandler)handler;

@end
