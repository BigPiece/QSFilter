//
//  QSBigEyeFilter.m
//  QSCamera
//
//  Created by qws on 2019/3/21.
//  Copyright © 2019 qws. All rights reserved.
//

#import "QSBigEyeFilter.h"

NSString *const kQSBigEyeFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;

 uniform highp float aspectRatio; // 所处理图像的宽高比
 uniform highp float scaleRatio;// 缩放系数，0无缩放，大于0则放大
 uniform highp float radius;// 缩放算法的作用域半径
 uniform highp vec2 leftEyeCenterPosition; // 左眼控制点，越远变形越小
 uniform highp vec2 rightEyeCenterPosition; // 右眼控制点

vec2 warpPositionToUse(vec2 centerPostion, vec2 currentPosition, float radius, float scaleRatio, float aspectRatio)
 {
     vec2 positionToUse = currentPosition;

     vec2 currentPositionToUse = vec2(currentPosition.x, currentPosition.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
     vec2 centerPostionToUse = vec2(centerPostion.x, centerPostion.y * aspectRatio + 0.5 - 0.5 * aspectRatio);

     float r = distance(currentPositionToUse, centerPostionToUse);

     if(r < radius)
     {
         float alpha = 1.0 - scaleRatio * pow(r / radius - 1.0, 2.0);
         positionToUse = centerPostion + alpha * (currentPosition - centerPostion);
     }
     
     return positionToUse;
 }
 
 void main()
{
    vec2 positionToUse = warpPositionToUse(leftEyeCenterPosition, textureCoordinate, radius, scaleRatio, aspectRatio);
    positionToUse = warpPositionToUse(rightEyeCenterPosition, positionToUse, radius, scaleRatio, aspectRatio);
    
//    float lr = length(textureCoordinate - leftEyeCenterPosition);
//    float rr = length(textureCoordinate - rightEyeCenterPosition);

//    if (lr < 5./1080. || rr < 5./1080.) {
//        gl_FragColor = vec4(1.0);
//    } else {
        gl_FragColor = texture2D(inputImageTexture, positionToUse);
//    }
}
 );

@interface QSBigEyeFilter()
{
    GLint aspectRatioUniform;
    GLint scaleRatioUniform;
    GLint radiusUniform;
    GLint leftEyeCenterPositionUniform;
    GLint rightEyeCenterPositionUniform;
}
@property (nonatomic, assign) CGFloat aspectRatio;

@end


@implementation QSBigEyeFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kQSBigEyeFragmentShaderString];
    if (self) {
        aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
        scaleRatioUniform = [filterProgram uniformIndex:@"scaleRatio"];
        radiusUniform = [filterProgram uniformIndex:@"radius"];
        leftEyeCenterPositionUniform = [filterProgram uniformIndex:@"leftEyeCenterPosition"];
        rightEyeCenterPositionUniform = [filterProgram uniformIndex:@"rightEyeCenterPosition"];
        
        self.scaleRatio = 0.5;
        self.radius = 60./1080.;
    }
    return self;
}

- (void)setAspectRatio:(CGFloat)aspectRatio {
    _aspectRatio = aspectRatio;
    [self setFloat:aspectRatio forUniform:aspectRatioUniform program:filterProgram];
}

- (void)setRadius:(CGFloat)radius {
    _radius = radius;
    [self setFloat:_radius forUniform:radiusUniform program:filterProgram];
}

- (void)setScaleRatio:(CGFloat)scaleRatio {
    _scaleRatio = scaleRatio;
    [self setFloat:scaleRatio forUniform:scaleRatioUniform program:filterProgram];
}

- (void)setLeftEyeCenterPosition:(CGPoint)leftEyeCenterPosition {
    _leftEyeCenterPosition = [self normalizePoint:leftEyeCenterPosition];
    [self setPoint:_leftEyeCenterPosition forUniform:leftEyeCenterPositionUniform program:filterProgram];
}

- (void)setRightEyeCenterPosition:(CGPoint)rightEyeCenterPosition {
    _rightEyeCenterPosition = [self normalizePoint:rightEyeCenterPosition];
    [self setPoint:_rightEyeCenterPosition forUniform:rightEyeCenterPositionUniform program:filterProgram];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [super setInputSize:newSize atIndex:textureIndex];
    CGSize size = [self sizeOfFBO];
    self.aspectRatio = size.width/size.height;
}

- (CGPoint)normalizePoint:(CGPoint)point {
    CGSize oriSize = [self rotatedSize:inputTextureSize forIndex:0];
    point.x /= oriSize.width;
    point.y /= oriSize.height;
    return point;
}

@end
