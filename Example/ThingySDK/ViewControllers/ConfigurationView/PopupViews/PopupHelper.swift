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
//  PopupHelper.swift
//
//  Created by Aleksander Nowakowski on 16/12/2016.
//

import SDCAlertView

@available(iOS 13.0, *)
class ModernViewStyle: AlertVisualStyle {
    
    override init(alertStyle: AlertControllerStyle) {
        super.init(alertStyle: .alert)

        backgroundColor = .secondarySystemBackground
        textFieldBorderColor = .red
        textFieldMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
}

class PopupHelper: NSObject {
    
    static func showTextInput(withTitle aTitle: String, subtitle aSubtitle: String? = nil, value aValue: String?, andPlaceholderValue aPlaceholderValue: String,
                              validator: ((String?) -> (Bool))? = nil, completion: ((String) -> (Void))? = nil) {
        let alert = AlertController(title: aTitle, message: aSubtitle)
        if #available(iOS 13.0, *) {
            alert.visualStyle = ModernViewStyle(alertStyle: .alert)
        }
        alert.addAction(AlertAction(title: "Cancel", style: .preferred))
        alert.addAction(AlertAction(title: "Set", style: .normal, handler: { (action) in
            let value = alert.textFields![0].text!
            completion?(value)
        }))
        //  alert.behaviors = AlertBehaviors.AutomaticallyFocusTextField
        alert.addTextField { (textField) in
            textField.placeholder = aPlaceholderValue
            if #available(iOS 13.0, *) {
                textField.backgroundColor = .tertiarySystemBackground
                textField.borderStyle = .line
            }
            textField.text = aValue
        }
        alert.shouldDismissHandler = { (action) -> (Bool) in
            let valid = action!.title == "Cancel" || (validator?(alert.textFields![0].text))!
            if valid == false {
                if aSubtitle != nil {
                    // This is a hack, let's hope it will work forever!
                    (alert.view?.subviews.first?.subviews[1].subviews[1] as? UILabel)?.textColor = UIColor.red
                } else {
                    alert.textFields![0].backgroundColor = UIColor.error
                }
            }
            return valid
        }
        alert.present()
    }
    
    static func showEddystoneUrlInput(currentUrl anUrl: URL?, completion: ((URL) -> (Void))? = nil) {
        let alert = AlertController(title: "Eddystone URL", message: nil)
        if #available(iOS 13.0, *) {
            alert.visualStyle = ModernViewStyle(alertStyle: .alert)
        }
        
        class UrlShemePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
            func numberOfComponents(in pickerView: UIPickerView) -> Int {
                return 1
            }
            
            func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
                return URL.eddystoneUrlSchemes.count
            }
            
            func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
                let textLabel = view as? UILabel ?? {
                    let label = UILabel()
                    label.font = UIFont.systemFont(ofSize: 13)
                    label.textAlignment = .center
                    return label
                }()
                textLabel.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
                return textLabel
            }
            
            func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
                return URL.eddystoneUrlSchemes[row]
            }
        }
        
        let picker = UrlShemePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = picker
        picker.dataSource = picker
        picker.selectRow(Int(anUrl?.eddystoneUrlSchemeCode ?? 0), inComponent: 0, animated: false)
        alert.contentView.addSubview(picker)
        
        // In order to make a border like in SDCAlertView fields UI of the URL field looks like this:
        // |---- fieldBorderCell --------|
        // | |-- fieldCell ------------| |
        // | | [_field_______________] | |
        // | |-------------------------| |
        // |-----------------------------|
        let fieldBorderCell = UIView()
        fieldBorderCell.translatesAutoresizingMaskIntoConstraints = false
        let fieldCell = UIView()
        fieldCell.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            fieldCell.backgroundColor = UIColor.tertiarySystemBackground
            fieldBorderCell.backgroundColor = UIColor.label
        } else {
            fieldCell.backgroundColor = UIColor.white
            fieldBorderCell.backgroundColor = UIColor.black
        }
        fieldBorderCell.addSubview(fieldCell)
        
        // Add padding 0.5 pt - this will make a thin black border
        NSLayoutConstraint(item: fieldCell, attribute: .leading, relatedBy: .equal, toItem: fieldBorderCell, attribute: .leading, multiplier: 1.0, constant: 0.5).isActive = true
        NSLayoutConstraint(item: fieldCell, attribute: .trailing, relatedBy: .equal, toItem: fieldBorderCell, attribute: .trailing, multiplier: 1.0, constant: -0.5).isActive = true
        NSLayoutConstraint(item: fieldCell, attribute: .top, relatedBy: .equal, toItem: fieldBorderCell, attribute: .top, multiplier: 1.0, constant: 0.5).isActive = true
        NSLayoutConstraint(item: fieldCell, attribute: .bottom, relatedBy: .equal, toItem: fieldBorderCell, attribute: .bottom, multiplier: 1.0, constant: -0.5).isActive = true
        
        let field = UITextField()
        field.autocorrectionType = .no
        field.addTarget(self, action: #selector(urlTextFieldDidChange(textField:)), for: .editingChanged)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "URL"
        field.keyboardType = .URL
        if #available(iOS 13.0, *) {
            field.backgroundColor = UIColor.tertiarySystemBackground
        } else {
            field.backgroundColor = UIColor.white
        }
        field.borderStyle = .none
        field.font = UIFont.systemFont(ofSize: 13.0)
        field.text = anUrl?.eddystoneUrlSufix
        fieldCell.addSubview(field)
        
        // Add padding 4 pt
        NSLayoutConstraint(item: field, attribute: .leading, relatedBy: .equal, toItem: fieldCell, attribute: .leading, multiplier: 1.0, constant: 4).isActive = true
        NSLayoutConstraint(item: field, attribute: .trailing, relatedBy: .equal, toItem: fieldCell, attribute: .trailing, multiplier: 1.0, constant: -4).isActive = true
        NSLayoutConstraint(item: field, attribute: .top, relatedBy: .equal, toItem: fieldCell, attribute: .top, multiplier: 1.0, constant: 4).isActive = true
        NSLayoutConstraint(item: field, attribute: .bottom, relatedBy: .equal, toItem: fieldCell, attribute: .bottom, multiplier: 1.0, constant: -4).isActive = true
        
        alert.contentView.addSubview(fieldBorderCell)
        
        // Picker left
        NSLayoutConstraint(item: picker, attribute: .leading, relatedBy: .equal, toItem: alert.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
        // Picker right - field left
        NSLayoutConstraint(item: picker, attribute: .trailing, relatedBy: .equal, toItem: fieldBorderCell, attribute: .leading, multiplier: 1.0, constant: -10.0).isActive = true
        // Picker top - parent top
        NSLayoutConstraint(item: picker, attribute: .top, relatedBy: .equal, toItem: alert.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
        // Picker height
        NSLayoutConstraint(item: picker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0).isActive = true
        // Picker width
        NSLayoutConstraint(item: picker, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 80.0).isActive = true
        // Picker bottom - parent bottom
        NSLayoutConstraint(item: picker, attribute: .bottom, relatedBy: .equal, toItem: alert.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
        // Field right
        NSLayoutConstraint(item: fieldBorderCell, attribute: .trailing, relatedBy: .equal, toItem: alert.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
        // Field height
        NSLayoutConstraint(item: fieldBorderCell, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 31.0).isActive = true
        // Field top - parent top
        NSLayoutConstraint(item: fieldBorderCell, attribute: .top, relatedBy: .equal, toItem: alert.contentView, attribute: .top, multiplier: 1.0, constant: 19.0).isActive = true
        
        alert.addAction(AlertAction(title: "Set", style: .normal, handler: { (action) in
            let anURL = URL(string: URL.eddystoneUrlSchemes[picker.selectedRow(inComponent: 0)] + field.text!)
            if anURL != nil {
                completion?(anURL!)
            }
        }))
        alert.addAction(AlertAction(title: "Cancel", style: .preferred))
        alert.addAction(AlertAction(title: "Disable", style: .destructive, handler: { (action) in
            completion?(URL(string:"url.disabled")!)
        }))
        alert.shouldDismissHandler = { (action) -> (Bool) in
            if action!.title == "Cancel" {
                return true
            }
            return field.text != nil && field.text!.count > 4
        }
        alert.present()
    }
    
    static func showIntervalInput(withTitle aTitle: String, subtitle aSubtitle: String? = nil, value aValue: Int, availableRange aRange: NSRange, unitInMs aUnit: Float,
                                andPlaceholderValue aPlaceholderValue: String, completion: ((Int) -> (Void))? = nil) {
        let alert = AlertController(title: aTitle, message: aSubtitle)
        if #available(iOS 13.0, *) {
            alert.visualStyle = ModernViewStyle(alertStyle: .alert)
        }
        alert.addAction(AlertAction(title: "Cancel", style: .preferred))
        alert.addAction(AlertAction(title: "Set", style: .normal, handler: { (action) in
            let value = alert.textFields![0].text!
            completion?(Int(value)!)
        }))
        
        if aUnit != 1.0 {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 12)
            label.text = "\(aValue) * \(aUnit) ms = \(Float(aValue) * aUnit) ms"
            alert.contentView.addSubview(label)
            
            NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: alert.contentView, attribute: .leading, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: label, attribute: .trailing, relatedBy: .equal, toItem: alert.contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: label, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 20.0).isActive = true
            NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: alert.contentView, attribute: .top, multiplier: 1.0, constant: 0.0).isActive = true
            NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: alert.contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0).isActive = true
            
            gloabalLabel = label
            globalUnit = aUnit
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = aPlaceholderValue
            textField.keyboardType = .numberPad
            textField.text = "\(aValue)"
            if #available(iOS 13.0, *) {
                textField.backgroundColor = .tertiarySystemBackground
                textField.borderStyle = .line
            }
            if aUnit != 1.0 {
                textField.addTarget(self, action: #selector(intervalDidChange(textField:)), for: .editingChanged)
            }
        }
        alert.shouldDismissHandler = { (action) -> (Bool) in
            if action!.title == "Cancel" {
                return true
            }
            let value = Int(alert.textFields![0].text!)
            let valid = value != nil && NSLocationInRange(value!, aRange)
            if valid == false {
                if aSubtitle != nil {
                    // This is a hack, let's hope it will work forever!
                    (alert.view?.subviews.first?.subviews[1].subviews[1] as? UILabel)?.textColor = UIColor.red
                } else {
                    alert.textFields![0].backgroundColor = UIColor.error
                }
            }
            return valid
        }
        alert.present()
    }
    
    private static weak var gloabalLabel: UILabel?
    private static var globalUnit: Float? // unit in ms
    
    @objc class func intervalDidChange(textField: UITextField) {
        if textField.text != nil && textField.text!.count > 0 {
            let aValue = Int(textField.text!)
            if let aValue = aValue {
                gloabalLabel!.text = "\(aValue) * \(globalUnit!) ms = \(Float(aValue) * globalUnit!) ms"
            } else {
                gloabalLabel!.text = ""
            }
        } else {
            gloabalLabel!.text = ""
        }
    }

    @objc class func urlTextFieldDidChange(textField: UITextField) {
        if textField.text?.contains(" ") == true {
            textField.text = textField.text?.replacingOccurrences(of: " ", with: "")
        }
    }
}
