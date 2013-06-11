//
//  OpenGLESView.m
//  Cube
//
//  Created by Stuart Lynch on 09/06/2013.
//  Copyright (c) 2013 UEA. All rights reserved.
//

#import "OpenGLESView.h"
#import "Cube.h"
#import "CC3GLMatrix.h"
#import "InfiniteScrollView.h"

@interface OpenGLESView ()
{   
    CAEAGLLayer         *_eaglLayer;
    EAGLContext         *_context;
    
    GLuint              _positionSlot;
    GLuint              _colorSlot;
    
    GLuint              _sampleFrameBuffer;
    GLuint              _resolveFrameBuffer;
    
    GLuint              _sampleRenderBuffer;
    GLuint              _colorRenderBuffer;
    
    GLuint              _depthRenderBuffer;
    GLuint              _sampleDepthRenderBuffer;
    
    GLuint              _projectionUniform;
    
    float               _currentRotation;
    GLuint              _programHandle;
    
    Cube                *_cubeTop;
    Cube                *_cubeMiddle;
    Cube                *_cubeBottom;
    
    InfiniteScrollView  *_topScrollView;
    InfiniteScrollView  *_middleScrollView;
    InfiniteScrollView  *_bottomScrollView;
    
    CADisplayLink* _displayLink;
}

@end

@implementation OpenGLESView

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Lifecycle
//////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) != nil)
    {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setup3DObjects];
        [self setupDisplayLink];
        
        _topScrollView = [[InfiniteScrollView alloc] initWithFrame:CGRectMake(frame.size.width/4, 0, frame.size.width/2, frame.size.height/3)];
        
        _middleScrollView = [[InfiniteScrollView alloc] initWithFrame:CGRectMake(frame.size.width/4, frame.size.height/3, frame.size.width/2, frame.size.height/3)];
        
        _bottomScrollView = [[InfiniteScrollView alloc] initWithFrame:CGRectMake(frame.size.width/4, frame.size.height*2/3, frame.size.width/2, frame.size.height/3)];
        
        [self addSubview:_topScrollView];
        [self addSubview:_middleScrollView];
        [self addSubview:_bottomScrollView];
    }
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)setupDisplayLink
{
    _displayLink = [[CADisplayLink displayLinkWithTarget:self selector:@selector(render:)] retain];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer
{    
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glGenRenderbuffers(1, &_sampleRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _sampleRenderBuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, width, height);
}

- (void)setupDepthBuffer
{
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
    
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glGenRenderbuffers(1, &_sampleDepthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _sampleDepthRenderBuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, width, height);
}

- (void)setupFrameBuffer
{
    glGenFramebuffers(1, &_resolveFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _resolveFrameBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER,_colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
    
    glGenFramebuffers(1, &_sampleFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleFrameBuffer);
    glBindRenderbuffer(1, _sampleRenderBuffer);
    glBindRenderbuffer(1, _sampleDepthRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _sampleRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _sampleDepthRenderBuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
}

- (void)setup3DObjects
{
    _cubeTop    = [[Cube alloc] initWithWidth:2.75f forProgram:_programHandle];
    _cubeTop.color = [UIColor colorWithRed:0.7f green:0.8f blue:0.9f alpha:1.0f];
    _cubeMiddle = [[Cube alloc] initWithWidth:2.75f forProgram:_programHandle];
    _cubeMiddle.color = [UIColor colorWithRed:0.5f green:0.6f blue:0.8f alpha:1.0f];
    _cubeBottom = [[Cube alloc] initWithWidth:2.75f forProgram:_programHandle];
    _cubeBottom.color = [UIColor colorWithRed:0.4f green:0.5f blue:0.7f alpha:1.0f];
}

- (void)dealloc
{
    [_context release];
    _context = nil;
    [_topScrollView release];
    [_middleScrollView release];
    [_bottomScrollView release];
    [_displayLink release];
    [_cubeTop release];
    [_cubeMiddle release];
    [_cubeBottom release];
    [super dealloc];
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Methods
//////////////////////////////////////////////////////////////////////////

- (void)render:(CADisplayLink*)displayLink 
{
    glBindFramebuffer(GL_FRAMEBUFFER, _sampleFrameBuffer);
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    glClearColor(0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    [_cubeTop.modelView populateFromTranslation:CC3VectorMake(0,2.8,-7)];
    GLfloat rotation = -_topScrollView.contentOffset.x*90/_topScrollView.frame.size.width;
    [_cubeTop.modelView rotateBy:CC3VectorMake(0, rotation,0)];
    
    [_cubeMiddle.modelView populateFromTranslation:CC3VectorMake(0, 0, -7)];
    rotation = -_middleScrollView.contentOffset.x*90/_middleScrollView.frame.size.width*2;
    [_cubeMiddle.modelView rotateBy:CC3VectorMake(0, rotation,0)];
    
    [_cubeBottom.modelView populateFromTranslation:CC3VectorMake(0, -2.8, -7)];
    rotation = -_bottomScrollView.contentOffset.x*90/_bottomScrollView.frame.size.width*2;
    [_cubeBottom.modelView rotateBy:CC3VectorMake(0, rotation,0)];
    
    
    // 1
    
    
    [_cubeMiddle render];
    [_cubeTop render];
    [_cubeBottom render];
    
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _resolveFrameBuffer);
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _sampleFrameBuffer);
    glResolveMultisampleFramebufferAPPLE();
    
    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0,GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE,2,discards);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)compileShaders
{
    
    // 1
    GLuint vertexShader = [self compileShader:@"VertexShader"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"FragmentShader"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShader);
    glAttachShader(_programHandle, fragmentShader);
    glLinkProgram(_programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(_programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(_programHandle, "Position");
    _colorSlot = glGetAttribLocation(_programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    _projectionUniform = glGetUniformLocation(_programHandle, "Projection");
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

@end
