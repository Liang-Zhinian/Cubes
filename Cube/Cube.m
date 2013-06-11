//
//  Cube.m
//  Cube
//
//  Created by Stuart Lynch on 09/06/2013.
//  Copyright (c) 2013 UEA. All rights reserved.
//

#import "Cube.h"

typedef struct{
    GLfloat Position[3];
    GLfloat Color[4];
} Vertex;

typedef struct {
    GLubyte Face[3];
} TriangleFace;

@interface Cube ()
{
    Vertex *_vertices;
    TriangleFace *_indices;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    
    GLuint _modelViewUniform;
}
@end

@implementation Cube

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle
//////////////////////////////////////////////////////////////////////////

- (id)initWithWidth:(GLfloat)width forProgram:(GLint)programHandle
{
    if ((self = [super init]) != nil)
    {
        _width = width;
        _vertices = malloc(sizeof(Vertex)*8);
        _indices = malloc(sizeof(TriangleFace)*2*6);
        _modelView = [[CC3GLMatrix matrix] retain];
        
        self.color = [UIColor orangeColor];
        [self __setupVertices];
        [self __setupIndices];
        [self __setupVBOs];
        
        _positionSlot = glGetAttribLocation(programHandle, "Position");
        _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
        
        glEnableVertexAttribArray(_positionSlot);
        glEnableVertexAttribArray(_colorSlot);
        
        _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");
    }
    return self;
}

- (void)dealloc
{
    glDisableVertexAttribArray(_positionSlot);
    glDisableVertexAttribArray(_colorSlot);
    free(_indices);
    free(_vertices);
    [_modelView release];
    [_color release];
    [super dealloc];
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Overwridden Properties
//////////////////////////////////////////////////////////////////////////

- (void)setWidth:(GLfloat)width
{
    _width = width;
    [self __setupVertices];
    [self __setupVBOs];
}

- (void)setColor:(UIColor *)color
{
    _color = [color retain];
    [self __setupVertices];
    [self __setupVBOs];
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods
//////////////////////////////////////////////////////////////////////////

- (void)render
{
    glUniformMatrix4fv(_modelViewUniform, 1, 0, self.modelView.glMatrix);
    [self __bindVBOs];
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));
    
    glDrawElements(GL_TRIANGLES, 36,GL_UNSIGNED_BYTE, 0);
    
    [self __printError];
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods
//////////////////////////////////////////////////////////////////////////

- (void)__printError
{
    GLenum error = glGetError();
    switch (error)
    {
        case GL_OUT_OF_MEMORY:
        {
            NSLog(@"Out Of Memory");
            break;
        }
        case GL_INVALID_FRAMEBUFFER_OPERATION:
        {
            NSLog(@"Invalid Framebuffer Operation");
            break;
        }
        case GL_INVALID_OPERATION:
        {
            NSLog(@"Invalid Operation");
            break;
        }
        case GL_INVALID_VALUE:
        {
            NSLog(@"Invalid Value");
            break;
        }
        case GL_INVALID_ENUM:
        {
            NSLog(@"Invalid Enum");
            break;
        }
        case GL_NO_ERROR:
        {
            break;
        }
        default:
        {
            NSLog(@"Unknown Error");
            break;
        }
    }

}

- (void)__setupVBOs
{
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    
    glGenBuffers(1, &_vertexBuffer);
    glGenBuffers(1, &_indexBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex)*8, _vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(TriangleFace)*12, _indices, GL_STATIC_DRAW);
}

- (void)__bindVBOs
{
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
}

- (void)__setupVertices
{
    GLfloat w = self.width/2;
    CGColorRef color = [self.color CGColor];
    const CGFloat *components = CGColorGetComponents(color);
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    Vertex vertex0 = {{w, -w, w}, {r, g, b, 1}};
    Vertex vertex1 = {{w, w, w}, {r, g, b, 1}};
    Vertex vertex2 = {{-w, w, w}, {r, g, b, 1}};
    Vertex vertex3 = {{-w, -w, w}, {r, g, b, 1}};
    Vertex vertex4 = {{w, -w, -w}, {r, g, b, 1}};
    Vertex vertex5 = {{w, w, -w}, {r, g, b, 1}};
    Vertex vertex6 = {{-w, w, -w}, {r, g, b, 1}};
    Vertex vertex7 = {{-w, -w, -w}, {r, g, b, 1}};
    
    _vertices[0] = vertex0;
    _vertices[1] = vertex1;
    _vertices[2] = vertex2;
    _vertices[3] = vertex3;
    _vertices[4] = vertex4;
    _vertices[5] = vertex5;
    _vertices[6] = vertex6;
    _vertices[7] = vertex7;
    
    /*
    for (int i=0; i<8; i++)
    {
        Vertex vertex = _vertices[i];
        NSLog(@"{%.2f, %.2f, %.2f}", vertex.Position[0],vertex.Position[1],vertex.Position[2]);
    }
     */
}

- (void)__setupIndices
{
    TriangleFace triFace00 = {0, 1, 2};
    TriangleFace triFace01 = {2, 3, 0};
    TriangleFace triFace02 = {4, 6, 5};
    TriangleFace triFace03 = {4, 7, 6};
    TriangleFace triFace04 = {2, 7, 3};
    TriangleFace triFace05 = {7, 6, 2};
    TriangleFace triFace06 = {0, 4, 1};
    TriangleFace triFace07 = {4, 1, 5};
    TriangleFace triFace08 = {6, 2, 1};
    TriangleFace triFace09 = {1, 6, 5};
    TriangleFace triFace10 = {0, 3, 7};
    TriangleFace triFace11 = {0, 7, 4};
    
    _indices[0]  = triFace00;
    _indices[1]  = triFace01;
    _indices[2]  = triFace02;
    _indices[3]  = triFace03;
    _indices[4]  = triFace04;
    _indices[5]  = triFace05;
    _indices[6]  = triFace06;
    _indices[7]  = triFace07;
    _indices[8]  = triFace08;
    _indices[9]  = triFace09;
    _indices[10] = triFace10;
    _indices[11] = triFace11;
}

@end
