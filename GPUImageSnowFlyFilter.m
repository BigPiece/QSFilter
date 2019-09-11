//
//  GPUImageSnowFlyFilter.m
//  Taker
//
//  Created by qws on 2018/12/7.
//  Copyright © 2018 com.pepsin.fork.video_taker. All rights reserved.
//

#import "GPUImageSnowFlyFilter.h"

NSString *const kGPUImageSnowFlyFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float iGlobalTime;
 uniform float blizardFactor;
 uniform int snowFlakeAmount;
 
 float rnd(float x)
{
    return fract(
                 sin(
                     dot(
                         vec2(x + 47.49, 38.2467 / (x + 2.3)),
                         vec2(12.9898, 78.233)
                         )
                     ) * (43758.5453)
                 );
}
 
 
 float rand(float x){
     return fract(sin(dot(vec2(x + 47.49, 38.2467 / (x + 2.3)), vec2(12.9898,78.233))) * 43758.5453);
 }
 
 float drawCircle(vec2 uv, vec2 center, float radius)
{
    return 1.0 - smoothstep(0.0, radius, length(uv - center));
}
 
 //非精确，把一个值输出为颜色，r通道存储mod（对255取模）的值，g通道存储余数(除以255)
 vec4 transferValueToColor(float value) {
     float modV = mod(value,255.);
     float yu = floor(value / 255.);
     float valueR = modV /255.;
     float valueG = yu / 255.;
     vec4 color = vec4(valueR,valueG,1.0,1.0);
     return color;
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
    vec4 blendColor = vec4(0.0);

//    vec3 leakColor = drawLeaks(textureCoordinate.xy,
//                               vec2(-.5, .5),
//                               vec2(.1, -0.1),
//                               vec2(.0, .0),
//                               vec2(16., 9.),
////                               vec3(166./255., 66./255., 65./255.)*1.5,
//                               vec3(blendColor.rgb),
//                               iGlobalTime,
//                               vec2(.3, 0.));
//    blendColor = vec4(leakColor,1.0);
//
//    vec4 outputColor = vec4(baseColor.rgb + blendColor.rgb,1.0);
//    outputColor = vec4(blendScreen(baseColor.rgb,blendColor.rgb),1.0);
//    gl_FragColor = outputColor;
//    gl_FragColor = transferValueToColor(float(iGlobalTime));

    float j;
    // 生成若干个圆，当前uv依次与这些圆心计算距离，未落在圆域内则为黑色，落在圆域内则为白色
    for (int i = 0; i < snowFlakeAmount; i++)
    {
        j = float(i);
        // 控制了不同雪花的下落速度 和 雪花的大小
        float speed = 0.3 + rnd(cos(j)) * (0.7 + 0.5 * cos(j / (float(snowFlakeAmount) * 0.25)));

        // x坐标 左右环绕分布的范围
        float x = (-0.25 + textureCoordinate.y) * blizardFactor + rnd(j) + 0.1 * cos(iGlobalTime + sin(j));

        // y坐标  随着时间下降
        float y = mod( rnd(j) - speed * (iGlobalTime * 1.5 * (0.1 + blizardFactor)), 0.95);

        vec2 center = vec2(x,1.-y);
        
        float radius = 0.001 + speed * 0.012;
        blendColor += vec4(0.9 * drawCircle(textureCoordinate.xy,center,radius)); // 输出是这些圆的颜色叠加

    } //for
    gl_FragColor = vec4(blendScreen(baseColor.rgb,blendColor.rgb),1.0);
//    gl_FragColor = blendColor;
}
);



@interface GPUImageSnowFlyFilter()
{
    GLint snowFlakeAmountUniform; // 雪花数
    GLfloat blizardFactorUniform; // 风的大小
    GLfloat iGlobalTimeUniform; // 时间
    double t;
    float x;
    int count;
}

@end

@implementation GPUImageSnowFlyFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageSnowFlyFragmentShaderString];
    if (self) {
        snowFlakeAmountUniform = [filterProgram uniformIndex:@"snowFlakeAmount"];
        blizardFactorUniform = [filterProgram uniformIndex:@"blizardFactor"];
        iGlobalTimeUniform = [filterProgram uniformIndex:@"iGlobalTime"];
        self.snowFlakeAmount = 1;
        self.blizardFactor = 0.;
        self.iGlobalTime = 0.;
    }
    return self;
}

- (void)setSnowFlakeAmount:(int)snowFlakeAmount {
    _snowFlakeAmount = snowFlakeAmount;
    [self setInteger:snowFlakeAmount forUniform:snowFlakeAmountUniform program:filterProgram];
}

- (void)setBlizardFactor:(float)blizardFactor {
    _blizardFactor = blizardFactor;
    [self setFloat:blizardFactor forUniform:blizardFactorUniform program:filterProgram];
}

- (void)setIGlobalTime:(float)iGlobalTime {
    _iGlobalTime = iGlobalTime;
    [self setFloat:iGlobalTime forUniform:iGlobalTimeUniform program:filterProgram];
}


- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    self.iGlobalTime = fmod(CMTimeGetSeconds(frameTime), 600.);
    self.snowFlakeAmount = 10;
    self.blizardFactor = 0.35;
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

@end
