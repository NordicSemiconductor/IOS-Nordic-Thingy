/*
 Copyright (c) 2010 - 2017, Nordic Semiconductor ASA
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form, except as embedded into a Nordic
 Semiconductor ASA integrated circuit in a product or a software update for
 such product, must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other
 materials provided with the distribution.
 
 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 contributors may be used to endorse or promote products derived from this
 software without specific prior written permission.
 
 4. This software, with or without modification, must only be used with a
 Nordic Semiconductor ASA integrated circuit.
 
 5. Any software provided in binary form under this license must not be reverse
 engineered, decompiled, modified and/or disassembled.
 
 THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
//
//  MotionSettingsViewController.swift
//
//  Created by Mostafa Berg on 13/12/2016.
//

import UIKit

class MotionSettingsViewController: ThingyTableViewController, UIPopoverPresentationControllerDelegate {
    
    //MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: Any) {
        handleCancel()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        handleSave()
    }
    
    //MARK: - Outlets
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var pedometerLabel: UILabel!
    @IBOutlet weak var processingFrequencyLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var compassLabel: UILabel!
    @IBOutlet weak var wakeOnMotionSwitch: UISwitch!
    
    private var pedometerInterval        : UInt16 = 0
    private var motionProcessingFrequency: UInt16 = 0
    private var tempCompensationInterval : UInt16 = 0
    private var compassInterval          : UInt16 = 0

    //MARK: - UIViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        (pedometerInterval, tempCompensationInterval, compassInterval, motionProcessingFrequency, wakeOnMotionSwitch.isOn) = targetPeripheral!.readMotionConfiguration()!
        
        pedometerLabel.text = "\(pedometerInterval) ms"
        processingFrequencyLabel.text = "\(motionProcessingFrequency) Hz"
        temperatureLabel.text = "\(tempCompensationInterval) ms"
        compassLabel.text = "\(compassInterval) ms"
    }

    //MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: // Pedometer interval
                PopupHelper.showIntervalInput(withTitle: "Pedometer interval", subtitle: "Range: 100 ms - 5000 ms",
                                              value: Int(pedometerInterval), availableRange: NSMakeRange(100, 5000 - 100 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value) -> (Void) in
                                                self.pedometerInterval = UInt16(value)
                                                self.pedometerLabel.text = "\(value) ms"
                                              })
            case 1: // Motion processing unit interval
                PopupHelper.showIntervalInput(withTitle: "Motion processing unit freq.", subtitle: "Range: 1 Hz - 200 Hz",
                                              value: Int(motionProcessingFrequency), availableRange: NSMakeRange(1, 200 - 1 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Frequency",
                                              completion: { (value) -> (Void) in
                                                self.motionProcessingFrequency = UInt16(value)
                                                self.processingFrequencyLabel.text = "\(value) Hz"
                                              })
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0: // Temp compensation interval
                PopupHelper.showIntervalInput(withTitle: "Temp. compensation interval",
                                              subtitle: "Gyro sensor depends on the temperature. The sensor is automaticaly calibrated every given number of ms.\nRange: 100 ms - 5000 ms",
                                              value: Int(tempCompensationInterval), availableRange: NSMakeRange(100, 5000 - 100 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value) -> (Void) in
                                                self.tempCompensationInterval = UInt16(value)
                                                self.temperatureLabel.text = "\(value) ms"
                                              })
            case 1: // Compass compansation interval
                PopupHelper.showIntervalInput(withTitle: "Compass compensation interval",
                                              subtitle: "Motion sensors are automatically calibrated using magnetometer every given number of ms. Range: 100 ms - 5000 ms",
                                              value: Int(tempCompensationInterval), availableRange: NSMakeRange(100, 5000 - 100 + 1), unitInMs: 1.0,
                                              andPlaceholderValue: "Interval",
                                              completion: { (value) -> (Void) in
                                                self.tempCompensationInterval = UInt16(value)
                                                self.compassLabel.text = "\(value) ms"
                                              })
            default:
                break
            }
        case 2:
            if indexPath.row == 0 {
                wakeOnMotionSwitch.setOn(!wakeOnMotionSwitch.isOn, animated: true)
            }
            break
        default:
            break
        }
    }
    
    //MARK: - Implementation
    private func handleSave() {
        let (pedometerInterval, tempCompensationInterval, compassInterval, motionProcessingFrequency, wakeOnMotion) = targetPeripheral!.readMotionConfiguration()!
        let dataChanged = pedometerInterval != self.pedometerInterval ||
            tempCompensationInterval != self.tempCompensationInterval ||
            compassInterval != self.compassInterval ||
            motionProcessingFrequency != self.motionProcessingFrequency ||
            wakeOnMotion != self.wakeOnMotionSwitch.isOn
        
        // Save data only when at least one value has been changed
        if dataChanged {
            let loadingView = UIAlertController(title: "Configuring Thingy", message: "Sending configuration...", preferredStyle: .alert)
            present(loadingView, animated: true) {
                self.targetPeripheral!.setMotionConfiguration(
                    pedometerInterval: self.pedometerInterval,
                    temperatureCompensationInterval: self.tempCompensationInterval,
                    compassInterval: self.compassInterval,
                    motionProcessingInterval: self.motionProcessingFrequency,
                    wakeOnMotion: self.wakeOnMotionSwitch.isOn,
                    withCompletionHandler: {
                        (success) -> (Void) in
                        if success {
                            loadingView.message = "Done!"
                            loadingView.dismiss(animated: true, completion: {
                                self.handleCancel()
                            })
                        } else {
                            loadingView.message = "Failed!"
                            loadingView.dismiss(animated: true)
                            print("Couldn't save motion configuration!")
                        }
                })
            }
        } else {
            // Otherwise just dismiss the settings view controller
            handleCancel()
        }
    }
    
    private func handleCancel() {
        navigationController?.dismiss(animated: true)
    }
}
