//
//  CoachMarks.swift
//  Clew
//
//  Created by Terri Liu on 2019/6/28.
//  Copyright © 2019 OccamLab. All rights reserved.
//

import UIKit
import Instructions

<<<<<<< HEAD:Clew/TutorialViewController.swift

class TutorialViewController: UIViewController, CoachMarksControllerDataSource, CoachMarksControllerDelegate {

    @IBOutlet weak var staticLabel2: DesignableLabel!
    @IBAction func CloseTips(_ sender: UIButton) {

        
        //initializing tutorial delegate
        var appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismiss(animated: false)
        appDelegate.window = UIWindow(frame:UIScreen.main.bounds)
        appDelegate.window?.makeKeyAndVisible()
        appDelegate.window?.rootViewController = ViewController()
        print("hi")
    }
    
    //////////
=======
//TODO: Edit and add place to put parameters
class CoachMarks: UIViewController, CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
>>>>>>> 1cf7d6d5d22691e2a20e6cf306b8c05f3e0513f9:Clew/Controllers/Tutorial VCs/CoachMarks.swift
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coachMarksController.dataSource = self
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
    
    let pointOfInterest = UIView()
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        pointOfInterest.center = CGPoint(x: 210, y: 660)
        return coachMarksController.helper.makeCoachMark(for: pointOfInterest)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = "Click here when you're ready!"
        coachViews.bodyView.nextLabel.text = "Ok!"
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.coachMarksController.start(in: .window(over: self))
    }
    
}
