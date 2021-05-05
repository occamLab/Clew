import SwiftUI
import UIKit
import SimpleForm
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

enum QuestionType: String {
    case textField = "textField"
    case textView = "textView"
    case slider = "slider"
    case stepper = "stepper"
}

struct SurveyQuestion {
    let name: String
    let text: String
    let localizations: [String: String]
    let questionType: QuestionType
    let required: Bool
    let order: Int
    let numericalDefault: Float?
    let numericalMin: Float?
    let numericalMax: Float?
    var localizedText: String {
        if let languageCode = Locale.current.languageCode, let localized = localizations[languageCode] {
            return localized
        } else {
            return text
        }
    }
}

class FirebaseFeedbackSurveyModel {
    let databaseHandle = Database.database()
    public static var shared = FirebaseFeedbackSurveyModel()
    var questions: [SurveyQuestion] = []

    private init() {
        setupListeners()
    }
    
    private func setupListeners() {
        let surveysRef = databaseHandle.reference(withPath: "surveys/main")
        surveysRef.observe(.childAdded) { (snapshot) -> Void in
            self.populateModel(snapshot)
        }
        surveysRef.observe(.childChanged) { (snapshot) -> Void in
            self.populateModel(snapshot)
        }
    }
    private func populateModel(_ snapshot: DataSnapshot) {
        // TODO: avoid hardcode to English
        guard let questionDefinition = snapshot.value as? [String: Any], let prompt = questionDefinition["prompt"] as? [String: String], let questionType = questionDefinition["type"] as? String, let questionTypeEnum = QuestionType(rawValue: questionType), let questionOrder = questionDefinition["order"] as? Int, let text = prompt["en"] else {
            return
        }
        let numericalDefault = questionDefinition["numericalDefault"] as? Float
        let numericalMin = questionDefinition["numericalMin"] as? Float
        let numericalMax = questionDefinition["numericalMax"] as? Float

        let requiredString = questionDefinition["required"] as? String ?? "true"
        questions.append(SurveyQuestion(name: snapshot.key, text: text, localizations: prompt, questionType: questionTypeEnum, required: requiredString != "false", order: questionOrder, numericalDefault: numericalDefault, numericalMin: numericalMin, numericalMax: numericalMax))
    }
}

struct FirebaseFeedbackSurvey: View {
    
    var simpleForm = SF()
    var presentingVC: UIViewController?
    let logFileURLs: [String]
    @State var testText: String = ""
    @State var calculatedHeight: CGFloat = 0.0

    init(logFileURLs: [String]) {
        self.logFileURLs = logFileURLs
    }
    
    var body: some View {
        let orderedQuestions = FirebaseFeedbackSurveyModel.shared.questions.sorted(by: {$0.order < $1.order})
        
        // Section One
        let sectionOne = SimpleFormSection()
        for question in orderedQuestions {
            switch question.questionType {
            case .textField:
                sectionOne.model.fields.append(SimpleFormField(textField: question.localizedText, labelPosition: .above, name: question.name, value: "", validation: question.required ? [.required] : []))
            case .textView:
                sectionOne.model.fields.append(SimpleFormField(textView: question.text, labelPosition: .above, name: question.name, value: "", validation: question.required ? [.required] : []))
            case .slider:
                sectionOne.model.fields.append(SimpleFormField(sliderField: question.text, name: question.name, value: (question.numericalDefault ?? 0.5), range: (question.numericalMin ?? 0.0)...(question.numericalMax ?? 1.0)))
            case .stepper:
                sectionOne.model.fields.append(SimpleFormField(stepperField: question.text, name: question.name, value: (question.numericalDefault ?? 3), range: (question.numericalMin ?? 1)...(question.numericalMax ?? 5)))
            }
        }
        self.simpleForm.model.sections.append(sectionOne)
        return NavigationView {
            VStack {
                simpleForm
                    .navigationBarTitle(Text(NSLocalizedString("surveyPopoverTitle", comment: "This is the title of the survey popover that is displayed to get feedback")), displayMode: .inline).navigationBarItems(trailing: Button(action: {
                        if self.simpleForm.isValid() {
                            var formValues = self.simpleForm.getValues()
                            formValues["_dateSubmitted"] = Date().timeIntervalSince1970
                            formValues["_uid"] = Auth.auth().currentUser?.uid ?? "notsignedin"
                            formValues["_logFileURLs"] = logFileURLs
                            let jsonData = try! JSONSerialization.data(withJSONObject: formValues, options: .prettyPrinted)
                            self.uploadToFirebase(data: jsonData)
                        }
                    }){
                        Text(NSLocalizedString("submitSurvey", comment: "this is the button text that submits the survey"))
                    })
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
        let fileRef = feedbackRef.child("\(uniqueID)_main.json")
        
        let fileType = StorageMetadata()
        fileType.contentType = "application/json"
        let _ = fileRef.putData(data, metadata: fileType){ (metadata, error) in
            if metadata == nil {
                print("could not upload feedback to firebase", error!.localizedDescription)
            } else {
                print("uploaded data successfully")
            }
            NotificationCenter.default.post(name: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil)
        }
    }
}
