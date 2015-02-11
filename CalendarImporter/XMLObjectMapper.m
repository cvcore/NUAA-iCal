//
//  XMLObjectMapper.m
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

#import "XMLObjectMapper.h"


static inline NSString *strip(NSString *string) {
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}


@interface XMLObjectMapper () <NSXMLParserDelegate>
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableArray *elements;
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, strong) NSMutableString *characters;
@end


@implementation XMLObjectMapper

- (id)initWithData:(NSData *)XMLData delegate:(id <XMLObjectMapperDelegate>)delegate
{
    self = [super init];
    if (self) {
        _parser = [[NSXMLParser alloc] initWithData:XMLData];
        _parser.delegate = self;
        _delegate = delegate;
    }
    return self;
}

- (void)mapElementsToObjects
{
    _elements = [NSMutableArray array];
    _objects = [NSMutableArray array];
    
    [_parser parse];
}

- (BOOL)inElements:(NSArray *)elementsToCheck
{
    NSUInteger index = 0;
    for (NSString *elementToFind in elementsToCheck) {
        NSUInteger i = [self.elements indexOfObject:elementToFind];
        if (i == NSNotFound || i < index) {
            return NO;
        }
        index = i;
    }
    return YES;
}

- (void)clearString
{
    self.characters = nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [self.elements addObject:elementName];
    
    id <XMLMappedObject> object = [self.delegate mapper:self startElementNamed:elementName withAttributes:attributeDict currentObject:[self.objects lastObject]];
    
    if (object) {
        [self.objects addObject:object];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSAssert([[self.elements lastObject] isEqualToString:elementName], @"Attempt to end tag other than the current head.");
    
    [self.elements removeLastObject];
    
    id <XMLMappedObject> currentObject = [self.objects lastObject];
    
    NSString *str = strip(self.characters);
    if (str && [str length]) {
        [currentObject mapper:self foundString:str forElementNamed:elementName];
    }
    
    [self clearString];
    [self.objects removeLastObject];
    
    [self.delegate mapper:self endElementNamed:elementName currentObject:currentObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!_characters) {
        _characters = [[NSMutableString alloc] init];
    }
    
    [_characters appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
    NSString *string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    [self parser:parser foundCharacters:string];
}

@end