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
//  ThingyUserInterfaceViewController.swift
//
//  Created by Mostafa Berg on 06/10/16.
//

import UIKit
import IOSThingyLibrary

class ThingyUserInterfaceViewController: SwipableTableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {

    //MARK: - Properties
    private var viewHasAppeared                     : Bool = false
    private var presetColors                        : [UIColor]!
    private var activeCell                          : ColorCollectionViewCell!
    private var currentSelectedColorIdx             : UInt8 = 0
    private var currentLightIntensity               : UInt8 = 100
    private var currentBreatheDelay                 : UInt16 = 3500
    private var currentMode                         : ThingyLEDMode = .breathe
    private var redSliderTapRecognizer              : UITapGestureRecognizer!
    private var greenSliderTapRecognizer            : UITapGestureRecognizer!
    private var blueSliderTapRecognizer             : UITapGestureRecognizer!
    private var lightIntensitySliderTapRecognizer   : UITapGestureRecognizer!

    //MARK: - Outlets and actions
    @IBOutlet weak var buttonStateLabel: UILabel!
    @IBOutlet weak var ledModeControl: UISegmentedControl!
    
    @IBOutlet weak var colorCollectionView: UICollectionView!
    @IBOutlet weak var intensityLabel: UILabel!
    @IBOutlet weak var breatheDelayLabel: UILabel!
    @IBOutlet weak var breatheDelayTextField: UITextField!
    @IBOutlet weak var lightIntensityPercentageLabel: UILabel!
    @IBOutlet weak var lightIntensitySlider: UISlider!
    
    @IBOutlet weak var constantModeView: UIView!
    @IBOutlet weak var constantSliderRed: UISlider!
    @IBOutlet weak var constantSliderGreen: UISlider!
    @IBOutlet weak var constantSliderBlue: UISlider!
    @IBOutlet weak var constantValueRed: UILabel!
    @IBOutlet weak var constantValueGreen: UILabel!
    @IBOutlet weak var constantValueBlue: UILabel!
    @IBOutlet weak var constantResultColorView: UIView!
    @IBOutlet weak var constantHexColorField: UITextField!
    
    @IBAction func lightIntensitySliderDidChange(_ sender: Any) {
        if sender as? UISlider == lightIntensitySlider {
            ledIntensitySliderDidChangeValue(newValue: lightIntensitySlider.value)
        }
    }

    @IBAction func lightIntensitySliderDidFinishChanging(_ sender: Any) {
        ledIntensityChanged(newValue: lightIntensitySlider.value)
    }
    
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        toggleRevealView()
    }
    
    @IBAction func ledModeChanged(_ sender: UISegmentedControl) {
        let selectedMode = ThingyLEDMode(rawValue: UInt8(sender.selectedSegmentIndex))!
        ledModeChanged(to: selectedMode)
    }

    @IBAction func constantSliderDidChange(_ sender: UISlider) {
        let value = UInt8(sender.value)
        
        if sender == constantSliderRed {
            constantValueRed.text = "\(value)"
        } else if sender == constantSliderGreen {
            constantValueGreen.text = "\(value)"
        } else if sender == constantSliderBlue {
            constantValueBlue.text = "\(value)"
        }
        constantHexColorField.text = String(format: "#%02X%02X%02X", UInt8(constantSliderRed.value), UInt8(constantSliderGreen.value), UInt8(constantSliderBlue.value))
        constantResultColorView.backgroundColor = UIColor(hexString: constantHexColorField.text!)
    }

    @IBAction func constantSliderFinishChanging(_ sender: UISlider) {
        turnOnConstantLED()
    }

    //MARK: - UITapGestureRecognizer
    @objc func didTapSlider(recognizer: UITapGestureRecognizer) {
        if let tappedView = recognizer.view as? UISlider {
            if tappedView.isHighlighted {
                // System is already handling an event
                // Nothing to be done by us
                return
            }
            let location = recognizer.location(in: tappedView)
            let valueOfTap = location.x / tappedView.bounds.size.width
            let changeInValue = Float(valueOfTap) * (tappedView.maximumValue - tappedView.minimumValue)
            let targetValue = tappedView.minimumValue + changeInValue
            tappedView.setValue(targetValue, animated: true)
            if tappedView == lightIntensitySlider {
                lightIntensitySliderDidChange(tappedView)
                lightIntensitySliderDidFinishChanging(tappedView)
            } else {
                constantSliderDidChange(tappedView)
                constantSliderFinishChanging(tappedView)
            }
        }
    }

    //MARK: - UIView Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        redSliderTapRecognizer   = UITapGestureRecognizer(target: self, action: #selector(didTapSlider(recognizer:)))
        greenSliderTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSlider(recognizer:)))
        blueSliderTapRecognizer  = UITapGestureRecognizer(target: self, action: #selector(didTapSlider(recognizer:)))
        lightIntensitySliderTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapSlider(recognizer:)))
        presetColors             = createColorPresetArray()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopButtonNotifications()
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        constantResultColorView.layer.cornerRadius = constantResultColorView.frame.width / 2
        constantResultColorView.layer.borderWidth = 0.5
        constantResultColorView.layer.borderColor = UIColor(hexString: "C8C7CB").cgColor
        constantSliderRed.addGestureRecognizer(redSliderTapRecognizer)
        constantSliderGreen.addGestureRecognizer(greenSliderTapRecognizer)
        constantSliderBlue.addGestureRecognizer(blueSliderTapRecognizer)
        lightIntensitySlider.addGestureRecognizer(lightIntensitySliderTapRecognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
        colorCollectionView.selectItem(at: IndexPath(item:Int(currentSelectedColorIdx), section:0) , animated: true, scrollPosition: .top)
    }

    //MARK: - Thingy delegate
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        navigationItem.title = peripheral.name + " UI"

        if state == .disconnecting || state == .disconnected {
            setUIElementState(enabled: false)
        } else if state == .ready {
            setUIElementState(enabled: true)
            initializeLED()
            beginButtonNotifications()
        }
    }

    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        guard new != nil else {
            return
        }
        stopButtonNotifications()
    }

    //MARK: - UICollecitonViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        activeCell?.setUnchecked()
        activeCell = collectionView.cellForItem(at: indexPath) as? ColorCollectionViewCell
        activeCell!.setChecked()
        
        ledColorChanged(newColorIndex: UInt8(indexPath.item))
    }

    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presetColors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThingyColorCell", for: indexPath) as! ColorCollectionViewCell
        let selected = indexPath == colorCollectionView.indexPathsForSelectedItems?.first
        aCell.setupWithColor(aColor: presetColors[indexPath.row], andChecked: selected)
        if selected {
            activeCell = aCell
        }
        return aCell
    }

    //MARK: - Implementation
    private func setUIElementState(enabled: Bool) {
        ledModeControl.isEnabled                     = enabled
        constantSliderBlue.isEnabled                 = enabled
        constantSliderRed.isEnabled                  = enabled
        constantSliderGreen.isEnabled                = enabled
        lightIntensitySlider.isEnabled               = enabled
        breatheDelayTextField.isEnabled              = enabled
        colorCollectionView.isUserInteractionEnabled = enabled
        buttonStateLabel.isEnabled                   = enabled
        buttonStateLabel.text = "UNKNOWN"
    }

    private func initializeLED() {
        if let state = targetPeripheral?.readLEDState() {
            ledModeControl.selectedSegmentIndex = Int(state.mode.rawValue)
            if let presetColor = state.presetColor {
                currentSelectedColorIdx = presetColor.rawValue - 1
            }
            
            if let intensity = state.intensity {
                currentLightIntensity = intensity
            }
            
            if let breatheDelay = state.breatheDelay {
                currentBreatheDelay = breatheDelay
            }
            
            //Update UI
            if viewHasAppeared {
                collectionView(colorCollectionView, didSelectItemAt: IndexPath(item: Int(currentSelectedColorIdx), section:0))
            }
            lightIntensitySlider.setValue(Float(currentLightIntensity), animated: true)
            lightIntensityPercentageLabel.text = "\(currentLightIntensity)%"
            breatheDelayTextField.text = String(currentBreatheDelay)
            ledModeChanged(ledModeControl)
        } else {
            print("No LED data found")
        }
    }

    private func beginButtonNotifications() {
        buttonStateLabel.text = "UNKNOWN"
        targetPeripheral?.beginButtonStateNotifications(withCompletionHandler: { (success) -> (Void) in
            print("Button notifications enabled: \(success)")
        }, andNotificationHandler: { (aState) -> (Void) in
            switch aState {
            case .pressed:
                self.buttonStateLabel.text = "PRESSED"
            case .released:
                self.buttonStateLabel.text = "RELEASED"
            default:
                self.buttonStateLabel.text = "UNKNOWN"
            }
        })
    }

    private func stopButtonNotifications() {
        targetPeripheral?.stopButtonStateUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Button notifications disabled: \(success)")
        })
    }

    //MARK: - LED Update methods
    private func ledModeChanged(to state: ThingyLEDMode) {

        guard (state == .off && currentMode == .off) == false else {
            // There is nothing to be done. LED is already disabled
            return
        }

        currentMode = state
        
        constantSliderRed.isEnabled     = state == .constant
        constantSliderGreen.isEnabled   = state == .constant
        constantSliderBlue.isEnabled    = state == .constant
        constantHexColorField.isEnabled = false
        
        breatheDelayTextField.isEnabled = state == .breathe
        lightIntensitySlider.isEnabled  = state == .breathe || state == .oneShot
        
        switch state {
        case .breathe:
            constantModeView.isHidden = true
            colorCollectionView.isHidden = false
            turnOnBreathingLED()
        case .constant:
            constantModeView.isHidden = false
            colorCollectionView.isHidden = true
            
            turnOnConstantLED()
        case .oneShot:
            constantModeView.isHidden = true
            colorCollectionView.isHidden = false
            turnOnLEDOneShot()
        case .off:
            turnOffLED()
        }
    }

    private func turnOnBreathingLED() {
        targetPeripheral?.turnOnBreathingLED(withCompletionHandler: { (success) -> (Void) in
            print("Breathing LED on \(success), index: \(self.currentSelectedColorIdx + 1), intensity: \(self.currentLightIntensity), delay: \(self.currentBreatheDelay)")
        }, presetColor: ThingyLEDColorPreset(rawValue: currentSelectedColorIdx + 1)!, intensity: currentLightIntensity, andBreatheDelay: currentBreatheDelay)
    }
    
    private func turnOnConstantLED() {
        let color = constantResultColorView.backgroundColor!
        targetPeripheral?.turnOnConstantLED(withCompletionHandler: { (success) -> (Void) in
            print("Constant LED on \(success) with color: \(color)")
        }, andColor: color)
    }
    
    private func turnOffLED() {
        targetPeripheral?.turnOffLED(withCompletionHandler: { (success) -> (Void) in
            print("LED Turned off: \(success)")
        })
    }
    
    private func turnOnLEDOneShot() {
        targetPeripheral?.turnOnOneShotLED(withCompletionHandler: { (success) -> (Void) in
            print("LED one shot started: \(success), index: \(self.currentSelectedColorIdx + 1), intensity: \(self.currentLightIntensity)")
        }, intensity: currentLightIntensity, andPresetColor: ThingyLEDColorPreset(rawValue: currentSelectedColorIdx + 1)!)
    }

    private func ledIntensityChanged(newValue: Float) {
        ledModeChanged(to: currentMode)
    }
    
    private func ledIntensitySliderDidChangeValue(newValue: Float) {
        currentLightIntensity = UInt8(newValue)
        lightIntensityPercentageLabel.text = "\(currentLightIntensity)%"
    }

    private func ledColorChanged(newColorIndex: UInt8) {
        currentSelectedColorIdx = newColorIndex
        ledModeChanged(to: currentMode)
    }
    
    private func ledBreatheDelayChanged(newValue: UInt16) {
        currentBreatheDelay = newValue
        ledModeChanged(to: currentMode)
    }

    @objc func resignTextField() {
        breatheDelayTextField.resignFirstResponder()
        if let parsedDelay = UInt16(breatheDelayTextField.text!) {
            if parsedDelay >= 50 && parsedDelay <= 10000 {
                breatheDelayTextField.resignFirstResponder()
                ledBreatheDelayChanged(newValue: parsedDelay)
            } else {
                showBreatheDelayLimitsAlert()
            }
        } else {
            showBreatheDelayLimitsAlert()
        }
    }

    func showBreatheDelayLimitsAlert() {
        let alert = UIAlertController(title: "Invalid LED breathe delay", message: "Only values between 50 ms and 10,000 ms are accepted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let screenWidth = Int(UIScreen.main.bounds.width)
        let toolbarHeight = Int(50)
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: toolbarHeight))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(resignTextField))
        ]

        toolbar.barStyle = .default
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let digits = NSCharacterSet.decimalDigits
        for aCharacter in string.utf8 {
            let unicode = UnicodeScalar(aCharacter)
            if digits.contains(unicode) == false {
                return false
            }
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        resignTextField()
        return false
    }

    //MARK: - Convenience
    private func createColorPresetArray() -> [UIColor] {
        var tempColors = [UIColor]()
        
        //Add presets
        tempColors.append(UIColor.red)
        tempColors.append(UIColor.green)
        tempColors.append(UIColor.yellow)
        tempColors.append(UIColor.blue)
        tempColors.append(UIColor.purple)
        tempColors.append(UIColor.cyan)
        tempColors.append(UIColor.white)

        return tempColors
    }
}
