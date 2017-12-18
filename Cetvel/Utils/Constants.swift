//
//  Constants.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 17.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit
import AudioToolbox
import VideoToolbox

struct Image {
    struct Menu {
        static let area = #imageLiteral(resourceName: "menu_area")
        static let length = #imageLiteral(resourceName: "menu_length")
        static let reset = #imageLiteral(resourceName: "menu_reset")
        static let setting = #imageLiteral(resourceName: "menu_setting")
        static let save = #imageLiteral(resourceName: "menu_save")
    }
    struct More {
        static let close = #imageLiteral(resourceName: "more_off")
        static let open = #imageLiteral(resourceName: "more_on")
    }
    struct Place {
        static let area = #imageLiteral(resourceName: "place_area")
        static let length = #imageLiteral(resourceName: "place_length")
        static let done = #imageLiteral(resourceName: "place_done")
    }
    struct Close {
        static let delete = #imageLiteral(resourceName: "cancle_delete")
        static let cancle = #imageLiteral(resourceName: "cancle_back")
    }
    struct Indicator {
        static let enable = #imageLiteral(resourceName: "img_indicator_enable")
        static let disable = #imageLiteral(resourceName: "img_indicator_disable")
    }
    struct Result {
        static let copy = #imageLiteral(resourceName: "result_copy")
    }
}

struct Sound {
    static var soundID: SystemSoundID = 0
    static func install() {
        guard let path = Bundle.main.path(forResource: "click", ofType: "wav") else { return  }
        let url = URL(fileURLWithPath: path)
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
    }
    static func play() {
        guard soundID != 0 else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    static func dispose() {
        guard soundID != 0 else { return }
        AudioServicesDisposeSystemSoundID(soundID)
    }
    
}
