//
//  XMLObjectMapper.h
//  Copyright (c) 2014 Justin Driscoll All rights reserved.
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
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@class XMLObjectMapper;


@protocol XMLMappedObject
- (void)mapper:(XMLObjectMapper *)mapper foundString:(NSString *)string forElementNamed:(NSString *)elementName;
@end


@protocol XMLObjectMapperDelegate
- (id <XMLMappedObject>)mapper:(XMLObjectMapper *)mapper startElementNamed:(NSString *)elementName withAttributes:(NSDictionary *)attributes currentObject:(id <XMLMappedObject>)currentObject;
- (void)mapper:(XMLObjectMapper *)mapper endElementNamed:(NSString *)elementName currentObject:(id <XMLMappedObject>)currentObject;
@end


@interface XMLObjectMapper : NSObject

@property (nonatomic, weak) id <XMLObjectMapperDelegate> delegate;

- (id)initWithData:(NSData *)XMLData delegate:(id <XMLObjectMapperDelegate>)delegate;
- (void)mapElementsToObjects;
- (BOOL)inElements:(NSArray *)elementsToCheck;

@end
