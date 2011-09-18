//
//  TwitterOAuthService.m
//  Twitbit
//
//  Created by John Debay on 7/16/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "TKTwitterOAuthAuthenticator.h"

#import "TKOAHMACSHA1SignatureProvider.h"
#import "NSString+TKOAURLEncodingAdditions.h"
#import "NSError+TKTwitterRequestHelpers.h"

typedef void(^TKConnectionCompletion)(NSURLResponse * response,
                                      NSData *data,
                                      NSError *error);

static NSString *OAUTH_SIGNATURE_METHOD = @"HMAC-SHA1";
static NSString *OAUTH_VERSION = @"1.0";


@interface TKTwitterOAuthAuthenticator ()

- (NSDictionary *)oauthComponentsForParams:(NSDictionary *)params;

- (NSString *)oauthSignatureBase:(NSString *)httpMethod
                         withUrl:(NSString *)url
              andOauthComponents:(NSDictionary *)parts;

- (NSString *)oauthAuthorizationHeader:(NSString *)oauthSignature
                   withOauthComponents:(NSDictionary *)components;

- (NSString *)oauthHeaderForMethod:(NSString *)method
                            andUrl:(NSString *)url
                         andParams:(NSDictionary *)params
                    andTokenSecret:(NSString *)tokenSecret;

- (void)performRequest:(NSURLRequest *)request
            completion:(TKConnectionCompletion)completion;

@end


@implementation TKTwitterOAuthAuthenticator

@synthesize consumerKey = consumerKey_;
@synthesize consumerSecret = consumerSecret_;

#pragma mark - Memory management

- (void)dealloc
{
    [consumerKey_ release];
    [consumerSecret_ release];

    [super dealloc];
}

#pragma mark - Initialization

- (id)initWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    self = [super init];
    if (self) {
        consumerKey_ = [key copy];
        consumerSecret_ = [secret copy];
    }

    return self;
}

#pragma mark - Fetching the token

- (void)fetchTwitterTokenWithCallbackURL:(NSURL *)callbackURL
                              completion:(TKTokenCompletion)tokenCompletion
{
    NSURL *url = [[self class] twitterTokenURL];
    NSDictionary *params =
        [NSDictionary dictionaryWithObject:[callbackURL absoluteString]
                                    forKey:@"oauth_callback"];
	NSString *oauthHeader =
        [self oauthHeaderForMethod:@"POST"
                            andUrl:[url absoluteString]
                         andParams:params
                    andTokenSecret:@""];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req addValue:oauthHeader forHTTPHeaderField:@"Authorization"];

    [self performRequest:req
              completion:
     ^(NSURLResponse *response, NSData *data, NSError *error) {
         NSString *token = nil;
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
         if ([httpResponse statusCode] == 200 && data)
             token = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding]
                      autorelease];
         else
             // jad: Parameters weren't in the response, so just throw
             // up a Twitter error. I'm fixing this bug because I first
             // saw it when getting over capacity messages, so that's
             // the message I'm putting here, whether or not it's actually true.
             error = [NSError tk_twitterOvercapacityError];

         tokenCompletion(token, error);
     }];
}

#pragma mark - Authorizing the token

- (void)authenticateTwitterToken:(NSString *)token
                    withVerifier:(NSString *)verifier
                      completion:(TKCredentialsCompletion)credentialsCompletion
{
    NSURL *url = [[self class] twitterAuthorizationURL];

	// We manually specify the token as a param, because it has not yet been
    // authorized and the automatic state checking wouldn't include it in
    // signature construction or header, since oauthTokenAuthorized is still NO
    // by this point.
	NSDictionary *params =
        [NSDictionary dictionaryWithObjectsAndKeys:
         token, @"oauth_token", verifier, @"oauth_verifier", nil];

    NSString *header = [self oauthHeaderForMethod:@"POST"
                                           andUrl:[url absoluteString]
                                        andParams:params
                                   andTokenSecret:[self consumerSecret]];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req addValue:header forHTTPHeaderField:@"Authorization"];

    [self performRequest:req completion:
     ^(NSURLResponse *response, NSData *data, NSError *error) {
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
         NSMutableDictionary *values = [NSMutableDictionary dictionary];

         if ([httpResponse statusCode] == 200 && data) {
             NSString *s = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
             NSArray *comps = [s componentsSeparatedByString:@"&"];
             [s release], s = nil;

             for (NSString *comp in comps) {
                 NSArray *vals = [comp componentsSeparatedByString:@"="];
                 if ([vals count] == 2)
                     [values setObject:[vals objectAtIndex:1]
                                forKey:[vals objectAtIndex:0]];
                 else {
                     // jad: Parameters weren't in the response, so just throw
                     // up a Twitter error. I'm fixing this bug because I first
                     // saw it when getting over capacity messages, so that's
                     // the message I'm putting here, whether or not it's
                     // actually true.
                     error = [NSError tk_twitterOvercapacityError];
                     break;
                 }
             }
         }

         credentialsCompletion(values, error);
     }];
}

#pragma mark - URLs

+ (NSURL *)twitterTokenURL
{
    return [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
}

+ (NSURL *)authenticationURLForOAuthToken:(NSString *)token
{
    // Add the force_login parameter per recommendation by Twitter here:
    //
    //  http://dev.twitter.com/pages/application-permission-model-faq
    //
    NSString *urlString =
        [NSString stringWithFormat:
         @"https://api.twitter.com/oauth/authorize?%@&force_login=true", token];
    return [NSURL URLWithString:urlString];
}

+ (NSURL *)twitterAuthorizationURL
{
    return [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
}

#pragma mark - Helper methods

- (NSDictionary *)oauthComponentsForParams:(NSDictionary *)params
{
    // Freshen the context. Get a fresh timestamp and calculate a nonce.
	// Nonce algorithm is sha1(timestamp || random), i.e
	// we concatenate timestamp with a random string, and then sha1 it.
	int timestamp = time(NULL);
	NSString *oauthTimestamp = [NSString stringWithFormat:@"%d", timestamp];
	int myRandom = random();
	NSString *oauthNonce =
        [[NSString stringWithFormat:@"%d%d", timestamp, myRandom] tk_sha1];

    NSMutableDictionary *parts = [NSMutableDictionary dictionary];
    [parts setObject:oauthTimestamp forKey:@"oauth_timestamp"];
    [parts setObject:oauthNonce forKey:@"oauth_nonce"];
    [parts setObject:OAUTH_SIGNATURE_METHOD forKey:@"oauth_signature_method"];
    [parts setObject:OAUTH_VERSION forKey:@"oauth_version"];
    [parts setObject:[self consumerKey] forKey:@"oauth_consumer_key"];
	
	if (params)
		[parts addEntriesFromDictionary:params];

    return parts;
}

- (NSString *)oauthSignatureBase:(NSString *)httpMethod
                         withUrl:(NSString *)url
              andOauthComponents:(NSDictionary *)parts
{
	// Sort the base string components and make them into string key=value pairs
	NSMutableArray *normalizedBase =
        [NSMutableArray arrayWithCapacity:[parts count]];
    NSArray *sortedKeys =
        [[parts allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (NSString *key in sortedKeys) {
        NSString *s =
            [NSString stringWithFormat:@"%@=%@", key, [parts objectForKey:key]];
		[normalizedBase addObject:s];
	}
	
	NSString *normalizedRequestParameters =
        [normalizedBase componentsJoinedByString:@"&"];

	// Return the signature base string. Note that the individual parameters
    // must have previously already URL-encoded and here we are encoding them
    // again; thus you will see some double URL-encoding for params. This is
    // normal.
	return [NSString stringWithFormat:@"%@&%@&%@",
            httpMethod,
            [url tk_encodedURLParameterString],
            [normalizedRequestParameters tk_encodedURLParameterString]];
}

/**
 * Given a calculated signature (by this point it is Base64-encoded string) and
 * a set of parameters, return the header value that you will stick in the
 * "Authorization" header.
 */
- (NSString *)oauthAuthorizationHeader:(NSString *)oauthSignature
                   withOauthComponents:(NSDictionary *)components
{
	NSMutableArray *chunks = [NSMutableArray array];

	// First add all the base components.
	[chunks addObject:[NSString stringWithString:@"OAuth realm=\"\""]];

    for (NSString *part in components) {
        NSString *value = [components valueForKey:part];
        NSString *s =
            [NSString stringWithFormat:@"%@=\"%@\"", part,
             /*[*/value /*encodedURLParameterString]*/];
        [chunks addObject:s];
    }

	// Signature will be the last component of our header.
    NSString *signature =
        [NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature",
         [oauthSignature tk_encodedURLParameterString]];
	[chunks addObject:signature];

	return [NSString stringWithFormat:@"%@",
            [chunks componentsJoinedByString:@", "]];
}



- (NSString *)oauthHeaderForMethod:(NSString *)method
                            andUrl:(NSString *)url
                         andParams:(NSDictionary *)params
                    andTokenSecret:(NSString *)tokenSecret
{
	TKOAHMACSHA1SignatureProvider *sigProvider =
        [[[TKOAHMACSHA1SignatureProvider alloc] init] autorelease];

	// If there were any params, URLencode them.
    NSMutableDictionary *encodedParams =
        [NSMutableDictionary dictionaryWithCapacity:[params count]];
	if (params)
		for (NSString *key in [params allKeys]) {
            NSString *s =
                [[params objectForKey:key] tk_encodedURLParameterString];
			[encodedParams setObject:s forKey:key];
		}

    NSString *consumerSecret = [self consumerSecret];
    NSString *secret =
        [NSString stringWithFormat:@"%@&%@", consumerSecret, tokenSecret];

	// Given a signature base and secret key, calculate the signature.
    NSDictionary *components = [self oauthComponentsForParams:encodedParams];
    NSString *clearText = [self oauthSignatureBase:method
                                           withUrl:url
                                andOauthComponents:components];
	NSString *signature = [sigProvider signClearText:clearText
                                          withSecret:secret];

	// Return the authorization header using the signature and parameters
    // (if any).
	return [self oauthAuthorizationHeader:signature
                      withOauthComponents:components];
}

- (void)performRequest:(NSURLRequest *)request
            completion:(TKConnectionCompletion)completion
{
    dispatch_queue_t async_queue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t current_queue = dispatch_get_current_queue();

    dispatch_async(async_queue, ^{
        NSURLResponse *response = nil; NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        dispatch_async(current_queue, ^{
            completion(response, data, error);
        });
    });
}

@end
