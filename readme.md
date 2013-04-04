# TwitterKit
TwitterKit is a lightweight Cocoa library for authenticating and communicating with the [Twitter REST API](https://dev.twitter.com/docs/api). The design draws from Apple's API for communicating with Twitter in iOS 5.

# Requirements
TwitterKit is compatible with __iOS 4.0 and higher__. It should also work on __Mac OS X 10.6 and higher__, but I haven't tested it myself.

# Quick Start
Here's a simple example for fetching a user's timeline. This assumes you've already gone through the steps to authenticate the user, so you already have her OAuth token and token secret.

```
// Using the class method to set the default consumer key and consumer secret to those of
// your app will apply to all subsequent instances of TKTwitterRequest. This can also be
// set on a per-request basis via the -setConsumerKey:consumerSecret: method. The latter
// takes precedence if both are set.
[TKTwitterRequest setDefaultConsumerKey:@"<my app's consumer key>"
                         consumerSecret:@"<my app's consumer secret>"];

NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline"];
TKTwitterRequest *request = [[TKTwitterRequest alloc] initWithURL:url
                                                       parameters:nil
                                                    requestMethod:TKRequestMethodGET];

[request performSignedRequestWithOAuthToken:@"<user's token>"
                                tokenSecret:@"<user's token secret>"
                                    handler:
    ^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        NSString *s = [[NSString alloc] initWithData:responseData
                                            encoding:NSUTF8StringEncoding];
        NSLog(@"%@", s);
        [s release];
    }];
```

# Authenticating
## OAuth Web Flow
Authentication is performed via the OAuth web flow using the `TKTwitterWebFlowAuthenticator` class. (This class does not support Twitter's PIN-based workflow, but I don't think any mobile/desktop apps use that anymore. Feel free to let me know if that assumption is incorrect.)

The high-level process you'll follow is the following:

* Start by obtaining an access token. You'll fetch this by contacting Twitter, providing them with a callback URL used in a subsequent step (explained below).
* When Twitter replies with the access token, you'll use that token to assemble a Twitter authorization URL. You'll redirect the user to that URL -- either in Safari or in an embedded web view within your app -- where the user will be prompted to enter her username and password and explicitly authorize your app to access her account.
* When the user grants access, Twitter will redirect the browser to the callback URL you specified in step 1. Twitter will append query parameters to that URL. From those parameters, you need to extract the token and token verifier (this step is straightforward but is part of TwitterKit).
* You send the extracted token and token verifier to Twitter, and Twitter replies with the user's user ID, screen name, and OAuth token and secret.

It's convoluted, but it's really not that bad to implement. Hopefully the `TKTwitterWebFlowAuthenticator` will help to make it as straightforward as possible.

Walking through this process with example code, first instantiate and initialize an `TKTwitterWebFlowAuthenticator` instance with your app's consumer key and secret:

```
TKTwitterWebFlowAuthenticator *authenticator =
    [[TKTwitterWebFlowAuthenticator alloc] initWithConsumerKey:@"<my app's consumer key>"
                                                consumerSecret:@"<my app's consumer secret>"];
```

Next you need to fetch the access token that you'll use as part of the URL to which you send the user for authentication. To do this, you'll need to provide your callback URL as explained above. You'll also provide a completion block that will be called after the token has been received. This block contains the authorization component of the URL you need to open in a web browser so the user can provide her credentials, or an `NSError` instance should one occur.

```
[authenticator fetchTwitterAccessTokenWithCallbackURL:url
                                     completion:
    ^(NSString *urlQueryString, NSError *error) {
        if (urlQueryString) {
            // send the user to the URL in Safari
            NSURL *tokenURL = 
                [[authenticator class] authorizationURLForQueryString:urlQueryString];
            [[UIApplication sharedApplication] openURL:tokenURL];
        }
    }];
```
Here I've also included the `force_login` parameter, but that's not required. See [Twitter's documentation](https://dev.twitter.com/docs/api/1/get/oauth/authenticate) for more information on allowed parameters.

Once the user has provided her credentials to Twitter and granted permission to your app, Twitter will redirect to your callback URL with some query parameters attached. From those parameters you need to obtain the OAuth token and verifier (straightforward, but left as an exercise to the reader). As the last step, send those to Twitter to receive the user's OAuth credentials:

```
[authenticator authenticateTwitterToken:token
                           withVerifier:verifier
                             completion:
    ^(NSDictionary *credentials, NSError *error) {
        NSLog(@"Credentials: %@", credentials);]
    }]; 
```
The `credentials` dictionary contains the user's user ID and screen name, as well as their OAuth token and secret.

## OAuth XAuth Flow
Unfortunately, TwitterKit doesn't yet support an XAuth authentication flow. This library came out of the needs of my [own apps](http://highorderbit.com), and since they all require direct message access, which is not permitted with XAuth, TwitterKit doesn't provide support for it. This might come in the future (I really mean that!), or, if you want to help out, please do!

# Communicating with the REST API
The `TKTwitterRequest` class creates, authorizes, and sends requests to the Twitter REST API. If you want to manage the connection to Twitter yourself, it can provide you an `NSURLConnection` instance that's initialized, configured, and ready to send.

## Providing Your Application's Consumer Key and Secret
You can provide the OAuth consumer key and consumer secret for your app on either a global basis (applies to all instances of `TKTwitterRequest`) or on an instance basis. If you provide both, the instance credentials are used.

### Global Application Credentials
Setting them globally is straightforward. Just call the `+setDefaultConsumerKey:consumerSecret:` class method:

```
[TKTwitterRequest setDefaultConsumerKey:@"<my app's consumer key>"
                         consumerSecret:@"<my app's consumer secret>"];
```

This will be used by all subsequent `TKTwitterRequest` instances.

### Instance Application Credentials
To set credentials for an individual instance of`TKTwitterRequest`, use the `-setConsumerKey:consumerSecret:` method. I imagine this will rarely be used, but it's there if you need it.

## Instantiating and Sending a Request
You can instantiate a `TKTwitterRequest` as follows:

```
// fetch the most recent 200 tweets of the user's timeline
NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
NSDictionary *params = [NSDictionary dictionaryWithObject:@"200" forKey:@"count"];
TKTwitterRequest *request = [[TKTwitterRequest alloc] initWithURL:url
                                                           params:params
                                                    requestMethod:TKRequestMethodGET];
```

Now that the request has been created, you can send it like so:

```
[request performSignedRequestWithOAuthToken:@"<user's oauth token>"
                                tokenSecret:@"<user's oauth token secret>"
                                 completion:
 ^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
     NSString *s = [[NSString alloc] initWithData:responseData
                                         encoding:NSUTF8StringEncoding];
     NSLog(@"%@", s);
     [s release];
 }];
```

## Instantiating and Sending a POST Request
Creating and sending a POST request is almost identical to sending a GET request (or a DELETE request):

```
NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update"];
NSDictionary *params =
    [NSDictionary dictionaryWithObject:@"Hello, world!" forKey:@"status"];

TKTwitterRequest *request = [[TKTwitterRequest alloc] initWithURL:url
                               parameters:params
                            requestMethod:TKRequestMethodPOST];

[request performSignedRequestWithOAuthToken:@"<user's token>"
                                tokenSecret:@"<user's token secret>"
                                    handler:
    ^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
        NSString *s = [[NSString alloc] initWithData:responseData
                                            encoding:NSUTF8StringEncoding];
        NSLog(@"%@", s);
        [s release];
    }];
```

## Obtaining an NSURLRequest to Send Yourself
If you would rather not delegate the sending of the request to the `TKTwitterRequest` instance, you can use the `TKTwitterRequest` to obtain an `NSURLRequest` instance that's authenticated, configured, and ready to be provided to an `NSURLConnection`.

```
// fetch the most recent 200 tweets of the user's timeline
NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
NSDictionary *params = [NSDictionary dictionaryWithObject:@"200" forKey:@"count"];
TKTwitterRequest *request = [[TKTwitterRequest alloc] initWithURL:url
                                                           params:params
                                                    requestMethod:TKRequestMethodGET];
NSURLRequest *urlRequest =
    [request signedRequestWithOAuthToken:@"<user's oauth token>"
                             tokenSecret:@"<user's oauth token secret>"];
[NSURLConnection connectionWithRequest:urlRequest delegate:self];
```

## Unsigned Requests
Finally, some Twitter REST API methods do not require authentication. Fetching the [public timeline](https://dev.twitter.com/docs/api/1/get/statuses/public_timeline) is one example. To support this, `TKTwitterRequest` includes "unsigned" equivalents of the signed methods. For example, assuming you've set up a request per the examples above, you can send an unsigned request as follows:

```
[request performUnsignedRequestWithCompletion:
 ^(NSHTTPURLResponse *response, NSData *responseData, NSError *error) {
     NSString *s = [[NSString alloc] initWithData:responseData
                                         encoding:NSUTF8StringEncoding];
     NSLog(@"%@", s);
     [s release], s = nil;
 }];
```
Or to obtain an `NSURLRequest` instance to send yourself:
```
NSURLRequest *urlRequest = [request unsignedRequest];
[NSURLConnection connectionWithRequest:urlRequest delegate:self];
```

# JSON and XML Parsing
TwitterKit doesn't parse any XML or JSON itself. There are [tons](https://github.com/johnezang/JSONKit) [of](http://code.google.com/p/json-framework/) [great](https://github.com/TouchCode/TouchJSON) [libraries](https://github.com/gabriel/yajl-objc) [out](https://github.com/TouchCode/TouchXML) [there](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSXMLParser_Class/Reference/Reference.html). You might want to use your favorite. Or you may want to use the latest and greatest super fast library that's going to be released in two weeks. Or you may need to use the proprietary XML library already used in your organization. Or you may want to distribute parsing of multiple simultaneous responses over GCD. Or you may want to implement parsing of the byte stream as it's downloaded from the network to improve performance.

Since the requirements of any individual app can differ greatly from the next, and since two key goals of TwitterKit are to minimize code size and eliminate dependencies, data parsing has been left out. And since in its most common case, parsing JSON is 1 or 2 lines of code using most mainstream libraries, it's not saving you that much work anyway.

# Credits
TwitterKit relies on components from other open source OAuth and Twitter libraries. Rather than include copies of those entire libraries, I extracted the small subsets that were actually used. In those cases, the names of the classes and methods have been changed to avoid any conflicts with code you may already be using. This helps to avoid not only name conflicts, but also version conflicts (what if you're using a newer version of some library that TwitterKit relies on?).

* [__OAuth Consumer__](http://oauth.googlecode.com/svn/code/obj-c/) -- Linked from the [OAuth code page](http://oauth.net/code/). The SHA1 signing of requests is borrowed from this library.
* [__PlainOAuth__](https://github.com/jaanus/PlainOAuth/) -- Much of the OAuth web flow support was inspired by this library. I did borrow some of the base crypto classes from here, though those classes are part of most Objective-C OAuth-related libraries I've encountered.

# Contributing
Any and all contributions in any form are welcome. Please feel free to [file a bug](https://github.com/jad/TwitterKit/issues) if you find one, or (better!), fix the bug and submit a pull request. If you just think part of the design sucks and have a suggestion for improvement, that's great! Please get in touch.

# License
TwitterKit is made available under the MIT license. See the "LICENSE" file included in this project for more information. In cases where I've imported code from other libraries, I've left their original license agreement in place.
