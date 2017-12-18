//
//  UIAlertController+Dismiss.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 16.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit

struct HUD {
    
    private static var _alertController: UIAlertController?
    
    static var isVisible: Bool {
        return _alertController != nil
    }
    static func show(title: String?,
                     message: String? = nil,
                     inSource viewController: UIViewController? = nil ,
                     autoDismissDuration duration: TimeInterval? = 5) {
        
        func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return topViewController(nav.visibleViewController)
            }
            if let tab = base as? UITabBarController {
                if let selected = tab.selectedViewController {
                    return topViewController(selected)
                }
            }
            if let presented = base?.presentedViewController {
                return topViewController(presented)
            }
            return base
        }
        
        let vc = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        guard let source = viewController ?? topViewController() else { return }
        _alertController?.dismiss(animated: false, completion: nil)
        _alertController = vc
        source.present(vc, animated: true, completion: nil)
        if let d = duration {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: UInt64(d) * NSEC_PER_SEC), execute: {
                vc.dismiss(animated: true, completion: nil)
                _alertController = nil
            })
        }
    }
    
    static func dismiss() {
        _alertController?.dismiss(animated: true, completion: nil)
        _alertController = nil
    }
    
}
