//
//  VisualAlignmentUtils.cpp
//  Clew
//
//  Created by Kawin Nikomborirak on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#include "VisualAlignmentUtils.hpp"
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <opencv2/opencv.hpp>
#include <opencv2/core/eigen.hpp>
#include <simd/SIMD.h>
#include <fstream>

KeyPointsAndDescriptors getKeyPointsAndDescriptors(cv::Mat image) {
    // Acquire features and their descriptors, and match them.
    auto feature_descriptor = cv::AKAZE::create();
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
    
    feature_descriptor->detectAndCompute(image, cv::Mat(), keypoints, descriptors);
    
    return {.keypoints = keypoints, .descriptors = descriptors};
}

std::vector<cv::DMatch> getMatches(cv::Mat descriptors1, cv::Mat descriptors2) {
    auto matcher = cv::BFMatcher();
    std::vector<std::vector<cv::DMatch>> matches;
    matcher.knnMatch(descriptors1, descriptors2, matches, 2);
    std::vector<cv::DMatch> good_matches;
    
    // Use Lowe's ratio test to select the good matches.
    for (const auto match : matches)
        if (match[0].distance < 0.6 * match[1].distance)
        {
            std::cout << "counter" << std::endl;
            good_matches.push_back(match[0]);
        }

    
    return good_matches;
}


Eigen::Matrix3f intrinsicsToMatrix(simd_float4 intrinsics) {
    Eigen::Matrix3f intrinsics_matrix;
    intrinsics_matrix << intrinsics.x, 0, intrinsics.z,
        0, intrinsics.y, intrinsics.w,
        0, 0, 1;
    return intrinsics_matrix;
}

Eigen::AngleAxisf getIdealRotation(Eigen::Matrix4f pose) {
    // The phone's x axis is from the front facing camera to the home button, so the desired polar angle is between the global y axis and the phone's -x axis.
    const auto polar_angle = acos(-pose(1, 0));
    Eigen::Vector3f rotation_axis = Eigen::Vector3f::UnitY().cross((Eigen::Vector3f) -pose.col(0).head(3));
    rotation_axis = rotation_axis / rotation_axis.norm();
    return Eigen::AngleAxisf(polar_angle, rotation_axis);
}

cv::Mat warpPerspectiveWithGlobalRotation(cv::Mat image, Eigen::Matrix3f intrinsics, Eigen::Matrix3f pose_rotation, Eigen::AngleAxisf rotation_in_global) {
    Eigen::Matrix3f phone_to_camera;
    phone_to_camera << 0, 1, 0, 1, 0, 0, 0, 0, -1;
    const Eigen::Vector3f rotation_in_camera_axis = (pose_rotation * phone_to_camera).inverse() * rotation_in_global.axis();
    const Eigen::AngleAxisf rotation_in_camera = Eigen::AngleAxisf(rotation_in_global.angle(), rotation_in_camera_axis);
    const Eigen::Matrix3f homography = intrinsics * rotation_in_camera * intrinsics.inverse();
    cv::Mat homography_mat;
    cv::eigen2cv(homography, homography_mat);
    cv::Mat squared;
    cv::warpPerspective(image, squared, homography_mat, image.size());
    return squared;
}

Eigen::Matrix4f poseToMatrix(simd_float4x4 pose) {
    Eigen::Matrix4f matrix;
    matrix << pose.columns[0].x, pose.columns[1].x, pose.columns[2].x, pose.columns[3].x,
        pose.columns[0].y, pose.columns[1].y, pose.columns[2].y, pose.columns[3].y,
        pose.columns[0].z, pose.columns[1].z, pose.columns[2].z, pose.columns[3].z,
        pose.columns[0].w, pose.columns[1].w, pose.columns[2].w, pose.columns[3].w;
    return matrix;
}

float getYaw(std::vector<cv::Point2f> points1, std::vector<cv::Point2f> points2, Eigen::Matrix3f intrinsics) {
    const auto essential_mat = cv::findEssentialMat(points1, points2, intrinsics(0, 0), cv::Point2f(intrinsics(0, 2), intrinsics(1, 2)));
    cv::Mat dcm_mat, translation_mat;
    Eigen::Matrix3f essential_matrix;
    cv2eigen(essential_mat, essential_matrix);

    int inliers = cv::recoverPose(essential_mat, points1, points2, dcm_mat, translation_mat, intrinsics(0, 0), cv::Point2f(intrinsics(0, 2), intrinsics(1, 2)));
    
    Eigen::Matrix3f dcm;
    cv2eigen(dcm_mat, dcm);
    const auto rotated = dcm * Eigen::Vector3f::UnitZ();
    const float yaw = atan2(rotated(0), rotated(2));
    
    return yaw;
}
simd_float3x3 rotationToSIMD(Eigen::Matrix3f matrix) {
    simd_float3x3 simd;
    simd.columns[0] = {matrix(0, 0), matrix(1, 0), matrix(2, 0)};
    simd.columns[1] = {matrix(0, 1), matrix(1, 1), matrix(2, 1)};
    simd.columns[2] = {matrix(0, 2), matrix(1, 2), matrix(2, 2)};
    return simd;
}
