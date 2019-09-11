//
//  QSThinFaceFilter.m
//  QSCamera
//
//  Created by qws on 2019/3/19.
//  Copyright © 2019 qws. All rights reserved.
//

/* 变形公式。u=变形前的点坐标,x=变形后的点坐标（即当前点）,r=影响半径，c=拖动的起点，m=拖动的终点
 u = x - [(r^2 - (x-c)^2) / (r^2 - (x-c)^2 + (m-c)^2) ]^2 * (m-c);
 
 Divide:
 dis = r^2 - (x-c)^2;
 ==> x - (dis / (dis + (m-c)^2))^2 * (m-c);
 
 Delta = m - c;
 ==> x - (dis/(dis + delta^2 *)^2 * delta;
 
 Add Strength
 ==> x - (dis / (dis + (100/Strength) * delta ^ 2)^2 * delta;
 
 */

#import "QSThinFaceFilter.h"
#define kFaceThinKeyPointArrayLength (26) //Left 3-15 Right 29-17
NSString *const kQSThinFaceFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform highp float aspectRatio;
 uniform highp float strength;
 uniform highp float radius;
 uniform highp float points[212];
 
 uniform highp float leftPoints[kFaceThinKeyPointArrayLength];
 uniform highp float rightPoints[kFaceThinKeyPointArrayLength];
 uniform highp float pointDeltas[kFaceThinKeyPointArrayLength/2];
 
 
 highp vec2 warpPositionToUse(vec2 currentPoint, vec2 contourPointA,  vec2 contourPointB, float radius, float delta, float aspectRatio)
 {
     vec2 positionToUse = currentPoint;
     
     vec2 currentPointToUse = vec2(currentPoint.x, currentPoint.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
     vec2 contourPointAToUse = vec2(contourPointA.x, contourPointA.y * aspectRatio + 0.5 - 0.5 * aspectRatio);
     
     float r = distance(currentPointToUse, contourPointAToUse);
     if(r < radius)
     {
         vec2 dir = normalize(contourPointB - contourPointA);
         float dist = radius * radius - r * r;
         float alpha = dist / (dist + (100./strength) * (r-delta) * (r-delta));
         alpha = alpha * alpha;
         
         positionToUse = positionToUse - alpha * delta * dir;
         
     }
     
     return positionToUse;
     
 }
 
 void main()
{
    vec4 oriColor = texture2D(inputImageTexture,textureCoordinate);
    vec2 positionToUse = textureCoordinate;
    for(int i = 0; i < kFaceThinKeyPointArrayLength/2; i++) {
        positionToUse = warpPositionToUse(positionToUse, vec2(leftPoints[i * 2], leftPoints[i * 2 + 1]), vec2(rightPoints[i * 2], rightPoints[i * 2 + 1]), radius, pointDeltas[i], aspectRatio);
        positionToUse = warpPositionToUse(positionToUse, vec2(rightPoints[i * 2], rightPoints[i * 2 + 1]), vec2(leftPoints[i * 2], leftPoints[i * 2 + 1]), radius, pointDeltas[i], aspectRatio);
    }
    
    //显示所有关键点
    float mym;
    for (int i = 0 ; i < 212; i+=2){
        vec2 facep = vec2(points[i],points[i+1]);
        float dis = distance(textureCoordinate,facep);
        mym = min(dis,mym);
    }
    
    if (mym < 3./1080.) { //show mark points
        gl_FragColor = vec4(0.0,1.0,0.0,1.);
    } else {
        vec4 nColor = texture2D(inputImageTexture, positionToUse);
        gl_FragColor = mix(oriColor,nColor,1.0);
    }
}
 );

@interface QSThinFaceFilter()
{
    //GL
    GLint aspectRatioUniform;
    GLint strengthUniform;
    GLint radiusUniform;
    
    GLint pointsUniform;
    GLint leftPointsUniform;
    GLint rightPointsUniform;
    GLint pointDeltasUniform;
    
    //Class
    GLfloat *_pts;
    GLfloat *_leftPoints;
    GLfloat *_rightPoints;
    GLfloat *_pointDeltas;
    
}
@property (nonatomic, assign) CGFloat aspectRatio;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat deltaIdentsive;

@end

@implementation QSThinFaceFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kQSThinFaceFragmentShaderString];
    if (self) {
        aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
        strengthUniform = [filterProgram uniformIndex:@"strength"];
        radiusUniform = [filterProgram uniformIndex:@"radius"];
        pointsUniform = [filterProgram uniformIndex:@"points"];
        leftPointsUniform = [filterProgram uniformIndex:@"leftPoints"];
        rightPointsUniform = [filterProgram uniformIndex:@"rightPoints"];
        pointDeltasUniform = [filterProgram uniformIndex:@"pointDeltas"];
        
        self.strength = 100 * 0.2;
        self.aspectRatio = 1.0;
        
        _pts = malloc(sizeof(GLfloat) * 212);
        _leftPoints = malloc(sizeof(GLfloat) * kFaceThinKeyPointArrayLength);
        _rightPoints = malloc(sizeof(GLfloat) * kFaceThinKeyPointArrayLength);
        _pointDeltas = malloc(sizeof(GLfloat) * kFaceThinKeyPointArrayLength/2);
    
    }
    return self;
}

- (void)setAspectRatio:(CGFloat)aspectRatio {
    _aspectRatio = aspectRatio;
    [self setFloat:aspectRatio forUniform:aspectRatioUniform program:filterProgram];
}

- (void)setStrength:(CGFloat)strength {
    _strength = strength;
 
    [self setFloat:strength forUniform:strengthUniform program:filterProgram];
}

- (void)setRadius:(CGFloat)radius {
    _radius = radius;
    [self setFloat:radius forUniform:radiusUniform program:filterProgram];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [super setInputSize:newSize atIndex:textureIndex];
    CGSize size = [self sizeOfFBO];
    self.aspectRatio = size.width/size.height;
}

- (void)setLandMarks:(NSArray<NSValue *> *)landMarks {
    _landMarks = landMarks;
    CGSize oriSize = [self rotatedSize:inputTextureSize forIndex:0];

    int loopIdx = 0;
    int allPointsidx = 0;
    int leftIdx = kFaceThinKeyPointArrayLength-1; //左边逆序
    int rightIdx = 0;
    for (NSValue *value in landMarks) {
        CGPoint pt = [value CGPointValue];
        CGPoint normalizedPoint = CGPointMake(pt.x/oriSize.width, pt.y/oriSize.height); //归一化
        _pts[allPointsidx] = normalizedPoint.x;
        _pts[allPointsidx + 1] = normalizedPoint.y;
        allPointsidx += 2;
        
        if (loopIdx >= 3 && loopIdx <= 15 && leftIdx >0 ) {//leftpoint 从下巴到耳朵
            _leftPoints[leftIdx] = normalizedPoint.y;
            _leftPoints[leftIdx - 1] = normalizedPoint.x;
            leftIdx -= 2;
        }
        
        if (loopIdx >= 17 && loopIdx <= 29 && rightIdx < kFaceThinKeyPointArrayLength) { //rightpoint 从下巴到耳朵
            _rightPoints[rightIdx] = normalizedPoint.x;
            _rightPoints[rightIdx + 1] = normalizedPoint.y;
            rightIdx += 2;
        }
        
        loopIdx++;
    }
    [self setFloatArray:_pts length:212 forUniform:pointsUniform program:filterProgram];
    [self setFloatArray:_leftPoints length:kFaceThinKeyPointArrayLength forUniform:leftPointsUniform program:filterProgram];
    [self setFloatArray:_rightPoints length:kFaceThinKeyPointArrayLength forUniform:rightPointsUniform program:filterProgram];
    
    //根据脸大小设置radius
    float r = fabs(_leftPoints[kFaceThinKeyPointArrayLength-1] - _rightPoints[kFaceThinKeyPointArrayLength-1]);
    if (self.strength < 1) {
        r = 0;
    }
    self.radius = r/10;
    
    //设置Delta
    for (int i = 0 ; i<kFaceThinKeyPointArrayLength/2; i++) {
        _pointDeltas[i] = (kFaceThinKeyPointArrayLength/2 - i) * r * 1.7 / [self sizeOfFBO].width;
    }
    [self setFloatArray:_pointDeltas length:kFaceThinKeyPointArrayLength/2 forUniform:pointDeltasUniform program:filterProgram];
}

@end
