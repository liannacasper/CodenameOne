/*
 * Copyright (c) 2012, Codename One and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Codename One designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Codename One through http://www.codenameone.com/ if you
 * need additional information or have any questions.
 */
#import "FillRect.h"
#import "CodenameOne_GLViewController.h"
#include "xmlvm.h"
#include "TargetConditionals.h"
#ifdef CN1_USE_METAL

@import Metal.MTLArgumentEncoder;
@import Metal.MTLRenderPipeline;
#endif

#if defined(USE_ES2) && !defined(CN1_USE_METAL)
extern GLKMatrix4 CN1modelViewMatrix;
extern GLKMatrix4 CN1projectionMatrix;
extern GLKMatrix4 CN1transformMatrix;
extern int CN1modelViewMatrixVersion;
extern int CN1projectionMatrixVersion;
extern int CN1transformMatrixVersion;
extern GLuint CN1activeProgram;
static GLuint program=0;
static GLuint vertexShader;
static GLuint fragmentShader;
static GLuint modelViewMatrixUniform;
static GLuint projectionMatrixUniform;
static GLuint transformMatrixUniform;
static GLuint colorUniform;
static GLuint vertexCoordAtt;
static GLuint textureCoordAtt;
static int currentCN1modelViewMatrixVersion=-1;
static int currentCN1projectionMatrixVersion=-1;
static int currentCN1transformMatrixVersion=-1;


static NSString *fragmentShaderSrc =
@"precision highp float;\n"
"uniform lowp vec4 uColor;\n"

"void main(){\n"
"   gl_FragColor = uColor; \n"
"}\n";

static NSString *vertexShaderSrc =
@"attribute vec4 aVertexCoord;\n"

"uniform mat4 uModelViewMatrix;\n"
"uniform mat4 uProjectionMatrix;\n"
"uniform mat4 uTransformMatrix;\n"

"void main(){\n"
"   gl_Position = uProjectionMatrix *  uModelViewMatrix * uTransformMatrix * aVertexCoord;\n"
"}";

static GLuint getOGLProgram(){
    if ( program == 0  ){
        program = CN1compileShaderProgram(vertexShaderSrc, fragmentShaderSrc);
        GLErrorLog;
        vertexCoordAtt = glGetAttribLocation(program, "aVertexCoord");
        GLErrorLog;
        
        modelViewMatrixUniform = glGetUniformLocation(program, "uModelViewMatrix");
        GLErrorLog;
        projectionMatrixUniform = glGetUniformLocation(program, "uProjectionMatrix");
        GLErrorLog;
        transformMatrixUniform = glGetUniformLocation(program, "uTransformMatrix");
        GLErrorLog;
        
        colorUniform = glGetUniformLocation(program, "uColor");
        GLErrorLog;
        
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        GLErrorLog;
        
        
    }
    return program;
}

#endif
#ifdef CN1_USE_METAL

static id<MTLRenderPipelineState> renderPipelineState = nil;
static id<MTLRenderPipelineState> getRenderPipelineState() {
    
    if (renderPipelineState == nil) {
        MTLRenderPipelineDescriptor *renderPipelineDescriptor  = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        id<MTLDevice> mtlDevice = [[CodenameOne_GLViewController instance] eaglView].device;
        id <MTLLibrary> lib = [mtlDevice newDefaultLibrary];
        
        renderPipelineDescriptor.vertexFunction = [lib newFunctionWithName:@"FillRectVertexColor"];
        renderPipelineDescriptor.fragmentFunction = [lib newFunctionWithName:@"FillRectFragmentColor"];
        renderPipelineState = [mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error: nil];
    }
    
    return renderPipelineState;
}

#endif

@implementation FillRect



-(id)initWithArgs:(int)c a:(int)a xpos:(int)xpos ypos:(int)ypos w:(int)w h:(int)h {
    color = c;
    alpha = a;
    x = xpos;
    y = ypos;
    width = w;
    height = h;
    return self;
}
#ifdef CN1_USE_METAL

-(void)execute {
    //[UIColorFromRGB(color, alpha) set];
    //CGContextFillRect(context, CGRectMake(x, y, width, height));
    //GlColorFromRGB(color, alpha);
    
    id<MTLRenderCommandEncoder> encoder = [self makeRenderCommandEncoder];
    [encoder setRenderPipelineState:getRenderPipelineState()];
    
}
#elif defined(USE_ES2)
-(void)execute {
    //[UIColorFromRGB(color, alpha) set];
    //CGContextFillRect(context, CGRectMake(x, y, width, height));
    //GlColorFromRGB(color, alpha);
    glUseProgram(getOGLProgram());
    
    float alph = ((float)alpha)/255.0;
    
    GLKVector4 colorV = GLKVector4Make(((float)((color >> 16) & 0xff))/255.0 * alph,
                                       ((float)((color >> 8) & 0xff))/255.0 * alph, ((float)(color & 0xff))/255.0 * alph, alph);
    GLfloat xOffset = 0;
    GLfloat yOffset = 0;
    
#if (TARGET_OS_SIMULATOR)
    xOffset = 0;
    yOffset = 0;
#endif
    
    GLfloat vertexes[] = {
        x+xOffset, y+yOffset,
        x + width, y+yOffset,
        x+xOffset, y + height,
        x + width, y + height
    };
    glEnableVertexAttribArray(vertexCoordAtt);
    GLErrorLog;
    
    if (currentCN1projectionMatrixVersion != CN1projectionMatrixVersion) {
        glUniformMatrix4fv(projectionMatrixUniform, 1, 0, CN1projectionMatrix.m);
        GLErrorLog;
        currentCN1projectionMatrixVersion = CN1projectionMatrixVersion;
    }
    if (currentCN1modelViewMatrixVersion != CN1modelViewMatrixVersion) {
        glUniformMatrix4fv(modelViewMatrixUniform, 1, 0, CN1modelViewMatrix.m);
        GLErrorLog;
        currentCN1modelViewMatrixVersion = CN1modelViewMatrixVersion;
    }
    if (currentCN1transformMatrixVersion != CN1transformMatrixVersion) {
        glUniformMatrix4fv(transformMatrixUniform, 1, 0, CN1transformMatrix.m);
        GLErrorLog;
        currentCN1transformMatrixVersion = CN1transformMatrixVersion;
    }
    glUniform4fv(colorUniform, 1, colorV.v);
    GLErrorLog;
    
    //_glVertexPointer(2, GL_FLOAT, 0, vertexes);
    //GLErrorLog;
    glVertexAttribPointer(vertexCoordAtt, 2, GL_FLOAT, GL_FALSE, 0, vertexes);
    GLErrorLog;
    
    
    //GLErrorLog;
    //_glVertexPointer(2, GL_FLOAT, 0, vertexes);
    //_glEnableClientState(GL_VERTEX_ARRAY);
    //GLErrorLog;
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    //GLErrorLog;
    //_glDisableClientState(GL_VERTEX_ARRAY);
    //GLErrorLog;
    
    glDisableVertexAttribArray(vertexCoordAtt);
    GLErrorLog;
    
    //glUseProgram(CN1activeProgram);
    //GLErrorLog;
}
#else
-(void)execute {
    //[UIColorFromRGB(color, alpha) set];
    //CGContextFillRect(context, CGRectMake(x, y, width, height));
    GlColorFromRGB(color, alpha);
    GLfloat vertexes[] = {
        x, y,
        x + width, y,
        x, y + height,
        x + width, y + height
    };
    
    GLErrorLog;
    _glVertexPointer(2, GL_FLOAT, 0, vertexes);
    _glEnableClientState(GL_VERTEX_ARRAY);
    GLErrorLog;
    _glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    GLErrorLog;
    _glDisableClientState(GL_VERTEX_ARRAY);
    GLErrorLog;
}
#endif

#ifndef CN1_USE_ARC
-(void)dealloc {
    [super dealloc];
}
#endif

-(NSString*)getName {
    return @"FillRect";
}


@end
