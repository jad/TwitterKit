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


#import "NSError+TKTwitterRequestHelpers.h"

@implementation NSError (TKTwitterRequestHelpers)

+ (id)tk_twitterOvercapacityError
{
    // jad: Parameters weren't in the response, so just throw
    // up a Twitter error. I'm fixing this bug because I first
    // saw it when getting over capacity messages, so that's
    // the message I'm putting here, whether or not it's
    // actually true.
    NSString *key = NSLocalizedDescriptionKey;
    NSString *msg = NSLocalizedString(@"Twitter is over capacity.", nil);
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:key];

    return [NSError errorWithDomain:@"Twitter"
                               code:500
                           userInfo:userInfo];
}

@end
