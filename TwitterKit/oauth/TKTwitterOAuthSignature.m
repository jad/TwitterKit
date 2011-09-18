//
//  TwitterOAuthSignature.m
//  Twitbit
//
//  Created by John Debay on 7/18/11.
//  Copyright 2011 High Order Bit. All rights reserved.
//

#import "TKTwitterOAuthSignature.h"

#import "TKOAHMACSHA1SignatureProvider.h"
#import "NSString+TKOAURLEncodingAdditions.h"
#import "NSDictionary+TKTwitterRequestHelpers.h"

static NSString *OAUTH_SIGNATURE_METHOD = @"HMAC-SHA1";
static NSString *OAUTH_VERSION = @"1.0";

@interface TKTwitterOAuthSignature ()

- (NSString *)oauthSignatureBase:(NSString *)httpMethod
                         withUrl:(NSURL *)url
              andOauthComponents:(NSDictionary *)parts;
- (NSString *)oauthAuthorizationHeader:(NSString *)oauthSignature
                   withOauthComponents:(NSDictionary *)components;
- (NSDictionary *)oauthComponentsForParams:(NSDictionary *)params;

@end

@implementation TKTwitterOAuthSignature

@synthesize consumerKey = consumerKey_, consumerSecret = consumerSecret_;
@synthesize token = token_, tokenSecret = tokenSecret_;

#pragma mark - Memory management

- (void)dealloc
{
    [consumerKey_ release];
    [consumerSecret_ release];

    [token_ release];
    [tokenSecret_ release];
    
    [super dealloc];
}

#pragma mark - Initialization

- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret
                    token:(NSString *)token
              tokenSecret:(NSString *)tokenSecret
{
    self = [super init];
    if (self) {
        consumerKey_ = [consumerKey copy];
        consumerSecret_ = [consumerSecret copy];
        token_ = [token copy];
        tokenSecret_ = [tokenSecret copy];
    }

    return self;
}

#pragma mark - Obtaining the authorization request header

- (NSString *)authorizationRequestHeaderForMethod:(TKRequestMethod)requestMethod
                                              url:(NSURL *)url
                                       parameters:(NSDictionary *)parameters
{
	TKOAHMACSHA1SignatureProvider *sigProvider =
        [[[TKOAHMACSHA1SignatureProvider alloc] init] autorelease];

	// If there were any params, URLencode them.
    NSMutableDictionary *encodedParams =
        [NSMutableDictionary dictionaryWithCapacity:[parameters count]];
	if (parameters)
		for (NSString *key in [parameters allKeys]) {
            NSString *val = [parameters objectForKey:key];
			[encodedParams setObject:[val tk_encodedURLParameterString]
                              forKey:key];
		}

    NSString *secret =
        [NSString stringWithFormat:@"%@&%@",
         [self consumerSecret], [self tokenSecret]];

    NSString *method = [NSString stringForRequestMethod:requestMethod];

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

#pragma mark - Helper methods

- (NSString *)oauthSignatureBase:(NSString *)httpMethod
                         withUrl:(NSURL *)url
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

    // need to strip the query parameters from the URL, if any
    NSString *baseUrl = [url absoluteString];
    NSRange where = [baseUrl rangeOfString:[url path]];
    if (!NSEqualRanges(NSMakeRange(NSNotFound, 0), where))
        baseUrl = [baseUrl substringToIndex:where.location + where.length];

    return
        [NSString stringWithFormat:@"%@&%@&%@",
         httpMethod,
         [baseUrl tk_encodedURLParameterString],
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

    for (NSString *key in components) {
        NSString *value = [components valueForKey:key];
        [chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, value]];
    }

	// Signature will be the last component of our header.
    NSString *signature =
        [NSString stringWithFormat:@"%@=\"%@\"", @"oauth_signature",
         [oauthSignature tk_encodedURLParameterString]];
	[chunks addObject:signature];

	return [chunks componentsJoinedByString:@", "];
}

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

@end
