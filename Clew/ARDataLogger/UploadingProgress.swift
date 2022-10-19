//
//  File.swift
//  
//
//  Created by Paul Ruvolo on 9/8/21.
//

import Foundation
import SwiftUI

struct LoadingView<Content>: View where Content: View {
    @Binding var isShowing: Bool  // should the modal be visible?
    var content: () -> Content
    var text: String?  // the text to display under the ProgressView - defaults to "Loading..."
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // the content to display - if the modal is showing, we'll blur it
                content()
                    .disabled(isShowing)
                    .blur(radius: isShowing ? 2 : 0)

                // all contents inside here will only be shown when isShowing is true
                if isShowing {
                    // this Rectangle is a semi-transparent black overlay
                    Rectangle()
                        .fill(Color.black).opacity(isShowing ? 0.6 : 0)
                        .edgesIgnoringSafeArea(.all)

                    // the magic bit - our ProgressView just displays an activity
                    // indicator, with some text underneath showing what we are doing
                    VStack(spacing: 48) {
                        ProgressView().scaleEffect(2.0, anchor: .center)
                        Text(text ?? "Uploading Data...").font(.title).fontWeight(.semibold)
                    }
                    .frame(width: 250, height: 200)
                    .background(Color.white)
                    .foregroundColor(Color.primary)
                    .cornerRadius(16)
                }
            }
        }
    }
}


public struct UploadingViewNoBinding: View {
    @State var uploadingViewShowing = true
    public init() {
        
    }
    public var body: some View {
        // Your entire view should go inside the LoadingView, so that the modal
        // can appear on top, as well as blur the content
        LoadingView(isShowing: $uploadingViewShowing) {
            Spacer()
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // TODO: possibly do some sort of announcement at this time (not sure the best mechanism for coordination with the client app)
            }
        }
    }
}

public struct UploadingView: View {
    @Binding var loadingViewShowing: Bool

    public init(loadingViewShowing: Binding<Bool>) {
        self._loadingViewShowing = loadingViewShowing
    }

    public var body: some View {
        // Your entire view should go inside the LoadingView, so that the modal
        // can appear on top, as well as blur the content
        LoadingView(isShowing: $loadingViewShowing) {
            Spacer()
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // TODO: possibly do some sort of announcement at this time (not sure the best mechanism for coordination with the client app)
            }
        }
    }
}
