//
//  SettingsViewController.swift
//  Cetvel
//
//  Created by Kurtulus Ahmet on 18.12.2017.
//  Copyright © 2017 Kurtulus Ahmet. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var unitSegment: UISegmentedControl!
    @IBOutlet weak var focusSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        unitSegment.selectedSegmentIndex = MeasurementUnit.Unit.all.index(of: ApplicationSetting.Status.defaultUnit)!
        focusSwitch.isOn = ApplicationSetting.Status.displayFocus
        focusSwitch.onTintColor = UIColor(red: 58 / 255.0, green: 83 / 255.0, blue: 155 / 255.0, alpha: 1.0)
    }

    @IBAction func lengthUnitAction(_ sender: UISegmentedControl) {
        ApplicationSetting.Status.defaultUnit = MeasurementUnit.Unit.all[sender.selectedSegmentIndex]
    }
    
    @IBAction func closeButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func focusAction(_ sender: UISwitch) {
        ApplicationSetting.Status.displayFocus = sender.isOn
    }
    

}
