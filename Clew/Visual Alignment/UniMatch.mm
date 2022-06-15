//
//  UniMatch.m
//  Clew
//
//  Created by Marc Eftimie on 6/14/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>
#import "UNIMatch.h"


@implementation UNIMatch : NSObject

+ (instancetype) UNIMatch:(float)x1 :(float)y1 :(float)x2 :(float)y2 {
    
    UNIMatch *match = [[UNIMatch alloc] initWithPts:x1 :y1 :x2 :y2 ];
    return match;
    
}

- (id) initWithPts:(float)x1 :(float)y1 :(float)x2 :(float)y2 {
    self = [super init];
    if (self) {
        self.queryPt = cv::Point2f(x1, y1);
        self.trainPt = cv::Point2f(x2, y2);
    }
    return self;
}

@end
