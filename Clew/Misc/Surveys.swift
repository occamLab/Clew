import SwiftUI
import SimpleForm
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

enum QuestionType: String {
    case textField = "textField"
    case slider = "slider"
}

struct SurveyQuestion {
    let name: String
    let text: String
    let questionType: QuestionType
    let required: Bool
    let order: Int
    let sliderDefault: Float?
    let sliderMin: Float?
    let sliderMax: Float?
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
        guard let questionDefinition = snapshot.value as? [String: Any], let text = questionDefinition["english"] as? String, let questionType = questionDefinition["type"] as? String, let questionTypeEnum = QuestionType(rawValue: questionType), let questionOrder = questionDefinition["order"] as? Int else {
            return
        }
        let sliderDefault = questionDefinition["sliderDefault"] as? Float
        let sliderMin = questionDefinition["sliderMin"] as? Float
        let sliderMax = questionDefinition["sliderMax"] as? Float

        let requiredString = questionDefinition["required"] as? String ?? "true"
        questions.append(SurveyQuestion(name: snapshot.key, text: text, questionType: questionTypeEnum, required: requiredString != "false", order: questionOrder, sliderDefault: sliderDefault, sliderMin: sliderMin, sliderMax: sliderMax))
    }
}

struct FirebaseFeedbackSurvey: View {
    
    var simpleForm = SF()
    var presentingVC: UIViewController?

    var body: some View {
        let orderedQuestions = FirebaseFeedbackSurveyModel.shared.questions.sorted(by: {$0.order < $1.order})
        
        // Section One
        let sectionOne = SimpleFormSection()
        for question in orderedQuestions {
            switch question.questionType {
            case .textField:
                sectionOne.model.fields.append(SimpleFormField(textField: question.text, labelPosition: .above, name: question.name, value: "", validation: question.required ? [.required] : []))
            case .slider:
                sectionOne.model.fields.append(SimpleFormField(sliderField: question.text, name: question.name, value: (question.sliderDefault ?? 0.5), range: (question.sliderMin ?? 0.0)...(question.sliderMax ?? 1.0)))
            }
        }
        self.simpleForm.model.sections.append(sectionOne)
        return NavigationView {
            simpleForm
                .navigationBarTitle("Simple Form", displayMode: .inline).navigationBarItems(trailing: Button(action: {
                    if self.simpleForm.isValid() {
                        var formValues = self.simpleForm.getValues()
                        formValues["_dateSubmitted"] = Date().timeIntervalSince1970
                        let jsonData = try! JSONSerialization.data(withJSONObject: formValues, options: .prettyPrinted)
                        self.uploadToFirebase(data: jsonData)
                    }
                }){
                    Text("Submit")
                })
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
        print(fileRef)
        
        /// Upload the file to the path defined by fileRef then checks for any errors
        let _ = fileRef.putData(data, metadata: fileType){ (metadata, error) in
            if metadata == nil {
                /// prints an errorstatement to the console
                print("could not upload feedback to firebase", error!.localizedDescription)
                ///sets the return value equal to 1 if an error ocurred
                ///quits the conditional
            } else {
                print("uploaded data successfully")
            }
            NotificationCenter.default.post(name: Notification.Name("SurveyPopoverReadyToDismiss"), object: nil)
        }
    }
}
