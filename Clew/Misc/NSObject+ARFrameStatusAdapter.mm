//
//  NSObject+ARFrameStatusAdapter.m
//  Clew
//
//  Created by Paul Ruvolo on 7/22/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

#import "NSObject+ARFrameStatusAdapter.h"
#import "JGMethodSwizzler.h"
#import "ARKit/ARKit.h"

@implementation ARFrameStatusAdapter

+(void)adjustTrackingStatus:(ARFrame *)frame {
    if (frame.camera.trackingState == ARTrackingStateLimited && frame.camera.trackingStateReason == ARTrackingStateReasonRelocalizing) {
        [frame.camera swizzleMethod:@selector(trackingState) withReplacement:JGMethodReplacementProviderBlock {
            return JGMethodReplacement(ARTrackingState, ARCamera *) {
                return ARTrackingStateNormal;
            };
        }];
    }
  }

@end
