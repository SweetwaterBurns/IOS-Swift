//
//  ViewController.swift
//  TipCalculator
//
//  Created by Ian Mitchell on 3/18/15.
//  Copyright (c) 2015 Ian Mitchell. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let tipCalc = TipCalculator(billTotal: 0.00, politeness: 3, accuracy: 3, promptness: 3)

    @IBOutlet weak var billTextField: UITextField!
    @IBOutlet weak var tipTextView: UITextView!
    @IBOutlet weak var totalTextView: UITextView!
    
    @IBOutlet weak var politenessSlider: UISlider!
    @IBOutlet weak var politenessTextView: UITextView!
    
    @IBOutlet weak var accuracySlider: UISlider!
    @IBOutlet weak var accuracyTextView: UITextView!
    
    @IBOutlet weak var promptnessSlider: UISlider!
    @IBOutlet weak var promptnessTextView: UITextView!
    
    @IBAction func politenessChange(sender: AnyObject) {
        tipCalc.politeness = Int(politenessSlider.value)
        refreshUI()
    }
    
    @IBAction func accuracyChange(sender: AnyObject) {
        tipCalc.accuracy = Int(accuracySlider.value)
        refreshUI()
    }
    
    @IBAction func promptnessChange(sender: AnyObject) {
        tipCalc.promptness = Int(promptnessSlider.value)
        refreshUI()
    }
   
    @IBAction func billChanged(sender: AnyObject) {
        tipCalc.billTotal = Double((billTextField.text as NSString).doubleValue)
        refreshUI()
    }
    
/*    @IBAction func calculate(sender: AnyObject) {
        tipCalc.billTotal = Double((billTextField.text as NSString).doubleValue)
        refreshUI()
    }
  */
    @IBAction func viewTapped(sender : AnyObject) {
          billTextField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        refreshUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refreshUI(){
        if !billTextField.editing{
            tipCalc.billTotal = Double((billTextField.text as NSString).doubleValue)
            billTextField.text = String(format: "%0.2f", tipCalc.billTotal)
        }
        
        tipTextView.text = String(format: "%0.2f", tipCalc.tip)
        totalTextView.text = String(format: "%0.2f", tipCalc.total)
        politenessSlider.value = Float(tipCalc.politeness)
        politenessTextView.text = String(tipCalc.politeness)
        accuracySlider.value = Float(tipCalc.accuracy)
        accuracyTextView.text = String(tipCalc.accuracy)
        promptnessSlider.value = Float(tipCalc.promptness)
        promptnessTextView.text = String(tipCalc.promptness)
    }
}

