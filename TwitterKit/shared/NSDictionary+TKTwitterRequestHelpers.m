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


#import "NSDictionary+TKTwitterRequestHelpers.h"

@implementation NSDictionary (TKTwitterRequestHelpers)

- (NSString *)tk_URLParameterString
{
    NSMutableString *s = [NSMutableString string];
    [self enumerateKeysAndObjectsUsingBlock:
         ^(id keyObject, id valueObject, BOOL *stop) {
             NSString *key = (NSString *) keyObject;
             NSString *value = (NSString *) valueObject;

             NSStringEncoding encoding = NSUTF8StringEncoding;
             NSString *encodedKey =
                [key stringByAddingPercentEscapesUsingEncoding:encoding];
             NSString *encodedValue =
                [value stringByAddingPercentEscapesUsingEncoding:encoding];
             [s appendFormat:@"%@=%@&", encodedKey, encodedValue];
         }];

    if ([s length] && [s characterAtIndex:[s length] - 1] == '&')
        [s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];

    return s;
}

@end
