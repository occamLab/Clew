//
//  VisualAlignment.h
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <simd/SIMD.h>
//#import <opencv2/opencv.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface VisualAlignment : NSObject
+ (float) visualYaw :(UIImage *)base_image :(simd_float4)base_intrinsics :(UIImage *)new_image :(simd_float4)new_intrinsics;
@end

NS_ASSUME_NONNULL_END
