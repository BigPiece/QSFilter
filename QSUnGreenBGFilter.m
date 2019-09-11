//
//  QSUnGreenBGFilter.m
//  QSCamera
//
//  Created by qws on 2019/2/28.
//  Copyright © 2019 qws. All rights reserved.
//

#import "QSUnGreenBGFilter.h"
#import <OpenGLES/ES2/gl.h>
NSString *const kGPUImageUnGreenFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform highp vec2 tubularisPoint;
 uniform highp float hueOffset;
 uniform highp float swapHueOffset;
 uniform highp float scale;
 uniform highp int lockSelectedColor;
 uniform highp vec4 lockedColor;
 uniform highp vec4 swapColor;

 
 float max3f(float a, float b, float c) {
     float max1 = max(a,b);
     float max2 = max(b,c);
     return max(max1,max2);
 }
 
 float min3f(float a, float b, float c) {
     float min1 = min(a,b);
     float min2 = min(b,c);
     return min(min1,min2);
 }
 
 vec3 rbgToHsv(vec3 rgbColor) {
     float r = rgbColor.r;
     float g = rgbColor.g;
     float b = rgbColor.b;

     float max = max3f(r,g,b);
     float min = min3f(r,g,b);

     float v = max;
     float s = (max - min)/max;
     float h;
     
     if (r == max) {
         h = 0. + (g - b)/(max-min) * 60./360.;
     } else if (g == max) {
         h = 120./360. + (b - r)/(max-min) * 60./360.;
     } else {
         h = 240./360. + (r - g)/(max-min) * 60./360.;
     }

     if(h<0.) h += 1.;

     return vec3(h,s,v);
 }

 vec3 hsvToRgb(vec3 hsvColor) {
     float h = hsvColor.r;
     float s = hsvColor.g;
     float v = hsvColor.b;
     float R;
     float G;
     float B;
     if (s == 0.) {
         R=G=B=0.;
     } else {
         h *= 360.;
         h /= 60.;
         int i = int(h);
         float f = h - float(i);
         float a = v * (1.-s);
         float b = v * (1.-s*f);
         float c = v * (1.-s*(1.-f));
         if (i == 0) {
             R=v;G=c;B=a;
         } else if (i==1) {
             R=b;G=v;B=a;
         }else if (i==2) {
             R=a;G=v;B=c;
         }else if (i==3) {
             R=a;G=b;B=v;
         }else if (i==4) {
             R=c;G=a;B=v;
         }else if (i==5) {
             R=v;G=a;B=b;
         }
     }
     return vec3(R,G,B);
 }
 
 void main()
{
    vec4 outColor = texture2D(inputImageTexture,textureCoordinate);
    vec4 pointColor = texture2D(inputImageTexture,vec2(tubularisPoint.y,1.0-tubularisPoint.x));
    
    if (lockSelectedColor == 1) {
        pointColor = lockedColor;
    }
    
    vec3 pointHSV = rbgToHsv(pointColor.rgb);
    float pH = pointHSV.r;
    float pS = pointHSV.g;
    float pV = pointHSV.b;

    vec3 hsvColor = rbgToHsv(outColor.rgb);
    float h = hsvColor.r;
    float s = hsvColor.g;
    float v = hsvColor.b;

    float hOffset = hueOffset/180.;
    if (h > pH - hOffset && h < pH + hOffset ) { //吸管
        float ret = h * 360. + swapHueOffset;
        if (ret > 360.) {
            ret -= 360.;
        }
        vec3 targetHsv = vec3(ret/360.,s,v);
        vec3 targetRgb = hsvToRgb(targetHsv);
        {
            outColor = vec4(targetRgb,outColor.a); //绿色 -> 白色
        }
    }
    
    //    vec3 testColor = hsvToRgb(vec3(pH,pS,pV));
    //    outColor = vec4(testColor,pointColor.a);
    
    //    if (h >= 35./180. && h <= 77./180.) {//色调
    //        if (s > 50./255. && s < 1.0 ) { //饱和度
    //            //s range 43~255
    //            if (v > 50./255. && v < 0.9 ) { //亮度
    //                //v range 46~255
    //                vec3 targetHsv = vec3(h+120./180.,s,v);
    //                vec3 targetRgb = hsvToRgb(targetHsv);
    //                outColor = vec4(targetRgb,outColor.a); //绿色 -> 白色
    //            }
    //        }
    //    }
    
    
    vec2 rtpt = vec2(0.05*scale,0.05);
    float radius = 0.025;
    vec2 ori = textureCoordinate - rtpt;
    ori.y = ori.y * scale;
    if (sqrt(ori.x*ori.x + ori.y*ori.y) < radius) {
        if (lockSelectedColor != 0) {
            gl_FragColor = lockedColor;
        } else {
            gl_FragColor = pointColor;
        }
    } else {
        gl_FragColor = outColor;
    }
}
 );

@interface QSUnGreenBGFilter()
{
    GLint tudularisPointUniform;
    GLint hueOffsetUniform;
    GLint lockSelectedColorUniform;
    GLint lockedColorUniform;
    GLint scaleUniform;
    GLint swapColorUniform;
    GLint swapHueOffsetUniform;
}
@property (nonatomic, assign) CGFloat scale;
@end


@implementation QSUnGreenBGFilter

- (instancetype)init
{
    self = [super initWithFragmentShaderFromString:kGPUImageUnGreenFragmentShaderString];
    if (self) {
        tudularisPointUniform = [filterProgram uniformIndex:@"tubularisPoint"];
        hueOffsetUniform = [filterProgram uniformIndex:@"hueOffset"];
        lockSelectedColorUniform = [filterProgram uniformIndex:@"lockSelectedColor"];
        lockedColorUniform = [filterProgram uniformIndex:@"lockedColor"];
        scaleUniform = [filterProgram uniformIndex:@"scale"];
        swapColorUniform = [filterProgram uniformIndex:@"swapColor"];
        swapHueOffsetUniform = [filterProgram uniformIndex:@"swapHueOffset"];
        
        self.tubularisPoint = CGPointMake(0.5, 0.5);
        self.hueOffset = 20.;
        self.swapHueOffset = 60.;
        self.lockSelectedColor = YES;
        self.lockedColor = [CIVector vectorWithX:0.5 Y:0.5 Z:0.5 W:0.5];
        self.scale = 1.0;
        self.tubularisLength = 5;
        self.swapColor = [CIVector vectorWithX:0.5 Y:0.5 Z:0.5 W:0.5];
    }
    return self;
}

- (void)setSwapHueOffset:(float)swapHueOffset {
    _swapHueOffset = swapHueOffset;
    [self setFloat:swapHueOffset forUniform:swapHueOffsetUniform program:filterProgram];
}

- (void)setSwapColor:(CIVector *)swapColor {
    _swapColor = swapColor;
    GPUVector4 value;
    value.one = swapColor.X;
    value.two = swapColor.Y;
    value.three = swapColor.Z;
    value.four = swapColor.W;
    [self setVec4:(value) forUniform:swapColorUniform program:filterProgram];
}

- (void)setLockSelectedColor:(BOOL)lockSelectedColor {
    _lockSelectedColor = lockSelectedColor;
    [self setInteger:lockSelectedColor forUniform:lockSelectedColorUniform program:filterProgram];
}

- (void)setLockedColor:(CIVector *)lockedColor {
    _lockedColor = lockedColor;
    GPUVector4 color4;
    color4.one = lockedColor.X;
    color4.two = lockedColor.Y;
    color4.three = lockedColor.Z;
    color4.four = lockedColor.W;
    [self setVec4:color4 forUniform:lockedColorUniform program:filterProgram];
}

- (void)setTubularisPoint:(CGPoint)tubularisPoint {
    _tubularisPoint = tubularisPoint;
    [self setPoint:_tubularisPoint forUniform:tudularisPointUniform program:filterProgram];
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [self useNextFrameForImageCapture];
        self.selectedColor = [self getRGBColorWithPoint:tubularisPoint];
        if (self.lockSelectedColor) {
            self.lockedColor = self.selectedColor;
        }
    });
}

- (CIVector *)getRGBColorWithPoint:(CGPoint)point {
    [GPUImageContext useImageProcessingContext];
    if (!outputFramebuffer) {
        return nil;
    }

    int r = 0,g = 0,b = 0,a = 0;
    GPUImageFramebuffer *frameBuffer = outputFramebuffer;
    [frameBuffer activateFramebuffer]; //每次 read/copy 灯Frambuffer时需要bind
    [frameBuffer lockForReading];
    
//    GLenum internelFormat = self.outputTextureOptions.internalFormat;
//    GLenum type = self.outputTextureOptions.type;
    
    int width          = (int)frameBuffer.size.width;
    int height         = (int)frameBuffer.size.height;
    int bytesPerRow    = (int)frameBuffer.bytesPerRow;
    int extraPixel     = (bytesPerRow - width * 4)/4; //width paded pixel
    int extraW         = width + extraPixel;
    
    int sizeW = self.tubularisLength;
    int sizeH = self.tubularisLength;
    int x = extraW * point.x - sizeW/2;
    int y = height * point.y - sizeH/2;
    
    int pixelCount = sizeW * sizeH;
    GLubyte *target = malloc(sizeof(GLubyte) * pixelCount * 4);
    glReadPixels(x, y, sizeW, sizeH, GL_RGBA, GL_UNSIGNED_BYTE, target);
    
    if (self.tubularisPreview.superview) {
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, target, pixelCount * 4, NULL);
        CGImageRef cgImg = CGImageCreate(sizeW, sizeH, 8, 4 * 8, sizeW * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, provider, NULL, NO, kCGRenderingIntentDefault);
        self.tubularisPreview.image = [UIImage imageWithCGImage:cgImg];
        CFRelease(cgImg);
    }
    
    int pixelIndex = 0;
    while (target[pixelIndex]) {
        r += target[pixelIndex + 0];
        g += target[pixelIndex + 1];
        b += target[pixelIndex + 2];
        a += target[pixelIndex + 3];
        pixelIndex += 4;
    }
    r /= pixelCount;
    g /= pixelCount;
    b /= pixelCount;
    a /= pixelCount;
    
    NSLog(@"px = %f py = %f w = %d h = %d r = %d,g = %d ,b = %d ,a = %d",point.x,point.y,width,height,r,g,b,a);
    [frameBuffer unlockAfterReading];
    
    return [CIVector vectorWithX:r/255. Y:g/255. Z:b/255. W:a/255.];
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    [super setInputSize:newSize atIndex:textureIndex];
    CGSize size = [self sizeOfFBO];
    self.scale = size.width/size.height;
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    [self setFloat:scale forUniform:scaleUniform program:filterProgram];
}

- (void)setHueOffset:(float)hueOffset {
    _hueOffset = hueOffset;
    [self setFloat:hueOffset forUniform:hueOffsetUniform program:filterProgram];
}

- (void)setTubularisLength:(float)tubularisLength {
    _tubularisLength = tubularisLength;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat length = tubularisLength;
        if (self.tubularisPreview.superview && !CGSizeEqualToSize([self sizeOfFBO], CGSizeZero)) {
            CGFloat scale = self.tubularisPreview.superview.bounds.size.width / [self sizeOfFBO].width;
            length = tubularisLength * scale;
        }
        weakSelf.tubularisPreview.frame = CGRectMake(0, 0, length, length);
    });
}

- (UIImageView *)tubularisPreview {
    if (!_tubularisPreview) {
        CGFloat length = self.tubularisLength < 15 ? 15 : self.tubularisLength;
        _tubularisPreview = [[UIImageView alloc] initWithFrame:(CGRectMake(0, 0, length, length))];
        _tubularisPreview.layer.borderColor = [UIColor cyanColor].CGColor;
        _tubularisPreview.layer.borderWidth = 1;
        _tubularisPreview.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _tubularisPreview;
}


@end
