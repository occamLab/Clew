//
//  UNIMatch.h
//  Clew
//
//  Created by Marc Eftimie on 6/14/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

#ifndef UNIMatch_h
#define UNIMatch_h


#endif /* UNIMatch_h */

#import <opencv2/opencv.hpp>
#import <Foundation/Foundation.h>

@interface UNIMatch : NSObject

+ (instancetype) UNIMatch:(float)x1 :(float)y1 :(float)x2 :(float)y2;

- (id) initWithPts:(float)x1 :(float)y1 :(float)x2 :(float)y2;

@property (assign) cv::Point2f queryPt;

@property (assign) cv::Point2f trainPt;

@end



