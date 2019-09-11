//
//  QSSeSanFilter.m
//  QSCamera
//
//  Created by qws on 2019/2/15.
//  Copyright © 2019 qws. All rights reserved.
//

#import "QSSeSanFilter.h"
#import "QSShaderFunc.h"

NSString *const kGPUImageSeSanFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;

 vec2 magAndOffset(vec2 coord, float offset,float scale) {
     return (coord + offset) * scale;
 }

 vec3 blendScreen(vec3 base,vec3 blend) {
     return 1.0 - (1.0 - base) * (1.0- blend);
 }
 
// vec4 addScreen(vec4 base,vec4 overlay,float alpha) {
//     return base * (1.0-alpha) + overlay * alpha;
// }
 
 vec3 addScreen(vec3 base,vec3 overlay,float alpha) {
     return base * (1.0-alpha) + overlay * alpha;
 }
 
 void main()
{
    vec4 color = texture2D(inputImageTexture,textureCoordinate);
    
    vec4 toUseColor = texture2D(inputImageTexture,magAndOffset(textureCoordinate,-0.01,1.1));
    vec4 unRed = vec4(0.0,toUseColor.gb,1.0);
    
    toUseColor = texture2D(inputImageTexture,magAndOffset(textureCoordinate,-0.02,1.1));
    vec4 unBlue = vec4(toUseColor.rg,0,1.0);

    toUseColor = texture2D(inputImageTexture,magAndOffset(textureCoordinate,-0.03,1.1));
    vec4 unGreen = vec4(toUseColor.r,0,toUseColor.b,1.0);
    
    vec3 outColor = color.rgb;
    outColor = addScreen(color.rgb,unRed.rgb,0.33);
    outColor = addScreen(outColor.rgb,unBlue.rgb,0.33);
    outColor = addScreen(outColor.rgb,unGreen.rgb,0.33);
    
    gl_FragColor = vec4(outColor,1.0);
}
 );

@interface QSSeSanFilter()
{
    GLuint otherTexture;
}
@end

@implementation QSSeSanFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageSeSanFragmentShaderString];
    if (self) {

    }
    return self;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {

//    GLuint originTexture = [self.framebufferForOutput texture];
//    glActiveTexture(GL_TEXTURE3);
//    glGenTextures(1, &otherTexture);
//    glBindTexture(GL_TEXTURE_2D, originTexture);
//    glUniform1i(originTexture, 3);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
}

@end
