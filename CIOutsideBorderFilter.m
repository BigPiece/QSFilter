//
//  CIOutsideOBorderFilter.m
//  Taker
//
//  Created by qws on 2018/5/24.
//  Copyright © 2018年 com.pepsin.fork.video_taker. All rights reserved.
//

#import "CIOutsideBorderFilter.h"

@interface CIOutsideBorderFilter()
@property (strong, nonatomic) CIKernel *outsideKernel;
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat right;
@end

@implementation CIOutsideBorderFilter
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (NSDictionary<NSString *,id> *)attributes
{
    NSDictionary *dict = @{
                           kCIAttributeFilterDisplayName: @"CIOutsideBorderFilter",
                           
                           @"inputImage": @{kCIAttributeIdentity: @0,
                                            kCIAttributeClass: @"CIImage",
                                            kCIAttributeDisplayName: @"Image",
                                            kCIAttributeType: kCIAttributeTypeImage},
                           
                           @"inputFocusPoint": @{kCIAttributeIdentity: [CIVector vectorWithCGPoint:(CGPointMake(0.5, 0.5))],
                                             kCIAttributeClass: @"CIVector",
                                             kCIAttributeDefault: [CIVector vectorWithCGPoint:(CGPointMake(0.5, 0.5))],
                                             kCIAttributeDisplayName: @"Focus Point",
                                             kCIAttributeType: kCIAttributeTypeScalar},
                           
                           @"inputBorderEdge": @{kCIAttributeIdentity: [CIVector vectorWithCGRect:(CGRectMake(10, 10, 10, 10))],
                                            kCIAttributeClass: @"CIVector",
                                            kCIAttributeDefault: [CIVector vectorWithCGRect:(CGRectMake(10, 10, 10, 10))],
                                            kCIAttributeDisplayName: @"Border Edge",
                                            kCIAttributeType: kCIAttributeTypeScalar},
                           };
    return dict;
}

- (CIImage *)outputImage
{
    CGRect extent = self.inputImage.extent;
    
    CGRect bigExtent = CGRectMake(0, 0,
                                  extent.size.width + self.left + self.right,
                                  extent.size.height + self.top + self.bottom);
    
    CIImage *img = [self.outsideKernel applyWithExtent:bigExtent roiCallback:^CGRect(int index, CGRect destRect) {
        return destRect;
    } arguments:@[self.inputImage,
                  [CIVector vectorWithX:self.inputFocusPoint.X Y:self.inputFocusPoint.Y],
                  @(self.top),
                  @(self.left),
                  @(self.bottom),
                  @(self.right)]];
    
    CVPixelBufferRef inputPixelBuffer = self.inputImage.pixelBuffer;
    CVPixelBufferRef testPixelBuffer = NULL;
    size_t pw = img.extent.size.width;
    size_t ph = img.extent.size.height;
    OSType pft = CVPixelBufferGetPixelFormatType(inputPixelBuffer);
    NSMutableDictionary *outputPixelBufferAttributes = [NSMutableDictionary dictionary];
    [outputPixelBufferAttributes setObject:@(pft) forKey:(__bridge NSString *) kCVPixelBufferPixelFormatTypeKey];
    [outputPixelBufferAttributes setObject:@(pw) forKey:(__bridge NSString *) kCVPixelBufferWidthKey];
    [outputPixelBufferAttributes setObject:@(ph) forKey:(__bridge NSString *) kCVPixelBufferHeightKey];
    [outputPixelBufferAttributes setObject:@{} forKey:(__bridge NSString *) kCVPixelBufferIOSurfacePropertiesKey];
    CVPixelBufferCreate(kCFAllocatorDefault, pw, ph,pft, (__bridge CFDictionaryRef)outputPixelBufferAttributes, &testPixelBuffer);
    
    CIContext *ctx = [CIContext contextWithOptions:@{kCIContextWorkingFormat : @(kCIFormatRGBAh)}];
    CVPixelBufferLockBaseAddress(testPixelBuffer, 0);
    [ctx render:img toCVPixelBuffer:testPixelBuffer];
    OSType pxielBufferType = CVPixelBufferGetPixelFormatType(testPixelBuffer);
    CIImage *outputImg = [CIImage imageWithCVPixelBuffer:testPixelBuffer options:@{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(pxielBufferType)}];
    self.outputDepthMap = testPixelBuffer;
    CVPixelBufferRetain(testPixelBuffer);
    CVPixelBufferUnlockBaseAddress(testPixelBuffer, 0);
    return outputImg;
}

- (CIKernel *)outsideKernel
{
    NSString *kernelStr = Shader_stringize
    (
     kernel vec4 borderColor(sampler image,vec2 focusRect, float top, float left, float bottom, float right) {
         
         vec2 focusPoint = vec2(focusRect.x,focusRect.y);
         vec4 focusColor = sample(image,focusPoint);
         vec2 samplerSize = samplerSize(image);
         
         vec2 destPoint = destCoord();
         if (destPoint.x < left || destPoint.x > samplerSize.x + left || destPoint.y < top || destPoint.y > samplerSize.y + top) {
             return focusColor;
         } else {
             vec2 samplePoint = samplerTransform(image,vec2(destPoint.x - left,destPoint.y - top));
             vec4 imgColor = sample(image,samplePoint);
             return imgColor;
         }
     }
     );//str
    return [CIKernel kernelWithString:kernelStr];
}

- (CGFloat)top {
    return self.inputBorderEdge.Z;
}

- (CGFloat)left {
    return self.inputBorderEdge.Y;
}

- (CGFloat)bottom {
    return self.inputBorderEdge.X;
}

- (CGFloat)right {
    return self.inputBorderEdge.W;
}


- (NSString *)displayName {
    return @"CIOutsideBorderFilter";
}
@end
