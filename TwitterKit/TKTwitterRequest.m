//
//  TwitterRequest.m
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "TKTwitterRequest.h"
#import "TKTwitterOAuthSignature.h"
#import "NSDictionary+TKTwitterRequestHelpers.h"

#pragma mark - NSURL private category

@interface NSURL (TKTwitterRequestPrivateHelpers)
- (NSURL *)_URLByAppendingGETParameters:(NSDictionary *)params;
@end

@implementation NSURL (TKTwitterRequestPrivateHelpers)
- (NSURL *)_URLByAppendingGETParameters:(NSDictionary *)params
{
    NSMutableString *s =
        [NSMutableString stringWithString:[self absoluteString]];

    if ([params count]) {
        [s appendString:@"?"];
        [s appendString:[params tk_URLParameterString]];
    }

    return [NSURL URLWithString:s];
}
@end



#pragma mark - TKTwitterRequest implementation

static NSMutableDictionary *classOAuthCredentials_ = nil;

#pragma mark - Private interface

@interface TKTwitterRequest ()
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;

#pragma mark - Request helpers

- (void)performRequest:(NSURLRequest *)request
               handler:(TKRequestHandler)handler;
@end

@implementation TKTwitterRequest

@synthesize url = url_;
@synthesize parameters = parameters_;
@synthesize requestMethod = requestMethod_;

@synthesize consumerKey = consumerKey_;
@synthesize consumerSecret = consumerSecret_;

#pragma mark - Configuration

+ (void)setDefaultConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    if (!classOAuthCredentials_)
        classOAuthCredentials_ = [[NSMutableDictionary alloc] init];

    [classOAuthCredentials_ setValue:key forKey:@"key"];
    [classOAuthCredentials_ setValue:secret forKey:@"secret"];
}

+ (NSString *)defaultConsumerKey
{
    return [classOAuthCredentials_ valueForKey:@"key"];
}

+ (NSString *)defaultConsumerSecret
{
    return [classOAuthCredentials_ valueForKey:@"secret"];
}

#pragma mark - Memory management

- (void)dealloc
{
    [url_ release];
    [parameters_ release];

    [consumerKey_ release];
    [consumerSecret_ release];

    [super dealloc];
}

#pragma mark - Initialization

- (id)initWithURL:(NSURL *)url
       parameters:(NSDictionary *)parameters
    requestMethod:(TKRequestMethod)requestMethod
{
    self = [super init];
    if (self) {
        url_ = [url copy];
        parameters_ = [parameters copy];
        requestMethod_ = requestMethod;
    }

    return self;
}

#pragma mark - OAuth

- (void)setConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    [self setConsumerKey:key];
    [self setConsumerSecret:secret];
}

#pragma mark - Getting an NSURLRequest

- (NSURL *)finalURLWithParameters:(NSDictionary *)parameters
{
    NSURL *url = [self url];

    TKRequestMethod method = [self requestMethod];
    // Note that if the request method is DELETE, Twitter will report a
    // "Could not authenticate with OAuth" error unless the parameters are
    // passed along as the query string.
    if (method == TKRequestMethodGET || method == TKRequestMethodDELETE)
        url = [url _URLByAppendingGETParameters:[self parameters]];

    return url;
}

- (NSMutableURLRequest *)mutableRequestForParameters:(NSDictionary *)parameters
{
    TKRequestMethod method = [self requestMethod];
    NSURL *url = [self finalURLWithParameters:[self parameters]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (method == TKRequestMethodPOST) {
        NSString *bodyString = [[self parameters] tk_URLParameterString];
        NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:body];
    }
    [request setHTTPMethod:[NSString stringForRequestMethod:method]];

    return request;
}

- (NSURLRequest *)signedRequestWithOAuthToken:(NSString *)token
                                  tokenSecret:(NSString *)tokenSecret
{
    NSString *consumerKey =
        [self consumerKey] ?
        [self consumerKey] : [[self class] defaultConsumerKey];
    NSString *consumerSecret =
        [self consumerSecret] ?
        [self consumerSecret] : [[self class] defaultConsumerSecret];

    NSMutableDictionary *params =
        [NSMutableDictionary dictionaryWithDictionary:[self parameters]];
    [params setObject:token forKey:@"oauth_token"];

    NSMutableURLRequest *request = [self mutableRequestForParameters:params];

    TKTwitterOAuthSignature *sig =
        [[TKTwitterOAuthSignature alloc] initWithConsumerKey:consumerKey
                                              consumerSecret:consumerSecret
                                                       token:token
                                                 tokenSecret:tokenSecret];
    NSString *header =
        [sig authorizationRequestHeaderForMethod:[self requestMethod]
                                             url:[request URL]
                                      parameters:params];
    [request addValue:header forHTTPHeaderField:@"Authorization"];
    [sig release], sig = nil;

    return request;
}

- (NSURLRequest *)unsignedRequest
{
    return [self mutableRequestForParameters:[self parameters]];
}

#pragma mark - Sending the request

- (void)performUnsignedRequestWithHandler:(TKRequestHandler)handler
{
    [self performRequest:[self unsignedRequest] handler:handler];
}

- (void)performSignedRequestWithOAuthToken:(NSString *)token
                               tokenSecret:(NSString *)tokenSecret
                                   handler:(TKRequestHandler)handler
{
    NSURLRequest *request = [self signedRequestWithOAuthToken:token
                                                  tokenSecret:tokenSecret];
    [self performRequest:request handler:handler];
}

#pragma mark - Request helpers

- (void)performRequest:(NSURLRequest *)request handler:(TKRequestHandler)handler
{
    dispatch_queue_t async_queue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t current_queue = dispatch_get_current_queue();
    dispatch_async(async_queue, ^{
        NSURLResponse *response = nil; NSError *error = nil;
        NSData *data =[NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response
                                                        error:&error];
        dispatch_async(current_queue, ^{
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            handler(httpResponse, data, error);
        });
    });
}

@end
