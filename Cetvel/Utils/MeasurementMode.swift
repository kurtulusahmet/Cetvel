//
//  MeasurementMode.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 17.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit

let labelColor = UIColor(red: 58 / 255.0, green: 83 / 255.0, blue: 155 / 255.0, alpha: 1.0)

enum MeasurementMode {
    case length
    case area
    func toAttrStr() -> NSAttributedString {
        let str = self == .area ? "Alan Ölçümü" : "Uzunluk Ölçümü"
        return NSAttributedString(string: str, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 20),
                                                            NSAttributedStringKey.foregroundColor: labelColor])
    }
}
