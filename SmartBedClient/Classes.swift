//
//  Classes.swift
//  SmartBedClient
//
//  Created by Eugene L. on 2/2/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import Foundation

class Bed: Codable {
    
    var BedNo: Int
    var BedWeight: Double
    var BedRPM: Double
    
    init(code: Int, weight: Double, rpm: Double) {
        BedNo = code
        BedWeight = weight
        BedRPM = rpm
    }
    
    func IsNo(text: String) -> Bool {
        if String(BedNo).uppercased().contains(text.uppercased()) { return true }
        return false
    }
    
}
