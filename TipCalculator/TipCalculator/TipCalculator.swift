//
//  TipCalculatorModel.swift
//  TipCalculator
//
//  Created by Ian Mitchell on 3/18/15.
//  Copyright (c) 2015 Ian Mitchell. All rights reserved.
//

import Foundation

class TipCalculator{
    
    let scoreWeight = 0.01
    var politeness  = 3
    var accuracy = 3
    var promptness = 3
    
    var billTotal = 0.0
    
    var tip: Double {
        get {
            return billTotal * Double(politeness + accuracy + promptness) * scoreWeight
        }
    }
    
    var total: Double {
        get {
            return billTotal + tip
        }
    }
    
    init(billTotal: Double){
        self.billTotal = billTotal
    }
    
    init(billTotal: Double, politeness: Int, accuracy: Int, promptness: Int){
        self.billTotal = billTotal
        self.politeness = politeness
        self.accuracy = accuracy
        self.promptness = promptness
    }
}
