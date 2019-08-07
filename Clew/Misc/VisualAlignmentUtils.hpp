//
//  VisualAlignmentUtils.hpp
//  Clew
//
//  Created by Kawin Nikomborirak on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#ifndef VisualAlignmentUtils_hpp
#define VisualAlignmentUtils_hpp

#include <opencv2/opencv.hpp>
#include <stdio.h>
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <simd/SIMD.h>


typedef struct {
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
} KeyPointsAndDescriptors;

/**
 Get keypoints and descriptors from an image.
 
 - returns: A KeyPointAndDescriptors containing the image's keypoints and the respective descriptors.
 
 - parameters:
 - image: The image to find features in.
 */
KeyPointsAndDescriptors getKeyPointsAndDescriptors(cv::Mat image);

/**
 Find matches between two sets of features.
 
 - returns: A list of matches.
 
 - parameters:
 - descriptors1: The first set of descriptors.
 - descriptors2: The second set of descriptors.
 */
std::vector<cv::DMatch> getMatches(cv::Mat descriptors1, cv::Mat descriptors2);

/**
 Convert camera intrinsics encoded in a simd_float4 to one encoded in an Eigen::Matrix3f.
 
 - returns: An intrinsics matrix.
 
 - parameters:
 - intrinsics: The intrinsics encoded as a simd_float4
 */
Eigen::Matrix3f intrinsicsToMatrix(simd_float4 intrinsics);

/**
 Get the rotation in global coordinates from an ideal vertical position pitched down to the camera's actual position.
 
 - returns: The rotation from an ideal vertical position which pitches down to the camera's actual position in the global coordinate frame.
 
 - parameters:
 - pose: The pose of the camera.
 */
Eigen::AngleAxisf getIdealRotation(Eigen::Matrix4f pose);

/**
 Rotate the image's perspective according to a rotation in global coordinates.
 
 - returns: An image with the perspective warped according to the global rotation specified.
 
 - parameters:
 - image: The image to warp the perspective of.
 - intrinsics: The camera intrinsics used to capture the image.
 - pose_rotation: The rotation converting a point in the camera's coordinate system to one in the global coordinate system.
 - rotation_in_global: The rotation in global coordinates with which to warp the perspective.
 */
cv::Mat warpPerspectiveWithGlobalRotation(cv::Mat image, Eigen::Matrix3f intrinsics, Eigen::Matrix3f pose_rotation, Eigen::AngleAxisf rotation_in_global);

/**
 Convert a pose encoded in a simd_float4x4 to one encoded in an Eigen::Matrix4f.
 
 - returns: A matrix encoding a pose of the input simd_float4x4.
 
 - parameters:
 - pose: The pose encoded as a simd_float4x4.
 */
Eigen::Matrix4f poseToMatrix(simd_float4x4 pose);

/**
 Get the yaw given matching points between images.
 
 - returns: The rotation about the image's negative x axis to convert a point in the second camera's coordinate frame to one in the first camera's coordinate frame.
 
 - parameters:
 - points1: The points in the first image which are matched by index to the specified points in the second image.
 - points2: The points in the second image which are matched by index to the specified points in the second image.
 - intrinsics: The camera intrinsics of the camera used to get the points.
 */
float getYaw(std::vector<cv::Point2f> points1, std::vector<cv::Point2f> points2, Eigen::Matrix3f intrinsics);

/**
 Encode rotation matrix from an Eigen::Matrix3f to a simd_float3x3.
 
 - returns: A simd_float3x3 encoding the specified rotation.
 
 - parameters:
 - matrix: An Eigen::Matrix3f encoding the rotation to be converted.
 */
simd_float3x3 rotationToSIMD(Eigen::Matrix3f matrix);

#endif /* VisualAlignmentUtils_hpp */
