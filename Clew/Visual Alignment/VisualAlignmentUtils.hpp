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
float getYaw(std::vector<cv::Point2f> points1, std::vector<cv::Point2f> points2, Eigen::Matrix3f intrinsics, int& numInliers, float& residualAngle, float& tx, float& ty, float& tz);

/**
 Encode rotation matrix from an Eigen::Matrix3f to a simd_float3x3.
 
 - returns: A simd_float3x3 encoding the specified rotation.
 
 - parameters:
 - matrix: An Eigen::Matrix3f encoding the rotation to be converted.
 */
simd_float3x3 rotationToSIMD(Eigen::Matrix3f matrix);


// Copyright (C) 2014 The Regents of the University of California (Regents)
// and Google, Inc. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//
//     * Neither the name of The Regents or University of California, Google,
//       nor the names of its contributors may be used to endorse or promote
//       products derived from this software without specific prior written
//       permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please contact the author of this library if you have any questions.
// Author: Chris Sweeney (cmsweeney@cs.ucsb.edu), John Flynn (jflynn@google.com)

#include <Eigen/Core>
#include <Eigen/Geometry>
#include <vector>

// Solves for the limited transformation between correspondences from two
// images. The transformation is limited in that it only solves for a single
// rotation around a known axis. Additionally the translation is only solved up
// to scale
//
// This is intended for use with camera phones that have accelerometers, so that
// the 'up' vector is known, meaning the other two rotations are known. The
// effect of the other rotations should be removed before using this function.
//
// This implementation is intended to form the core of a RANSAC routine, and as
// such has an optimized interface for this use case.
//
// Computes the limited pose between the two sets of image rays. Places the
// rotation and translation solutions in soln_rotations and soln_translations.
// The translations are computed up to scale and have unit length. There are at
// most 4 solutions. The rotations and translations are defined such that the
// ray in image one are transformed according to:
//
//     ray_in_image_2 = Q * ray_in_image_1 + t
//
// The computed rotations are guaranteed to be rotations around the passed
// axis only.
namespace theia {
    void ThreePointRelativePosePartialRotation(
        const Eigen::Vector3d& rotation_axis,
        const Eigen::Vector3d image_1_rays[3],
        const Eigen::Vector3d image_2_rays[3],
        std::vector<Eigen::Quaterniond>* soln_rotations,
        std::vector<Eigen::Vector3d>* soln_translations);
}

Eigen::Matrix3d CrossProductMatrix(const Eigen::Vector3d& cross_vec);

#endif /* VisualAlignmentUtils_hpp */
