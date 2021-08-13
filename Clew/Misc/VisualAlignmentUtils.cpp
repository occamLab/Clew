//
//  VisualAlignmentUtils.cpp
//  Clew
//
//  Created by Kawin Nikomborirak on 7/19/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#include "VisualAlignmentUtils.hpp"
#include <opencv2/opencv.hpp>
#include <opencv2/core/eigen.hpp>
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <simd/SIMD.h>
#include <fstream>

KeyPointsAndDescriptors getKeyPointsAndDescriptors(cv::Mat image) {
    // Acquire features and their descriptors, and match them.
    auto feature_descriptor = cv::AKAZE::create(cv::AKAZE::DESCRIPTOR_MLDB_UPRIGHT);
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
        if (match.size() > 1 && match[0].distance < 0.7 * match[1].distance)
        {
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

float getYaw(std::vector<cv::Point2f> points1, std::vector<cv::Point2f> points2, Eigen::Matrix3f intrinsics, int& numInliers, float& residualAngle, float& tx, float& ty, float& tz) {
    const auto essential_mat = cv::findEssentialMat(points1, points2, intrinsics(0, 0), cv::Point2f(intrinsics(0, 2), intrinsics(1, 2)));
    cv::Mat dcm_mat, translation_mat;
    Eigen::Matrix3f essential_matrix;
    cv2eigen(essential_mat, essential_matrix);

    numInliers = cv::recoverPose(essential_mat, points1, points2, dcm_mat, translation_mat, intrinsics(0, 0), cv::Point2f(intrinsics(0, 2), intrinsics(1, 2)));
    
    Eigen::Matrix3f dcm;
    cv2eigen(dcm_mat, dcm);
    tx = translation_mat.at<double>(0, 0);
    ty = translation_mat.at<double>(0, 1);
    tz = translation_mat.at<double>(0, 2);
    const auto rotated = dcm * Eigen::Vector3f::UnitZ();
    const float yaw = atan2(rotated(0), rotated(2));
    residualAngle = abs(yaw) - acos((dcm.trace() - 1)/2);
    std::cout << "numInliers " << numInliers << " residualAngle " << residualAngle << " yaw " << yaw << std::endl;

    return yaw;
}
simd_float3x3 rotationToSIMD(Eigen::Matrix3f matrix) {
    simd_float3x3 simd;
    simd.columns[0] = {matrix(0, 0), matrix(1, 0), matrix(2, 0)};
    simd.columns[1] = {matrix(0, 1), matrix(1, 1), matrix(2, 1)};
    simd.columns[2] = {matrix(0, 2), matrix(1, 2), matrix(2, 2)};
    return simd;
}


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
#include <Eigen/Eigenvalues>
#include <Eigen/SVD>
#include <Eigen/Geometry>
#include <math.h>

#include <limits>


using Eigen::AngleAxisd;
using Eigen::EigenSolver;
using Eigen::JacobiSVD;
using Eigen::Map;
using Eigen::Matrix3d;
using Eigen::Matrix;
using Eigen::Quaterniond;
using Eigen::Vector3d;

bool SolveQEP(const Matrix3d& M, const Matrix3d& C, const Matrix3d& K,
              std::vector<double>* eigenvalues,
              std::vector<Vector3d>* eigenvectors) {
  // Solves the quadratic eigenvalue problem:
  //
  //   Q(s)x = 0
  //
  // where:
  //
  //   Q(s) = s^2*M + s*C + K
  //
  // Returns true if the problem could be solved, false otherwise.
  //
  // This is converted to a generalized eigenvalue as described in:
  //   http://en.wikipedia.org/wiki/Quadratic_eigenvalue_problem
  //
  // The generalized eigenvalue problem is in this form:
  //
  // [ C  K ]z = s[ -M  0  ]z
  // [-I  0 ]     [ 0   -I ]
  //
  // With eigenvector z = [ sx ] and s is the eigenvalue.
  //                      [  x ]
  //
  // The eigenvector of the quadratic eigenvalue problem can be extracted from
  // z.
  //
  // Where z is the eigenvector, s is the eigenvalue.
  // This generalized eigenvalue can be converted to a standard eigenvalue
  // problem by multiplying by the inverse of the RHS matrix. The inverse of
  // the RHS matrix is particularly simple:
  //
  // [ -inv(M)  0 ]
  // [ 0       -I ]
  //
  // So the generalized eigenvalue problem reduces to a standard eigenvalue
  // problem on the constraint matrix:
  //
  // [ -inv(M)C  -inv(M)K ]z = sz
  // [ I         0        ]

  Matrix3d inv_M;
  static const double kDeterminantThreshold = 1e-12;
  bool invert_success;
  // Check that determinant of M is larger than threshold. This threshold only
  // seems to be reached when there is no rotation. TODO(jflynn): verify.
  M.computeInverseWithCheck(inv_M, invert_success, kDeterminantThreshold);
  if (!invert_success) {
    return false;
  }

  // Negate inverse of M.
  inv_M = -1.0 * inv_M;

  // Set up constraint matrix.
  Matrix<double, 6, 6> constraint = Matrix<double, 6, 6>::Zero();
  // Set upper-left to - inv(M) * C.
  constraint.block<3, 3>(0, 0) = inv_M * C;
  // Set upper-right to -inv(M) * K.
  constraint.block<3, 3>(0, 3) = inv_M * K;
  // Set lower-left to identity.
  constraint.block<3, 3>(3, 0) = Matrix3d::Identity();
  // Extract the left eigenvectors and values from the constraint matrix.
  EigenSolver<Matrix<double, 6, 6> > eig_solver(constraint);
  const double kImagEigenValueTolerance = 1e-12;

  for (int i = 0; i < eig_solver.eigenvalues().size(); i++) {
    // Ignore roots corresponding to s^2 + 1.
    if (fabs(eig_solver.eigenvalues()[i].imag() - 1) <
            kImagEigenValueTolerance ||
        fabs(eig_solver.eigenvalues()[i].imag() + 1) <
            kImagEigenValueTolerance) {
      continue;
    }
    // Only consider the real eigenvalues and corresponding eigenvectors.
    eigenvalues->push_back(eig_solver.eigenvalues()[i].real());
    eigenvectors->push_back(
        Vector3d(eig_solver.eigenvectors().col(i).tail<3>().real()));
  }
  return true;
}

Eigen::Matrix3d CrossProductMatrix(const Vector3d& cross_vec) {
  Matrix3d cross;
  cross << 0.0, -cross_vec.z(), cross_vec.y(),
      cross_vec.z(), 0.0, -cross_vec.x(),
      -cross_vec.y(), cross_vec.x(), 0.0;
  return cross;
}

void theia::ThreePointRelativePosePartialRotation(
    const Vector3d& axis,
    const Vector3d image_1_rays[3],
    const Vector3d image_2_rays[3],
    std::vector<Quaterniond>* soln_rotations,
    std::vector<Vector3d>* soln_translations) {

  // Each correspondence gives another constraint and the constraints can
  // be stacked to create a constraint matrix.
  //
  // The rotation matrix R can be parameterized, up to scale factor, as:
  //
  //   R ~ 2 * (v * v' + s[v]x) + (s^2 - 1)I
  //
  //   I = Identity matrix.
  //
  // where is v is the known (unit length) axis and s is related to the
  // unknown angle of rotation.
  //
  // The epipolar constraint holds if the rotation matrix is scaled, so the
  // rotation matrix parameterization above can be used. Each row of the
  // constraint matrix is thus a function of s^2 and s, so the constraint can be
  // written as:
  //
  //   [ M * s^2 + C *s + k ] * [ t ] = 0
  //                            [ 1 ]
  //
  // This is standard quadratic eigenvalue problem (QEP) and is solved using
  // standard methods.

  // Creates the matrices for the QEP problem.
  Matrix3d M;
  Matrix3d C;
  Matrix3d K;
  for (int i = 0; i < 3; ++i) {
    const Vector3d& q1(image_1_rays[i]);
    const Vector3d& q2(image_2_rays[i]);
    M.row(i) = q2.cross(q1);
    C.row(i) = 2.0 * q2.cross(axis.cross(q1));
    K.row(i) = 2.0 * q1.dot(axis) * q2.cross(axis) - q2.cross(q1);
  }

  std::vector<double> eigenvalues;
  std::vector<Vector3d> eigenvectors;
  if (SolveQEP(M, C, K, &eigenvalues, &eigenvectors)) {
    // Extracts the translations and rotations from the eigenvalues and
    // eigenvectors of the QEP problem.
    for (int i = 0; i < eigenvalues.size(); ++i) {
      Quaterniond quat(eigenvalues[i], axis[0], axis[1], axis[2]);
      quat.normalize();

      soln_rotations->push_back(quat);
      soln_translations->push_back(eigenvectors[i]);
      soln_rotations->push_back(quat);
      soln_translations->push_back(-eigenvectors[i]);
    }
  } else {
    // When there is zero rotation the vector part of the quaternion disappears
    // and it becomes ([0], 1) (where [0] is the zero vector) and the SolveQEP
    // method cannot be used.
    // However from the equations for M, C, and K above we can see that the
    // C and K matrices contain the axis, which is 0 assuming zero rotation,
    // so to solve for the translation we can directly extract the null space
    // of M.
    // Alternatively this can be derived directly from the epipolar
    // constraint, after substituting identity for the rotation matrix.
    eigenvectors.clear();

    JacobiSVD<Matrix3d> svd = M.jacobiSvd(Eigen::ComputeFullV);
    const Vector3d eigenvector(svd.matrixV().col(2));

    soln_rotations->push_back(Quaterniond(AngleAxisd(0.0, axis)));
    soln_translations->push_back(eigenvector);
    soln_rotations->push_back(Quaterniond(AngleAxisd(0.0, axis)));
    soln_translations->push_back(-eigenvector);
  }
}
