import pandas as pd
import numpy as np
import math

def compute_route_distance(keypoints):
    distance = 0.0
    if not len(keypoints):
        return distance
    last_point = np.asarray(keypoints[0][:-1])
    for i in range(1,len(keypoints)):
        next_point = np.asarray(keypoints[i][:-1])
        distance += np.linalg.norm(next_point - last_point)
        last_point = next_point
    return distance

def get_is_end_to_start(stateSequence):
    if type(stateSequence) == float and math.isnan(stateSequence):
        # before we had state sequences all routes were end to start
        return 1.0
    return float(not np.any([s.find('navigateStartToEnd=true') >= 0 for s in stateSequence]))

def get_num_excessive_motion_errors(trackingErrors):
    if type(trackingErrors) == float and math.isnan(trackingErrors):
        # before we had state sequences all routes were end to start
        return float('nan')
    return np.sum([s.find('ExcessiveMotion') >= 0 for s in trackingErrors])


def get_num_insufficient_features_errors(trackingErrors):
    if type(trackingErrors) == float and math.isnan(trackingErrors):
        # before we had state sequences all routes were end to start
        return float('nan')
    return np.sum([s.find('InsufficientFeatures') >= 0 for s in trackingErrors])


def get_resumed_route(stateSequence):
    if type(stateSequence) == float and math.isnan(stateSequence):
        return 0.0
    return float(np.any([s.find('startingResumeProcedure') >= 0 for s in stateSequence]))

def get_phone_verticality(pathdata):
    if len(pathdata) == 0:
        return float('nan')
    return [np.reshape(p[:-2], (4, 4), order='F')[1][0] for p in pathdata]

def process_offset(heading, translation):
    try:
        if np.linalg.norm(translation[[0, 2]]) > .1:
            return math.acos(np.dot(heading, translation)/np.linalg.norm(translation))
        else:
            return float('nan')
    except Exception as inst:
        return float('nan')

def get_phone_offset(pathdata):
    if len(pathdata) == 0:
        return float('nan')
    # TODO: what's up with 18 length matrix (what are the last two elements?)
    translations = [np.reshape(p2[:-2], (4, 4), order='F')[:,3] - np.reshape(p1[:-2], (4, 4), order='F')[:,3] for p1,p2 in zip(pathdata[:-1],pathdata[1:])]
    headings = [-np.reshape(p[:-2], (4, 4), order='F')[:,2] for p in pathdata[:-1]]
    return [process_offset(heading, translation) for heading, translation in zip(headings, translations)]

def smart_median(data):
    # require at least 20 measurements (each measurement is 300ms) that meet the criteria of 0.1m travel
    if (~np.isnan(data)).sum() < 15:
        return float('nan')
    else:
        return np.nanmedian(data)

def get_heading_angles(route_data):
  # get heading angles returns the angle (in degrees) that the phone is offset
  # from the walking direction

  # FUNCTION CALL:
  # data.all['PathHeadingAngles'] = data.all['PathData'].map(get_heading_angles)
  # data.all['navigationHeadingAngles'] = data.all['navigationData'].map(get_heading_angles)
  
  if isinstance(route_data, list):
    Angles = [0]*(len(route_data)-1)

    # determine angles !
    for i in range(0, len(route_data)-1):
      loc1 = np.reshape(route_data[i][:-2], (4,4), order = 'F')[:-1, 3]
      loc2 = np.reshape(route_data[i+1][:-2], (4,4), order = 'F')[:-1, 3]


      walk_heading = (loc2 - loc1)[[0,2]]
      phone_heading = np.reshape(route_data[i][:-2], (4,4), order = 'F')[:-1, 2][[0,2]]
      phone_heading *= -1

      walk_heading = walk_heading / np.linalg.norm(walk_heading)
      phone_heading = phone_heading / np.linalg.norm(phone_heading)
      
      angle = math.atan2(walk_heading[1], walk_heading[0]) - math.atan2(phone_heading[1], phone_heading[0])

      normVector = [math.cos(angle), math.sin(angle)]
      angle = math.atan2(normVector[1], normVector[0])
      angle = angle * 180 / 3.1415
      Angles[i] = angle
  else:
    Angles = []
  
  return Angles
  
def get_relativeError(keypoints, navigation, pathLength):
  # determines approximately how much of the path is completed based on the
  # length of the path and the distance from the navigation end to
  # the final keypoint

  # FUNCTION CALL:
  # data.all['relativeError'] = data.all.apply(lambda x: get_relativeError(x['keypointData'], x['navigationData'], x['routeDistance']), axis = 1)
  
  if (isinstance(keypoints, list)) & (isinstance(navigation, list)) & (pathLength > 0):
    keypoint = keypoints[-1][:-1]

    endloc = np.reshape(navigation[-1][:-2], (4,4), order = 'F')[:-1, 3]

    error = np.linalg.norm(keypoint - endloc)
    #print(str(error) + ' & ' + str(pathLength))
    return error / pathLength

  return float('nan')
