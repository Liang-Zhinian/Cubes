//
//  Cube.h
//  Cube
//
//  Created by Stuart Lynch on 09/06/2013.
//  Copyright (c) 2013 UEA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "CC3GLMatrix.h"

@interface Cube : NSObject

@property(nonatomic, readwrite, assign) GLfloat width;
@property(nonatomic, readwrite, assign) UIColor *color;
@property(nonatomic, readonly) CC3GLMatrix      *modelView;

- (id)initWithWidth:(GLfloat)width forProgram:(GLint)programHandle;
- (void)render;

@end
