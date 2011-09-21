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

- (NSURLRequest *)unsignedRequest;
- (NSURLRequest *)signedRequestWithOAuthToken:(NSString *)token
                                  tokenSecret:(NSString *)tokenSecret;

#pragma mark - Sending the request

- (void)performUnsignedRequestWithCompletion:(TKRequestHandler)completion;
- (void)performSignedRequestWithOAuthToken:(NSString *)token
                               tokenSecret:(NSString *)tokenSecret
                                completion:(TKRequestHandler)completion;

@end
