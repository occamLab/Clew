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
import SimpleForm
import FirebaseStorage
import FirebaseDatabase
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
    let databaseHandle = Database.database()
    public static var shared = FirebaseFeedbackSurveyModel()
    var questions: [String: [SurveyQuestion]] = [:]
    var intervals: [String: Double] = [:]
    var currentAppLaunchSurvey: String = ""
    var currentAfterRouteSurvey: String = ""
    
    private init() {
        setupListeners()
    }
    
    private func setupListeners() {
        let surveysRef = databaseHandle.reference(withPath: "surveys")
        surveysRef.observe(.childAdded) { (snapshot) -> Void in
            self.populateModel(snapshot)
        }
        surveysRef.observe(.childChanged) { (snapshot) -> Void in
            self.populateModel(snapshot)
        }
    }
    private func populateModel(_ snapshot: DataSnapshot) {
        print(snapshot.key)
        
        if snapshot.key == "currentAppLaunchSurvey" {
            self.currentAppLaunchSurvey = snapshot.value as? String ?? "defaultSurvey"
        } else if snapshot.key == "currentAfterRouteSurvey" {
            self.currentAfterRouteSurvey = snapshot.value as? String ?? "defaultSurvey"
        }
        
        var surveyQuestions: [SurveyQuestion] = []
        guard let surveyQuestionsRaw = snapshot.value as? [String: Any] else {
            return
        }
        var presentationIntervalInSeconds: Double = 0.0
        for (childKey, childValue) in surveyQuestionsRaw {
            if childKey == "_presentationIntervalInSeconds" {
                if let newInterval = childValue as? Double {
                    presentationIntervalInSeconds = newInterval
                }
                continue
            }
            guard let questionDefinition = childValue as? [String: Any], let prompt = questionDefinition["prompt"] as? [String: String], let questionType = questionDefinition["type"] as? String, let questionTypeEnum = QuestionType(rawValue: questionType), let questionOrder = questionDefinition["order"] as? Int, let text = prompt["en"] else {
                continue
            }
            let numericalDefault = questionDefinition["numericalDefault"] as? Float
            let numericalMin = questionDefinition["numericalMin"] as? Float
            let numericalMax = questionDefinition["numericalMax"] as? Float
            let quantizeSlider = questionDefinition["quantizeSlider"] as? Bool
            let addSliderAccent = questionDefinition["addSliderAccent"] as? Bool

            let booleanDefault = questionDefinition["booleanDefault"] as? Bool
            let required = questionDefinition["required"] as? Bool ?? true
            let isEmail = questionDefinition["isEmail"] as? Bool ?? false
            var choices: [MultipleChoiceOption] = []
            if let choiceDict = questionDefinition["choices"] as? [String : [String: Any] ] {
                for (choiceKey, choiceDescription) in choiceDict {
                    if let choice = MultipleChoiceOption(key: choiceKey, firebaseData: choiceDescription) {
                        choices.append(choice)
                    }
                }
            }
            choices.sort(by: {$0.choiceOrder < $1.choiceOrder})
            surveyQuestions.append(SurveyQuestion(name: childKey, text: text, localizations: prompt, questionType: questionTypeEnum, required: required, isEmail: isEmail, order: questionOrder, numericalDefault: numericalDefault, numericalMin: numericalMin, numericalMax: numericalMax, quantizeSlider: quantizeSlider, addSliderAccent: addSliderAccent, booleanDefault: booleanDefault, choices: choices))
        }
        questions[snapshot.key] = surveyQuestions
        intervals[snapshot.key] = presentationIntervalInSeconds
        print("intervals", intervals)
    }
    
}

struct FirebaseFeedbackSurvey: View {
    var simpleForm = SF()
    var presentingVC: UIViewController?
    let feedbackSurveyName: String
    let logFileURLs: [String]
    @State var testText: String = ""
    @State var calculatedHeight: CGFloat = 0.0

    init(feedbackSurveyName: String, logFileURLs: [String]) {
        self.feedbackSurveyName = feedbackSurveyName
        self.logFileURLs = logFileURLs
    }
    
    var body: some View {
        let orderedQuestions = FirebaseFeedbackSurveyModel.shared.questions[feedbackSurveyName] != nil ? FirebaseFeedbackSurveyModel.shared.questions[feedbackSurveyName]!.sorted(by: {$0.order < $1.order}) : []
        
        // Section One
        let sectionOne = SimpleFormSection()
        for question in orderedQuestions {
            switch question.questionType {
            case .textField:
                sectionOne.model.fields.append(SimpleFormField(textField: question.localizedText, labelPosition: .above, name: question.name, value: "", validation: (question.required ? [.required] : []) + (question.isEmail ? [.email] : [])))
            case .textView:
                sectionOne.model.fields.append(SimpleFormField(textView: question.localizedText, labelPosition: .above, name: question.name, value: "", validation: (question.required ? [.required] : []) + (question.isEmail ? [.email] : [])))
            case .slider:
                sectionOne.model.fields.append(SimpleFormField(sliderField: question.localizedText, name: question.name, value: question.numericalDefault ?? 0.5, addSliderAccent: question.addSliderAccent ?? false, quantizeSlider: question.quantizeSlider ?? false, range: (question.numericalMin ?? 0.0)...(question.numericalMax ?? 1.0)))
            case .stepper:
                sectionOne.model.fields.append(SimpleFormField(stepperField: question.localizedText, name: question.name, value: (question.numericalDefault ?? 3), range: (question.numericalMin ?? 1)...(question.numericalMax ?? 5)))
            case .toggle:
                sectionOne.model.fields.append(SimpleFormField(toggleField: question.localizedText, name: question.name, value: question.booleanDefault ?? true))
            case .checkboxes:
                sectionOne.model.fields.append(SimpleFormField(checkboxesField: question.localizedText, name: question.name, choices: question.localizedChoices, value: false))
            case .title:
                sectionOne.model.fields.append(SimpleFormField(title: question.localizedText))
            }
        }
            
        self.simpleForm.model.sections.append(sectionOne)
        return NavigationView {
            VStack {
                simpleForm
                    .navigationBarTitle(Text(NSLocalizedString("surveyPopoverTitle", comment: "This is the title of the survey popover that is displayed to get feedback")), displayMode: .inline).navigationBarItems(trailing: Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil)
                    }) { Text(NSLocalizedString("dismissSurvey", comment: "this is the button text that dismisses the survey"))})
                Button(action: {
                    if self.simpleForm.isValid() {
                        var formValues = self.simpleForm.getValues()
                        formValues["_preferredLanguage"] = Locale.current.languageCode ?? ""
                        formValues["_dateSubmitted"] = Date().timeIntervalSince1970
                        formValues["_uid"] = Auth.auth().currentUser?.uid ?? "notsignedin"
                        formValues["_logFileURLs"] = logFileURLs
                        let jsonData = try! JSONSerialization.data(withJSONObject: formValues, options: .prettyPrinted)
                        self.uploadToFirebase(data: jsonData)
                    }
                }){
                    Text(NSLocalizedString("submitSurvey", comment: "this is the button text that submits the survey"))
                }
            }
        }
    }
    
    func uploadToFirebase(data: Data) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        let feedbackRef = Storage.storage().reference().child("feedback/\(uid)")
        let uniqueID = UUID().uuidString

        ///creates a reference to the location we want to save the new file
        let fileRef = feedbackRef.child("\(uniqueID)_\(feedbackSurveyName).json")
        
        let fileType = StorageMetadata()
        fileType.contentType = "application/json"
        let _ = fileRef.putData(data, metadata: fileType){ (metadata, error) in
            if metadata == nil {
                print("could not upload feedback to firebase", error!.localizedDescription)
            } else {
                print("uploaded data successfully")
            }
            NotificationCenter.default.post(name: Notification.Name("SurveyPopoverReadyToDismiss"), object: true)
        }
    }
}
