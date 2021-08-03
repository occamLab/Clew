//
//  VisualAlignment.mm
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import "VisualAlignment.h"
#import "VisualAlignmentUtils.hpp"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>
#import <opencv2/core/eigen.hpp>
#import <Eigen/Core>
#import <Eigen/Geometry>
#import <UIKit/UIKit.h>
#import <fstream>


@implementation VisualAlignment

+ (VisualAlignmentReturn) visualYaw :(UIImage *)image1 :(simd_float4)intrinsics1 :(simd_float4x4)pose1
                    :(UIImage *)image2 :(simd_float4)intrinsics2 :(simd_float4x4)pose2 {
    
    VisualAlignmentReturn ret;
    // Convert the UIImages to cv::Mats and rotate them.
    cv::Mat image_mat1, image_mat2;
    UIImageToMat(image1, image_mat1);
    UIImageToMat(image2, image_mat2);

    cv::cvtColor(image_mat1, image_mat1, cv::COLOR_RGB2GRAY);
    cv::rotate(image_mat1, image_mat1, cv::ROTATE_90_CLOCKWISE);
    cv::cvtColor(image_mat2, image_mat2, cv::COLOR_RGB2GRAY);
    cv::rotate(image_mat2, image_mat2, cv::ROTATE_90_CLOCKWISE);
    
    Eigen::Matrix3f intrinsics1_matrix_unrotated = intrinsicsToMatrix(intrinsics1);
    Eigen::Matrix3f intrinsics2_matrix_unrotated = intrinsicsToMatrix(intrinsics2);
    
    // Since the image was rotated clockwise, we have to swap entries in the intrinsic matrices as well.
    // I use matrix multiplication for this.
    Eigen::Matrix3f swap_matrix;
    swap_matrix << 0, 1, 0, 1, 0, 0, 0, 0, 1;
    
    Eigen::Matrix3f intrinsics1_matrix = swap_matrix * intrinsics1_matrix_unrotated * swap_matrix;
    Eigen::Matrix3f intrinsics2_matrix = swap_matrix * intrinsics2_matrix_unrotated * swap_matrix;
    
    intrinsics1_matrix(0, 2) = image_mat1.cols - intrinsics1_matrix(0, 2);
    intrinsics2_matrix(0, 2) = image_mat2.cols - intrinsics2_matrix(0, 2);
    const Eigen::Matrix4f pose1_matrix = poseToMatrix(pose1);
    const Eigen::Matrix4f pose2_matrix = poseToMatrix(pose2);
    
    const Eigen::AngleAxisf square_rotation1 = getIdealRotation(pose1_matrix);
    const Eigen::AngleAxisf square_rotation2 = getIdealRotation(pose2_matrix);
    
    ret.square_rotation1 = rotationToSIMD((Eigen::Matrix3f) square_rotation1);
    ret.square_rotation2 = rotationToSIMD((Eigen::Matrix3f) square_rotation2);
    
    const auto square_image_mat1 = warpPerspectiveWithGlobalRotation(image_mat1, intrinsics1_matrix, pose1_matrix.block(0, 0, 3, 3), square_rotation1);
    const auto square_image_mat2 = warpPerspectiveWithGlobalRotation(image_mat2, intrinsics2_matrix, pose2_matrix.block(0, 0, 3, 3), square_rotation2);
    cv::Mat square_image_mat1_resized, square_image_mat2_resized;
    const int downSampleFactor = 2;
    cv::resize(square_image_mat1, square_image_mat1_resized, cv::Size(square_image_mat1.size().width/downSampleFactor, square_image_mat1.size().height/downSampleFactor));
    cv::resize(square_image_mat2, square_image_mat2_resized, cv::Size(square_image_mat2.size().width/downSampleFactor, square_image_mat2.size().height/downSampleFactor));
    
    const auto keypoints_and_descriptors1 = getKeyPointsAndDescriptors(square_image_mat1_resized);
    const auto keypoints_and_descriptors2 = getKeyPointsAndDescriptors(square_image_mat2_resized);

    const auto matches = getMatches(keypoints_and_descriptors1.descriptors, keypoints_and_descriptors2.descriptors);
    
    if (matches.size() < 20) {
        ret.is_valid = false;
        ret.yaw = 0;
        return ret;
    }


    std::vector<cv::Point2f> vectors1, vectors2;
    
    for (const auto& match : matches) {
        const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
        const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
        // correct for the downsampling
        vectors1.push_back(downSampleFactor*keypoint1.pt);
        
        // Convert the second keypoint to one with the intrinsics of the first camera.
        Eigen::Vector3f keypoint2vec;
        keypoint2vec << downSampleFactor*keypoint2.pt.x, downSampleFactor*keypoint2.pt.y, 1;
        Eigen::Vector3f keypoint2projected = intrinsics1_matrix * intrinsics2_matrix.inverse() * keypoint2vec;
        vectors2.push_back(cv::Point2f(keypoint2projected(0), keypoint2projected(1)));
    }

    ret.is_valid = true;
    ret.numMatches = vectors1.size();
    const auto yaw = getYaw(vectors1, vectors2, intrinsics1_matrix, ret.numInliers, ret.residualAngle, ret.tx, ret.ty, ret.tz);
    
    // Uncomment the lines below and add a breakpoint to see the found matches between the perspective-warped images.
    cv::Mat debug_match_image;
    cv::drawMatches(square_image_mat1, keypoints_and_descriptors1.keypoints, square_image_mat2, keypoints_and_descriptors2.keypoints, matches, debug_match_image);
    UIImage *debug_match_image_ui = MatToUIImage(debug_match_image);

    ret.yaw = yaw;

    return ret;
}

+ (int) numFeatures :(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat, mat, cv::COLOR_RGB2GRAY);
    const auto keypoints_and_descriptors = getKeyPointsAndDescriptors(mat);
    return keypoints_and_descriptors.keypoints.size();
}

+ (int) numMatches :(UIImage *)image1 :(UIImage *)image2 {
    cv::Mat mat1, mat2;
    UIImageToMat(image1, mat1);
    UIImageToMat(image2, mat2);
    cv::cvtColor(mat1, mat1, cv::COLOR_RGB2GRAY);
    cv::cvtColor(mat2, mat2, cv::COLOR_RGB2GRAY);
    const auto keypoints_and_descriptors1 = getKeyPointsAndDescriptors(mat1);
    const auto keypoints_and_descriptors2 = getKeyPointsAndDescriptors(mat2);
    
    const auto matches = getMatches(keypoints_and_descriptors1.descriptors, keypoints_and_descriptors2.descriptors);
    return matches.size();
}

@end
