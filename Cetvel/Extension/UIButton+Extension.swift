//
//  UIButton+Extension.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 17.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit

extension UIButton {
    public convenience init(size: CGSize, image: UIImage?) {
        self.init(frame: CGRect(origin: CGPoint.zero, size: size))
        setImage(image, for: .normal)
        setImage(image, for: .disabled)
        
    }
    
    public var disabledImage: UIImage? {
        get {
            return image(for: .disabled)
        }
        set {
            setImage(newValue, for: .disabled)
        }
    }
    
    public var normalImage: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }
}
