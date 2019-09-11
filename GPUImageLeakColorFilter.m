//
//  GPUImageLeakColorFilter.m
//  QSCamera
//
//  Created by qws on 2018/12/13.
//  Copyright © 2018 qws. All rights reserved.
//

#import "GPUImageLeakColorFilter.h"

NSString *const kGPUImageLeakColorsFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 uniform float iGlobalTime;
 
 float rand(float x){
     return fract(sin(dot(vec2(x + 47.49, 38.2467 / (x + 2.3)), vec2(12.9898,78.233))) * 43758.5453);
 }
 
 float drawCircle(vec2 uv, vec2 center, float radius)
{
    return 1.0 - smoothstep(0.0, radius, length(uv - center));
}
 
 vec3 blendScreen(vec3 base, vec3 blend) {
     return 1.0-((1.0-base)*(1.0-blend));
 }
 
 //(霓虹)
 vec3 drawLeaks(vec2 _uv,
                vec2 position,
                vec2 speed,
                vec2 size,
                vec2 resolution,
                vec3 color,
                float t,
                vec2 range) {
     vec2 leakst = _uv;
     vec2 newsize = normalize(size);
     newsize /= abs(newsize.x) + abs(newsize.y);
     
     leakst -= .5;                           // 坐标系居中
     leakst.x *= resolution.x/resolution.y;  // 等比例缩放
     
     leakst.x -= position.x;                 // 位置调整x
     leakst.y -= position.y;                 // 位置调整y
     
     leakst.x -= speed.x * t * 10.;          // 运动速率x
     leakst.y -= speed.y * t * 10.;          // 运动速率y
     
     if (newsize.x < newsize.y)              // 大小比例调整
         leakst.y *= newsize.x / newsize.y;
     if (newsize.x > newsize.y)
         leakst.x *= newsize.y / newsize.x;
     
     float angle = atan(leakst.y, leakst.x); // 笛卡尔转极坐标
     float radius = length(leakst);
     
     vec3 finalColor = vec3(smoothstep(range.x, range.y, radius))*color*(1.-t);   // 预设size&上色
     return finalColor;
 }
 
 
 void main()
{
    vec4 baseColor = texture2D(inputImageTexture, textureCoordinate.xy);
    
    vec3 leakColor = drawLeaks(textureCoordinate.xy,
                               vec2(-.5, .5), //position , 中点坐标系 ，landscape模式的xy
                               vec2(.1, -0.1), //开始位置
                               vec2(0.02, 0.01), //速度
                               vec2(16., 9.), //分辨率（比例）
                               vec3(166./255., 66./255., 65./255.)*1.5,//颜色
                               iGlobalTime, //时间
                               vec2(0.3, 0.1)); //范围
    vec4 blendColor = vec4(leakColor,1.0);
    
    gl_FragColor = vec4(blendScreen(baseColor.rgb,blendColor.rgb),1.0);
}
 );

@interface GPUImageLeakColorFilter()
{
    GLfloat iGlobalTimeUniform; // 时间
}
@end

@implementation GPUImageLeakColorFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageLeakColorsFragmentShaderString];
    if (self) {
        iGlobalTimeUniform = [filterProgram uniformIndex:@"iGlobalTime"];
        self.iGlobalTime = 0.;
    }
    return self;
}

- (void)setIGlobalTime:(float)iGlobalTime {
    _iGlobalTime = iGlobalTime;
    [self setFloat:iGlobalTime forUniform:iGlobalTimeUniform program:filterProgram];
}


- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    self.iGlobalTime = arc4random() % 100 / 1000.;
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

@end
