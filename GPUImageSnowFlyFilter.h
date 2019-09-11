//
//  GPUImageSnowFlyFilter.h
//  Taker
//
//  Created by qws on 2018/12/7.
//  Copyright © 2018 com.pepsin.fork.video_taker. All rights reserved.
//

#import "GPUImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageSnowFlyFilter : GPUImageFilter
@property (nonatomic, assign) float iGlobalTime;
@property (nonatomic, assign) int snowFlakeAmount;
@property (nonatomic, assign) float blizardFactor;




@end

NS_ASSUME_NONNULL_END
