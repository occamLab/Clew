//
//  Surveys.swift
//  Provides survey capabilities to be served from a Firebase database
//
//  Created by Paul on 5/3/2021
//

// TODO: Support multiple surveys by listening to the "surveys/" path.
// TODO: Allow trigger rate to be set through Firebase (e.g., showing the survey once a day versus once a week, etc.)
// TODO: Handle users being offline more gracefully (either don't show the survey at all or cache the data)

import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseAuth

enum QuestionType: String {
    case title = "title"
    case textField = "textField"
    case textView = "textView"
    case slider = "slider"
    case stepper = "stepper"
    case toggle = "toggle"
    case checkboxes = "checkboxes"
}

struct MultipleChoiceOption {
    let key: String
    let choiceOrder: Int
    let localizations: [String: String]

    init?(key: String, firebaseData: [String: Any]) {
        self.key = key
        guard let choiceOrder = firebaseData["order"] as? Int else {
            return nil
        }
        self.choiceOrder = choiceOrder
        guard let localizations = firebaseData["prompt"] as? [String: String] else {
            return nil
        }
        self.localizations = localizations
    }
    
    var localizedText: String {
        if let languageCode = Locale.current.languageCode, let localized = localizations[languageCode] {
            return localized
        } else {
            return key
        }
    }
}

struct SurveyQuestion {
    let name: String
    let text: String
    let localizations: [String: String]
    let questionType: QuestionType
    let required: Bool
    let isEmail: Bool
    let order: Int
    let numericalDefault: Float?
    let numericalMin: Float?
    let numericalMax: Float?
    let quantizeSlider: Bool?
    let addSliderAccent: Bool?
    let booleanDefault: Bool?
    let choices: [MultipleChoiceOption]
    var localizedText: String {
        if let languageCode = Locale.current.languageCode, let localized = localizations[languageCode] {
            return localized
        } else {
            return text
        }
    }
    var localizedChoices: [(String, String)] {
        choices.enumerated().map({(_, keyvalue) in (keyvalue.key, keyvalue.localizedText)})
    }
}

class FirebaseFeedbackSurveyModel {
    // let databaseHandle = Database.database()
    public static var shared = FirebaseFeedbackSurveyModel()
    var questions: [String: [SurveyQuestion]] = [:]
    var intervals: [String: Double] = [:]
    var currentAppLaunchSurvey: String = ""
    var currentAfterRouteSurvey: String = ""
    
    private init() {
        setupListeners()
    }
    
    private func setupListeners() {
//        let surveysRef = databaseHandle.reference(withPath: "surveys")
//        surveysRef.observe(.childAdded) { (snapshot) -> Void in
//            self.populateModel(snapshot)
//        }
//        surveysRef.observe(.childChanged) { (snapshot) -> Void in
//            self.populateModel(snapshot)
//        }
    }
//    private func populateModel(_ snapshot: DataSnapshot) {
//        print(snapshot.key)
//
//        if snapshot.key == "currentAppLaunchSurvey" {
//            self.currentAppLaunchSurvey = snapshot.value as? String ?? "defaultSurvey"
//        } else if snapshot.key == "currentAfterRouteSurvey" {
//            self.currentAfterRouteSurvey = snapshot.value as? String ?? "defaultSurvey"
//        }
//
//        var surveyQuestions: [SurveyQuestion] = []
//        guard let surveyQuestionsRaw = snapshot.value as? [String: Any] else {
//            return
//        }
//        var presentationIntervalInSeconds: Double = 0.0
//        for (childKey, childValue) in surveyQuestionsRaw {
//            if childKey == "_presentationIntervalInSeconds" {
//                if let newInterval = childValue as? Double {
//                    presentationIntervalInSeconds = newInterval
//                }
//                continue
//            }
//            guard let questionDefinition = childValue as? [String: Any], let prompt = questionDefinition["prompt"] as? [String: String], let questionType = questionDefinition["type"] as? String, let questionTypeEnum = QuestionType(rawValue: questionType), let questionOrder = questionDefinition["order"] as? Int, let text = prompt["en"] else {
//                continue
//            }
//            let numericalDefault = questionDefinition["numericalDefault"] as? Float
//            let numericalMin = questionDefinition["numericalMin"] as? Float
//            let numericalMax = questionDefinition["numericalMax"] as? Float
//            let quantizeSlider = questionDefinition["quantizeSlider"] as? Bool
//            let addSliderAccent = questionDefinition["addSliderAccent"] as? Bool
//
//            let booleanDefault = questionDefinition["booleanDefault"] as? Bool
//            let required = questionDefinition["required"] as? Bool ?? true
//            let isEmail = questionDefinition["isEmail"] as? Bool ?? false
//            var choices: [MultipleChoiceOption] = []
//            if let choiceDict = questionDefinition["choices"] as? [String : [String: Any] ] {
//                for (choiceKey, choiceDescription) in choiceDict {
//                    if let choice = MultipleChoiceOption(key: choiceKey, firebaseData: choiceDescription) {
//                        choices.append(choice)
//                    }
//                }
//            }
//            choices.sort(by: {$0.choiceOrder < $1.choiceOrder})
//            surveyQuestions.append(SurveyQuestion(name: childKey, text: text, localizations: prompt, questionType: questionTypeEnum, required: required, isEmail: isEmail, order: questionOrder, numericalDefault: numericalDefault, numericalMin: numericalMin, numericalMax: numericalMax, quantizeSlider: quantizeSlider, addSliderAccent: addSliderAccent, booleanDefault: booleanDefault, choices: choices))
//        }
//        questions[snapshot.key] = surveyQuestions
//        intervals[snapshot.key] = presentationIntervalInSeconds
//        print("intervals", intervals)
//    }
    
}
