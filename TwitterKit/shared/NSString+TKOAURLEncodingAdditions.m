//
//  NSString+URLEncoding.m
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "NSString+TKOAURLEncodingAdditions.h"

#include <CommonCrypto/CommonDigest.h>

@implementation NSString (TKOAURLEncodingAdditions)

- (NSString *)tk_encodedURLString
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                            (CFStringRef) self,
                                                                            NULL,                   // characters to leave unescaped (NULL = all escaped sequences are replaced)
                                                                            CFSTR("?=&+"),          // legal URL characters to be escaped (NULL = all legal characters are replaced)
                                                                            kCFStringEncodingUTF8); // encoding
	return [result autorelease];
}

- (NSString *)tk_encodedURLParameterString
{
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                            (CFStringRef) self,
                                                                            NULL,
                                                                            CFSTR(":/=,!$&'()*+;[]@#?"),
                                                                            kCFStringEncodingUTF8);
	return [result autorelease];
}

- (NSString *)tk_decodedURLString
{
	NSString *result = (NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                            (CFStringRef) self,
                                                                                            CFSTR(""),
                                                                                            kCFStringEncodingUTF8);
	return [result autorelease];
	
}

- (NSString *)tk_removeQuotes
{
	NSUInteger length = [self length];
	NSString *ret = self;
	if ([self characterAtIndex:0] == '"')
		ret = [ret substringFromIndex:1];

	if ([self characterAtIndex:length - 1] == '"')
		ret = [ret substringToIndex:length - 2];
	
	return ret;
}

- (NSString *)tk_sha1
{
	const char *cStr = [self UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cStr, strlen(cStr), result);
	NSMutableString *s = [NSMutableString stringWithCapacity:20];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
		[s appendFormat:@"%02X", result[i]];

	return [s lowercaseString];
}


@end

