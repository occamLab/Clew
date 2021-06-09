import pandas as pd
import numpy as np
import os
import json
import matplotlib.pyplot as plt
from clew_data_analysis.utils import *

class ClewData:
    def __init__(self):
        # Surveys contains a dictionary where the survey name is the key and the
        # value is a data frame containing the survey responses across all of
        # the users.
        self.surveys = self.load_feedback()
        self.logs = self.load_logs()
        self.auth = self.load_auth()

    def load_auth(self):
        f = open(os.path.join('data','auth.json'))
        auth = json.load(f)
        f.close()
        return pd.DataFrame(auth['users'])

    def load_logs(self):
        log_dir = os.path.join('data','logs')
        log_files = os.listdir(log_dir)
        log_data = []
        for f in log_files:
            log_file_path = os.path.join(log_dir, f)
            if os.path.isdir(log_file_path):
                log_data += self.parse_user_logs(f, log_file_path)
        df_all = pd.DataFrame(log_data)
        df_all['isSuccess'] = df_all['PathType'].map(lambda x: float(x == 'success'))
        df_all['routeDistance'] = df_all['keypointData'].map(compute_route_distance)

        df_all['resumedRoute'] = df_all['stateSequence'].map(get_resumed_route)
        df_all['isEndToStart'] = df_all['stateSequence'].map(get_is_end_to_start)
        df_all['isStartToEndResumedRoute'] = df_all['resumedRoute'] * (1-df_all['isEndToStart'])

        df_all['numInsufficientFeaturesErrors'] = df_all['trackingErrorData'].map(get_num_insufficient_features_errors)
        df_all['numExcessiveMotionErrors'] = df_all['trackingErrorData'].map(get_num_excessive_motion_errors)
        df_all['numTrackingErrors'] = df_all['numInsufficientFeaturesErrors'] + df_all['numExcessiveMotionErrors']
        df_all['routeDistanceQCut'] = pd.qcut(df_all['routeDistance'], 5)
        df_all['numTrackingErrorsLimited'] = df_all['numTrackingErrors'].apply(lambda x: 4 if x > 4 else x)
        df_all['pathVerticality'] = df_all['PathData'].map(get_phone_verticality)
        df_all['navigationVerticality'] = df_all['navigationData'].map(get_phone_verticality)
        df_all['navigationOffset'] = df_all['navigationData'].map(get_phone_offset)
        df_all['pathVerticalityMedian'] = df_all['pathVerticality'].map(np.median)
        df_all['navigationVerticalityMedian'] = df_all['navigationVerticality'].map(np.median)
        df_all['navigationOffsetMedian'] = df_all['navigationOffset'].map(smart_median)
        df_all['pathVerticalityMedianQCut'] = pd.qcut(df_all['pathVerticalityMedian'], 5)
        df_all['navigationVerticalityMedianQCut'] = pd.qcut(df_all['navigationVerticalityMedian'], 5)
        df_all['navigationOffsetMedianQCut'] = pd.qcut(df_all['navigationOffsetMedian'], 5)

        df_all['arrived'] = df_all['stateSequence'].map(lambda x: float('nan') if type(x) == float else 'ratingRoute(announceArrival=true)' in x)
        df_all['PathX'] = df_all['PathData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,0] for m in x])
        df_all['PathY'] = df_all['PathData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,1] for m in x])
        df_all['PathZ'] = df_all['PathData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,2] for m in x])
        df_all['navigationX'] = df_all['navigationData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,0] for m in x])
        df_all['navigationY'] = df_all['navigationData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,1] for m in x])
        df_all['navigationZ'] = df_all['navigationData'].map(lambda x: [np.asarray(m)[:-2].reshape((4,4))[3,2] for m in x])
        df_all['keypointX'] = df_all['keypointData'].map(lambda x: [m[0] for m in x])
        df_all['keypointY'] = df_all['keypointData'].map(lambda x: [m[1] for m in x])
        df_all['keypointZ'] = df_all['keypointData'].map(lambda x: [m[2] for m in x])
        return df_all
    
    def parse_user_logs(self, user_id, log_dir):
        user_log_data = []
        for file in os.listdir(log_dir):
            stem = file[:file.rfind('_')]
            if stem.endswith('-0'):
                continue
            pathfile = os.path.join(log_dir, stem + '_pathdata.json')
            metadatafile = os.path.join(log_dir, stem + '-0_metadata.json')
            try:
                f = open(pathfile)
                pathdata = json.load(f)
                f.close()

                f = open(metadatafile)
                metadata = json.load(f)
                f.close()

                user_log_data.append({**pathdata, **metadata})
            except:
                print("unable to read a log")
                pass
        return user_log_data

    def load_feedback(self):
        surveys = dict()
        feedback_dir = os.path.join('data','feedback')
        feedback_files = os.listdir(feedback_dir)
        feedback = []
        for f in feedback_files:
            feedback_file_path = os.path.join(feedback_dir, f)
            if os.path.isdir(feedback_file_path):
                feedback.append(self.parse_user_feedback(f, feedback_file_path))
        all_surveys = set()
        for f in feedback:
            all_surveys |= set(f.keys())
        for survey_name in all_surveys:
            df = pd.DataFrame()
            rows = []
            for f in feedback:
                if survey_name in f:
                    df = df.append(f[survey_name], ignore_index=True)
            surveys[survey_name] = df
        return surveys

    def parse_user_feedback(self, user_id, feedback_dir):
        # This dictionary will associate survey name with a list of responses.
        # Each response corresponds to one time the user filled out the survey
        surveys_completed = dict()
        user_feedback = os.listdir(feedback_dir)
        for survey in user_feedback:
            if survey.find('_') != -1:
                survey_id = survey[:survey.find('_')]
                survey_name = survey[survey.find('_')+1:-5]
                survey_path = os.path.join(feedback_dir, survey)
                with open(survey_path) as f:
                    json_parsed = json.load(f)
                    survey_as_series = pd.Series(json_parsed,name=survey_id)
                    if survey_name not in surveys_completed:
                        surveys_completed[survey_name] = [survey_as_series]
                    else:
                        surveys_completed[survey_name].append(survey_as_series)
        return surveys_completed

if __name__ == '__main__':
    data = ClewData()
