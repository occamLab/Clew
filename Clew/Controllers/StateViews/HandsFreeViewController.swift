//
//  HandsFreeViewController.swift
//  Clew
//
//  Created by Arwa Naj on 22/06/2021.
//  Copyright © 2021 OccamLab. All rights reserved.
//

import Foundation



import UIKit
import AVFoundation
import Speech

class HandsFreeViewController: UIViewController {
  let audioEngine = AVAudioEngine()
  let speechRecognizer = SFSpeechRecognizer()
  let request = SFSpeechAudioBufferRecognitionRequest()
  var recognitionTask: SFSpeechRecognitionTask?
  var mostRecentlyProcessedSegmentDuration: TimeInterval = 0


  
   override  func viewDidLoad() {
    super.viewDidLoad()
   
    SFSpeechRecognizer.requestAuthorization {
      [unowned self] (authStatus) in
      switch authStatus {
      case .authorized:
        do {
          try self.startRecording()
        } catch let error {
          print("There was a problem starting recording: \(error.localizedDescription)")
        }
      case .denied:
        print("Speech recognition authorization denied")
      case .restricted:
        print("Not available on this device")
      case .notDetermined:
        print("Not determined")
      }
    }
  }


extension LiveTranscribeViewController {
  fileprivate func startRecording() throws {
    mostRecentlyProcessedSegmentDuration = 0

    self.transcriptionOutputLabel.text = ""
    // 1
    let node = audioEngine.inputNode
    let recordingFormat = node.outputFormat(forBus: 0)

    // 2
    node.installTap(onBus: 0, bufferSize: 1024,
                    format: recordingFormat) { [unowned self]
                      (buffer, _) in
                      self.request.append(buffer)
    }

    // 3
    audioEngine.prepare()
    try audioEngine.start()
    recognitionTask = speechRecognizer?.recognitionTask(with: request) {
      [unowned self]
      (result, _) in
      if let transcription = result?.bestTranscription {
        self.updateUIWithTranscription(transcription)
      }
    }
  }

  fileprivate func stopRecording() {
    audioEngine.stop()
    request.endAudio()
    recognitionTask?.cancel()
  }
}



  // 1
  fileprivate func updateUIWithTranscription(_ transcription: SFTranscription) {
    self.transcriptionOutputLabel.text = transcription.formattedString

    // 2
    if let lastSegment = transcription.segments.last,
      lastSegment.duration > mostRecentlyProcessedSegmentDuration {
      mostRecentlyProcessedSegmentDuration = lastSegment.duration
      // 3
        print("livehere")
        
      print(lastSegment.substring)
    }
  }
}


