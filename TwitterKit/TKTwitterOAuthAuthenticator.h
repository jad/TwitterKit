//
//  TwitterOAuthService.h
//  Twitbit
//
//  Created by John Debay on 7/16/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^TKTokenCompletion)(NSString *urlQueryString, NSError *error);
typedef void(^TKCredentialsCompletion)(NSDictionary *creds, NSError *error);

@interface TKTwitterOAuthAuthenticator : NSObject

@property (nonatomic, copy, readonly) NSString *consumerKey;
@property (nonatomic, copy, readonly) NSString *consumerSecret;

#pragma mark - Initialization

- (id)initWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark - Fetching the token

- (void)fetchTwitterTokenWithCallbackURL:(NSURL *)callbackURL
                              completion:(TKTokenCompletion)completion;

#pragma mark - Authorizing the token

- (void)authenticateTwitterToken:(NSString *)token
                    withVerifier:(NSString *)verifier
                      completion:(TKCredentialsCompletion)completion;

#pragma mark - URLs

+ (NSURL *)twitterTokenURL;
+ (NSURL *)authenticationURLForOAuthToken:(NSString *)token;

+ (NSURL *)twitterAuthorizationURL;

@end
