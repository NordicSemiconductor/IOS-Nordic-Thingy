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
//  DFUViewController.swift
//
//  Created by Mostafa Berg on 01/11/2016.
//

import UIKit
import IOSThingyLibrary
import iOSDFULibrary
import CoreBluetooth

class DFUViewController: SwipableTableViewController, ThingyDFUDelegate, NewThingyDelegate, FileSelectionDelegate {
    /// This firmware should be obtained from the Internet in the final app
    private var originalFirmware : DFUFirmware?
    private var selectedFirmware : DFUFirmware?
    private var selectedFileURL  : URL?
    private var dfuController    : ThingyDFUController!
    /// Workaround: This ensures the app will retry in case user attemps to flash the same softdevice again
    /// This is only required for merged zip files that contain sd/bl + app, in all other cases, app only is
    /// updated unless we are doing a DFU update with an app that requires a newer sd/bl version.
    private var isAttemptingSDCheck: Bool = false

    /// Flag set to true when the target row has been tapped. In that case the target name will not be cleard.
    private var changingTarget   : Bool = false
    
    @IBOutlet weak var startButton: UIBarButtonItem!
    @IBAction func startButtonTapped(_ sender: UIBarButtonItem) {
        startDFUProcess()
    }
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        toggleRevealView()
    }
    @IBAction func abortButtonTapped(_ sender: UIButton) {
        _ = dfuController.abort()
    }
    @IBAction func firmwareTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            performSegue(withIdentifier: "selectFile", sender: self)
        default:
            selectedFileURL = nil
            selectedFirmware = originalFirmware
            startButton.isEnabled = targetPeripheral != nil
            updateFirmwareInformation(from: selectedFirmware!)
            break
        }
    }
    @IBAction func errorHelpButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Info: Invalid object", message: "Firmware validation has failed. Most probably the firmware you are trying to send was signed with an invalid signature or the device parameters differ from what was set in the init packet. To flash your own firmware compile the bootloader using your own set of keys and flash it using USB.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alert.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
    
    //Firmware info section outlets
    @IBOutlet weak var firmwareFilename: UILabel!
    @IBOutlet weak var firmwareType: UILabel!
    @IBOutlet weak var firmwareSize: UILabel!
    @IBOutlet weak var firmwareVersion: UILabel!
    @IBOutlet weak var deviceName: UILabel!

    //DFU Status section outlets
    @IBOutlet weak var firmwareTypeControl: UISegmentedControl!
    @IBOutlet weak var targetCell: UITableViewCell!
    @IBOutlet weak var abortButton: UIButton!
    @IBOutlet weak var dfuActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var bootloaderStepIcon: UIImageView!
    @IBOutlet weak var bootloaderStepLabel: UILabel!
    @IBOutlet weak var scanBootloaderIcon: UIImageView!
    @IBOutlet weak var scanBootloaderLabel: UILabel!
    @IBOutlet weak var uploadingFirmwareIcon: UIImageView!
    @IBOutlet weak var uploadingFirmwareLabel: UILabel!
    @IBOutlet weak var completedIcon: UIImageView!
    @IBOutlet weak var completedLabel: UILabel!
    @IBOutlet weak var errorIcon: UIImageView!
    @IBOutlet weak var errorHelpButton: UIButton!
    
    //MARK: - UIViewController lifecycle
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadOriginalFirmware(withSoftDeviceBootloader: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset the flag
        changingTarget = false
        
        // Restore Thingy tab when custom file has not been selected (user tapped Cancel)
        if selectedFileURL == nil && firmwareTypeControl.selectedSegmentIndex == 0 {
            firmwareTypeControl.selectedSegmentIndex = 1
        } else if selectedFileURL != nil { // Set Custom if file was opened from e-mail
            firmwareTypeControl.selectedSegmentIndex = 0
        }
        // If the device and firmware is set, we can enable Start button
        startButton.isEnabled = targetPeripheral != nil && selectedFirmware != nil
        updateFirmwareInformation(from: selectedFirmware)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPeripheralSelector" {
            changingTarget = true
            let navigationController = segue.destination as! ThingyCreatorNavigationController
            navigationController.newThingyDelegate = self
            navigationController.setTargetPeripheral(targetPeripheral, andManager: thingyManager)
        } else if segue.identifier == "selectFile" {
            let aNavigationController = segue.destination as? UINavigationController
            let barViewController = aNavigationController?.topViewController as? UITabBarController
            let userFilesVC = barViewController?.viewControllers?.first as? UserFilesViewController
            userFilesVC?.fileDelegate = self
            
            if selectedFileURL != nil {
                userFilesVC?.selectedPath = selectedFileURL
            }
        }
    }
    
    //MARK: - Base class methods
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        if state == .ready {
            deviceName.text = peripheral.name
            startButton.isEnabled = selectedFirmware != nil
        }
    }
    
    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        // Don't change the name when 'Select new target' view is being open
        if changingTarget == false {
            if new == nil {
                startButton.isEnabled = false
                deviceName.text = "Not set"
            } else {
                // The device switched to DFU mode, update it's name
                deviceName.text = new!.name
            }
        }
    }
    
    override func targetPeripheralDidChange(new: ThingyPeripheral?) {
        if let targetPeripheral = new {
            deviceName.text = targetPeripheral.name
            if let fwVersion = targetPeripheral.readFirmwareVersion() {
                if fwVersion == "1.1.0" || fwVersion == "1.0.0" {
                    loadOriginalFirmware(withSoftDeviceBootloader: true)
                } else {
                    loadOriginalFirmware(withSoftDeviceBootloader: false)
                }
            }
            startButton.isEnabled = selectedFirmware != nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if firmwareTypeControl.selectedSegmentIndex == 0 && firmwareFilename.text == "Invalid file" {
            performSegue(withIdentifier: "selectFile", sender: self)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        // Changing the target is not possible when DFU is in progress
        return dfuActivityIndicator.isHidden
    }
    
    //MARK: - Implementation
    private func loadOriginalFirmware(withSoftDeviceBootloader: Bool) {
        if withSoftDeviceBootloader {
            originalFirmware = DFUFirmware(urlToZipFile: getExampleMergedFirmwareURL())
        } else {
            originalFirmware = DFUFirmware(urlToZipFile: getExampleFirmwareURL())
        }
        selectedFirmware = originalFirmware
    }
    
    private func getExampleMergedFirmwareURL() -> URL {
        return Bundle.main.url(forResource: "thingy_dfu_sd_bl_app_v\(kCurrentDfuVersion).HW_1.0", withExtension: "zip")!
    }

    private func getExampleFirmwareURL() -> URL {
        return Bundle.main.url(forResource: "thingy_dfu_pkg_app_v\(kCurrentDfuVersion).HW_1.0", withExtension: "zip")!
    }
    
    private func updateFirmwareInformation(from aFirmware: DFUFirmware?) {
        guard let aFirmware = aFirmware else {
            firmwareFilename.text = "Invalid file"
            firmwareType.text = "N/A"
            firmwareSize.text = "N/A"
            firmwareVersion.text = "N/A"
            firmwareType.alpha = 0.2
            firmwareSize.alpha = 0.2
            firmwareVersion.alpha = 0.2
            return
        }
        let appSize = aFirmware.size.application
        let sdSize = aFirmware.size.softdevice
        let blSize = aFirmware.size.bootloader
        var totalSize: Float = 0
        
        var type = ""
        if sdSize > 0 {
            type.append("SoftDevice")
            totalSize += Float(sdSize)
        }
        if blSize > 0 {
            if !type.isEmpty {
                type.append(", ")
            }
            type.append("Bootloader")
            totalSize += Float(blSize)
        }
        if appSize > 0 {
            if !type.isEmpty {
                type.append(", ")
            }
            type.append("Application")
            totalSize += Float(appSize)
        }
        
        firmwareType.text = type
        firmwareSize.text = String(format: "%.3f kB", (totalSize / 1024.0))
        firmwareFilename.text = aFirmware.fileName!
        firmwareType.alpha = 1
        firmwareSize.alpha = 1
        
        if aFirmware == originalFirmware {
            firmwareVersion.text = kCurrentDfuVersion
            firmwareVersion.alpha = 1
        } else {
            firmwareVersion.text = "N/A"
            firmwareVersion.alpha = 0.2
        }
    }
    
    //MARK: - FileSelectionDelegate
    func onFileSelected(withURL aFileURL: URL) {
        selectedFileURL = aFileURL
        selectedFirmware = DFUFirmware(urlToZipFile: aFileURL)
        
        // This method may be called before the view has been created (when file opened from an e-mail)
        if isViewLoaded {
            // If the device and firmware is set, we can enable Start button
            startButton.isEnabled = targetPeripheral != nil && selectedFirmware != nil
            firmwareTypeControl.selectedSegmentIndex = 0
            updateFirmwareInformation(from: selectedFirmware)
        }
    }
    
    //MARK: - ThingyDFUDelegate
    private func startDFUProcess() {
        guard targetPeripheral != nil else {
            print("DFU Target not set")
            return
        }
        dfuActivityIndicator.isHidden = false
        startButton.isEnabled         = false
        abortButton.isHidden          = false
        firmwareTypeControl.isEnabled = false
        targetCell.accessoryType      = .none
        errorHelpButton.isHidden      = true
        bootloaderStepIcon.alpha      = 0.2
        bootloaderStepLabel.alpha     = 1.0 // Show it initially
        scanBootloaderIcon.alpha      = 0.2
        scanBootloaderLabel.alpha     = 0.2
        uploadingFirmwareIcon.alpha   = 0.2
        uploadingFirmwareLabel.alpha  = 0.2
        speedLabel.alpha              = 0.2
        speedLabel.text               = "0 KB/s"
        progressIndicator.alpha       = 0.2
        completedIcon.alpha           = 0.2
        errorIcon.alpha               = 0.0 // Not visible
        completedLabel.alpha          = 0.2
        completedLabel.text           = "Completed"
        
        if targetPeripheral!.name.lowercased() == "thingydfu" {
            if selectedFirmware == originalFirmware {
                if isAttemptingSDCheck == false {
                    isAttemptingSDCheck = true
                    self.loadOriginalFirmware(withSoftDeviceBootloader: true)
                } else {
                    self.loadOriginalFirmware(withSoftDeviceBootloader: false)
                }
            }
        }
        let centralManager = thingyManager!.centralManager!
        dfuController = ThingyDFUController(withPeripheral: targetPeripheral!, centralManager: centralManager, firmware: selectedFirmware!, andDelegate: self)
        dfuController.startDFUProcess()
    }
    
    func dfuDidJumpToBootloaderMode(newPeripheral: ThingyPeripheral) {
        targetPeripheral = newPeripheral
        changeAlpha(of: bootloaderStepIcon, to: 1)
        changeAlpha(of: scanBootloaderLabel, to: 1)
    }
    
    func dfuDidStart() {
        changeAlpha(of: scanBootloaderIcon, to: 1)
    }

    func dfuDidComplete(thingy: ThingyPeripheral?) {
        isAttemptingSDCheck = false
        dfuActivityIndicator.isHidden = true
        startButton.isEnabled = true
        abortButton.isHidden = true
        firmwareTypeControl.isEnabled = true
        targetCell.accessoryType      = .disclosureIndicator
        progressIndicator.setProgress(0, animated: true)
        changeAlpha(of: completedLabel, to: 1)
        changeAlpha(of: completedIcon, to: 1)
        if thingy != nil {
            targetPeripheral = thingy
            thingyManager!.connect(toDevice: thingy!)
        }
        
        UIView.animate(withDuration: 0.3, delay: 1, options: [], animations: {
            self.bootloaderStepIcon.alpha      = 0.2
            self.bootloaderStepLabel.alpha     = 0.2
            self.scanBootloaderIcon.alpha      = 0.2
            self.scanBootloaderLabel.alpha     = 0.2
            self.uploadingFirmwareIcon.alpha   = 0.2
            self.uploadingFirmwareLabel.alpha  = 0.2
            self.speedLabel.alpha              = 0.2
            self.progressIndicator.alpha       = 0.2
            self.completedIcon.alpha           = 0.2
            self.errorIcon.alpha               = 0.0
            self.completedLabel.alpha          = 0.2
        }) { (completed) in
            self.speedLabel.text               = "0 KB/s"
            self.completedLabel.text           = "Completed"
        }
    }
    
    func dfuDidFail(withError anError: Error, andMessage aMessage: String) {
        dfuActivityIndicator.isHidden = true
        startButton.isEnabled = true
        abortButton.isHidden = true
        firmwareTypeControl.isEnabled = true
        targetCell.accessoryType      = .disclosureIndicator
        completedLabel.text = "Error: \(aMessage)"
        changeAlpha(of: completedIcon, to: 0)
        changeAlpha(of: errorIcon, to: 1)
        changeAlpha(of: completedLabel, to: 1)
        
        // The DFU from SDK 12 returns Invalid Object error when the signature does not match.
        // This means that the bootloader is either locked (requires fw signed by Nordic) or an invalid signature was
        // used to sign the new firmware. Let's show this info to the user. Until the NonSecure DFU is released the
        // only way to unlock the bootloader is by flashing user's own secure DFU bootloader with user's own public key
        // using USB. Unlocking the bootloader Over-The-Air is not supported yet.
        // TODO: This comment needs to be updated when NonSecure DFU or other way to unlock the Bootloader is implemented for Thingy.
        let error = anError as NSError
        if error.code == DFUError.remoteSecureDFUInvalidObject.rawValue {
            errorHelpButton.isHidden = false
        }

        if error.code == DFUError.remoteSecureDFUExtendedError.rawValue {
            if isAttemptingSDCheck == true {
                errorHelpButton.isHidden = true
                self.startDFUProcess()
                return
            } else {
                errorHelpButton.isHidden = false
            }
        }
    }
    
    func dfuDidAbort() {
        dfuActivityIndicator.isHidden = true
        startButton.isEnabled = true
        abortButton.isHidden = true
        firmwareTypeControl.isEnabled = true
        targetCell.accessoryType      = .disclosureIndicator
        completedLabel.text = "Upload aborted"
        changeAlpha(of: completedIcon, to: 0)
        changeAlpha(of: errorIcon, to: 1)
        changeAlpha(of: completedLabel, to: 1)
        isAttemptingSDCheck = false
    }

    func dfuDidStartUploading() {
        changeAlpha(of: progressIndicator, to: 1)
        changeAlpha(of: uploadingFirmwareLabel, to: 1)
        changeAlpha(of: speedLabel, to: 1)
    }

    func dfuDidProgress(withCompletion aCompletion: Int, forPart aPart: Int, outOf totalParts: Int, andAverageSpeed aSpeed: Double) {
        if totalParts > 1 {
            uploadingFirmwareLabel.text = "Uploading Firmware (\(aPart)/\(totalParts))"
        } else {
            uploadingFirmwareLabel.text = "Uploading firmware"
        }
        speedLabel.text = String(format: "%0.1f KB/s", aSpeed / 1024.0)
        progressIndicator.setProgress(Float(aCompletion) / 100.0, animated: true)
        uploadingFirmwareIcon.alpha = 0.2 + 0.8 * CGFloat(aCompletion) / 100.0
    }
    
    func dfuDidFinishUploading() {
        changeAlpha(of: uploadingFirmwareIcon, to: 1)
        changeAlpha(of: completedLabel, to: 1)
    }
    
    //MARK: - Helper methods
    private func changeAlpha(of view: UIView, to alpha: CGFloat, animate: Bool = true) {
        if animate {
            if view.alpha != alpha {
                UIView.animate(withDuration: 0.3) {
                    view.alpha = alpha
                }
            }
        } else {
            view.alpha = alpha
        }
    }
}
