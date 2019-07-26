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

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    float yaw;
    simd_float3x3 square_rotation1;
    simd_float3x3 square_rotation2;
} VisualAlignmentReturn;

@interface VisualAlignment : NSObject
+ (VisualAlignmentReturn) visualYaw :(NSString *)dir :(UIImage *)image1 :(simd_float4)intrinsics1 :(simd_float4x4)pose1 :(UIImage *)image2 :(simd_float4)intrinsics2 :(simd_float4x4)pose2;
@end

NS_ASSUME_NONNULL_END
