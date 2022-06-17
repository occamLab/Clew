//
//  InformedConsentView.swift
//  LidarCane
//
//  Created by Paul Ruvolo on 3/4/21.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase

struct InformedConsentView : View {
    @ObservedObject var informedConsentModel = InformedConsentViewModel()
    @State var showEmailAlert: Bool = false
    @State var destinationIsActive: Bool = false
    @State var isValid: Bool = false
    
    var body: some View {
        return
            ZStack{
                GeometryReader { geometry in
                    VStack {
                        WebView(urlType: .localUrl, viewModel: ViewModel()).frame(height: geometry.size.height*8/10)
                        ZStack {
                            TextField("Enter email", text: $informedConsentModel.userEmail)
                                .frame(height: 45)
                                .keyboardType(.emailAddress)
                                .padding(.leading, 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .stroke()
                                .foregroundColor(.gray)
                                .opacity(0.3)
                                .frame(height: 45)
                        }
                        .padding([.leading, .top, .trailing], 8)
                        
                        VStack {
                            Button(informedConsentModel.didEnterValidEmail ? "Consent to Participate" : "Please enter your email address") {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let sceneDelegate = windowScene.delegate as? SceneDelegate, let uid = Auth.auth().currentUser?.uid
                                  else {
                                    return
                                  }
                                let ref = Database.database().reference().child("appclipexperiment").child("emails").child(uid)
                                print(ref.url)
                                ref.setValue(["email": informedConsentModel.userEmail])
                                UserDefaults.standard.setValue(true, forKey: "hasconsented")
                                
                                let vc = ViewController()

                                sceneDelegate.window?.rootViewController = vc
                            }
                            .disabled(!informedConsentModel.didEnterValidEmail)
                            .padding([.leading, .top, .trailing], 8)
                            
                            Button("or Continue without data logging") {
                               guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                     let sceneDelegate = windowScene.delegate as? SceneDelegate, let uid = Auth.auth().currentUser?.uid
                                 else {
                                   return
                                 }
                                // set hasconsented key to false
                                UserDefaults.standard.setValue(false, forKey: "hasconsented")

                                // redirect to home UI
                                let vc = ViewController()
                                sceneDelegate.window?.rootViewController = vc
                            }
                            .padding([.leading, .top, .trailing], 8)

                        }
                    }
                    .padding()
                }
            }.navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle(Text("INFORMED CONSENT DOCUMENT"), displayMode: .inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                // TODO: check if we need to login
            }
        }
    }
    

#if DEBUG
struct InformedConsentView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            InformedConsentView()
        }
    }
}
#endif
