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
- (NSURL *)URLByAppendingGetParameters:(NSDictionary *)params;
@end

@implementation NSURL (TKTwitterRequestPrivateHelpers)
- (NSURL *)URLByAppendingGetParameters:(NSDictionary *)params
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

@property (nonatomic, copy, readonly) NSURL *fullUrl;

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSHTTPURLResponse *connectionResponse;
@property (nonatomic, retain) NSMutableData *connectionData;
@property (nonatomic, retain) NSError *connectionError;
@property (nonatomic, copy) TKRequestHandler requestHandler;
@end

@implementation TKTwitterRequest

@synthesize url = url_;
@synthesize parameters = parameters_;
@synthesize requestMethod = requestMethod_;

@synthesize consumerKey = consumerKey_;
@synthesize consumerSecret = consumerSecret_;

@synthesize fullUrl = fullUrl_;

@synthesize connection = connection_;
@synthesize connectionResponse = connectionResponse_;
@synthesize connectionData = connectionData_;
@synthesize connectionError = connectionError_;
@synthesize requestHandler = requestHandler_;

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

    [fullUrl_ release];

    [connection_ cancel];
    [connection_ release];
    [connectionResponse_ release];
    [connectionData_ release];
    [connectionError_ release];
    [requestHandler_ release];

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

#pragma mark - Getting a signed request

- (NSURLRequest *)signedRequestWithOAuthToken:(NSString *)token
                                  tokenSecret:(NSString *)tokenSecret
{
    NSString *consumerKey =
        [self consumerKey] ?
        [self consumerKey] : [[self class] defaultConsumerKey];
    NSString *consumerSecret =
        [self consumerSecret] ?
        [self consumerSecret] : [[self class] defaultConsumerSecret];

    TKTwitterOAuthSignature *sig =
        [[TKTwitterOAuthSignature alloc] initWithConsumerKey:consumerKey
                                              consumerSecret:consumerSecret
                                                       token:token
                                                 tokenSecret:tokenSecret];
    NSURLRequest *req = [sig signedRequestForURL:[self fullUrl]
                                      parameters:[self parameters]
                                   requestMethod:[self requestMethod]];
    [sig release], sig = nil;

    return req;
}

#pragma mark - Sending the request

- (void)performRequestWithHandler:(TKRequestHandler)handler
{
    NSAssert2(0, @"%@: %@ - Not implemented.",
              NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)performSignedRequestWithOAuthToken:(NSString *)token
                               tokenSecret:(NSString *)tokenSecret
                                   handler:(TKRequestHandler)handler
{
    [self setRequestHandler:handler];

    NSURLRequest *request = [self signedRequestWithOAuthToken:token
                                                  tokenSecret:tokenSecret];

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


    /*
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                delegate:self];
    [self setConnection:connection];
     */
}

#pragma mark - Connection events

- (void)processConnectionCompleted
{
    NSHTTPURLResponse *response = [self connectionResponse];
    NSData *data = [self connectionData];
    NSError *error = [self connectionError];

    [self requestHandler](response, data, error);

    [self setConnectionResponse:nil];
    [self setConnectionData:nil];
    [self setConnectionError:nil];
    [self setConnection:nil];
}

#pragma mark - NSURLConnectionDelegate implementation

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    [self setConnectionResponse:(NSHTTPURLResponse *) response];
    [self setConnectionData:[NSMutableData data]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self connectionData] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self processConnectionCompleted];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    [self setConnectionError:error];
    [self processConnectionCompleted];
}

#pragma mark - Accessors

- (NSURL *)fullUrl
{
    if (!fullUrl_) {
        switch ([self requestMethod]) {
            case TKRequestMethodGET:
                fullUrl_ =
                    [[self url] URLByAppendingGetParameters:[self parameters]];
                break;
            case TKRequestMethodPOST:
                fullUrl_ = [self url];
                break;
            default:
                NSAssert1(NO, @"Unknown request method: %d",
                          [self requestMethod]);
                break;
        }
    }

    return fullUrl_;
}

@end
