//
// Copyright (c) 2011 John A. Debay
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//


#import <Foundation/Foundation.h>

typedef void(^TKTokenCompletion)(NSString *urlQueryString, NSError *error);
typedef void(^TKCredentialsCompletion)(NSDictionary *creds, NSError *error);

@interface TKTwitterWebFlowAuthenticator : NSObject

@property (nonatomic, copy, readonly) NSString *consumerKey;
@property (nonatomic, copy, readonly) NSString *consumerSecret;

#pragma mark - Initialization

- (id)initWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret;

#pragma mark - Fetching the token

- (void)fetchTwitterAccessTokenWithCallbackURL:(NSURL *)callbackURL
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
