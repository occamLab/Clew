//
//  VisualAlignmentUtils.hpp
//  Clew
//
//  Created by Kawin Nikomborirak on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#ifndef VisualAlignmentUtils_hpp
#define VisualAlignmentUtils_hpp

#include <stdio.h>
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <simd/SIMD.h>
#include <opencv2/opencv.hpp>

typedef struct {
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
} KeyPointsAndDescriptors;

KeyPointsAndDescriptors getKeyPointsAndDescriptors(cv::Mat image);
std::vector<cv::DMatch> getMatches(cv::Mat descriptors1, cv::Mat descriptors2);
Eigen::Matrix3f intrinsicsToMatrix(simd_float4 intrinsics);
Eigen::AngleAxisf squareImageRotation(Eigen::Matrix4f pose);
cv::Mat squareImageGlobalRotation(cv::Mat image, Eigen::Matrix3f intrinsics, Eigen::Matrix3f pose_rotation, Eigen::AngleAxisf rotation_in_global);
Eigen::Matrix4f poseToMatrix(simd_float4x4 pose);
float getYaw(std::vector<cv::Point2f> vectors1, std::vector<cv::Point2f> vectors2);
simd_float3x3 rotationToSIMD(Eigen::Matrix3f matrix);

#endif /* VisualAlignmentUtils_hpp */
