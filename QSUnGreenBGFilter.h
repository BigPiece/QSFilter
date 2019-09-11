//
//  QSUnGreenBGFilter.h
//  QSCamera
//
//  Created by qws on 2019/2/28.
//  Copyright © 2019 qws. All rights reserved.
//

#import "GPUImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSUnGreenBGFilter : GPUImageFilter
@property (nonatomic, assign) CGPoint tubularisPoint;
@property (nonatomic, assign) float tubularisLength;
@property (nonatomic, strong) UIImageView *tubularisPreview;

@property (nonatomic, assign) float hueOffset; //色调
@property (nonatomic, assign) float staOffset; //饱和度
@property (nonatomic, assign) float valOffset; //亮度

@property (nonatomic, assign) BOOL lockSelectedColor;
@property (nonatomic, strong) CIVector *lockedColor;
@property (nonatomic, strong) CIVector *selectedColor;
@property (nonatomic, strong) CIVector *swapColor;
@property (nonatomic, assign) float swapHueOffset;

@end

NS_ASSUME_NONNULL_END
