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
//  ThingyDFUController.swift
//
//  Created by Mostafa Berg on 01/11/2016.
//
//

import iOSDFULibrary
import CoreBluetooth

enum BootloaderJumpState {
    case initial
    case connecting
    case discoveringServices
    case jumpToBootloaderCommandSent
    case jumpToBootloaderCompleted
    case jumpToBootloaderFailed
    case scanningBootloaderPeripheral
    case discoveredBootloaderPeripheral
    case startedDFUProcess
    case completedDFUProcess
    case deviceNotSupported
}

public class ThingyDFUController: NSObject, DFUProgressDelegate, DFUServiceDelegate, LoggerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, ThingyPeripheralDelegate {
    
    var bootloaderState                : BootloaderJumpState = .initial
    var targetFirmware                 : DFUFirmware!
    var targetPeripheral               : ThingyPeripheral!
    var dfuController                  : DFUServiceController!
    var centralManager                 : CBCentralManager!
    var thingyDFUDelegate              : ThingyDFUDelegate?
    var dfuInitiator                   : DFUServiceInitiator!
    var originalCentralManagerDelegate : CBCentralManagerDelegate?
    var originalPeripheralDelegate     : ThingyPeripheralDelegate?
    var dfuControlPointCharacteristic  : CBCharacteristic?

    required public init(withPeripheral aPeripheral: ThingyPeripheral, centralManager aCentralManager: CBCentralManager, firmware aFirmware: DFUFirmware, andDelegate aDelegate: ThingyDFUDelegate?) {
        super.init()
        targetFirmware    = aFirmware
        targetPeripheral  = aPeripheral
        thingyDFUDelegate = aDelegate
        centralManager    = aCentralManager
        bootloaderState   = .initial

        saveDelegates()
    }
    
    public func startDFUProcess() {
        targetPeripheral.state = .dfuInProgress
        let peripheral = targetPeripheral.basePeripheral
        
        if peripheral.state == .connected {
            // Have the DFU Service been discovered?
            if peripheral.services == nil || peripheral.services!.contains(where: { (service) -> Bool in return service.uuid == getSecureDFUServiceUUID() }) {
                discoverServices()
            } else {
                // We are connected and we have service present, let's evaluate the state
                if peripheral.services!.count > 2 {
                    //We are having all Thingy services persent, jump to bootloader
                    sendJumpToBootloaderCommand()
                } else {
                    //We're already connected and in bootloader mode since we only have the base 2 services
                    didDiscoverDFUPeripheral(aPeripheral: targetPeripheral.basePeripheral)
                }
            }
        } else {
            // Connect if we're not already connected
            connectPeripheral()
        }
    }
    
    public func abort() -> Bool {
        if dfuController == nil && bootloaderState == .connecting {
            // Device is not reachable and DFU can't start
            centralManager.cancelPeripheralConnection(targetPeripheral.basePeripheral)
            return true
        }
        return dfuController?.abort() ?? false
    }
    
    private func saveDelegates() {
        originalPeripheralDelegate = targetPeripheral.delegate
        originalCentralManagerDelegate = centralManager.delegate
    }
    
    private func restoreDelegates() {
        targetPeripheral.basePeripheral.delegate = targetPeripheral
        targetPeripheral.delegate = originalPeripheralDelegate
        centralManager.delegate = originalCentralManagerDelegate
    }

    private func connectPeripheral() {
        bootloaderState = .connecting
        targetPeripheral.basePeripheral.delegate = self
        centralManager.delegate = self
        centralManager.connect(targetPeripheral.basePeripheral, options: nil)
    }
    
    private func discoverServices() {
        bootloaderState = .discoveringServices
        targetPeripheral.basePeripheral.delegate = self
        centralManager.delegate = self
        targetPeripheral.basePeripheral.discoverServices([getSecureDFUServiceUUID()])
    }

    private func sendJumpToBootloaderCommand() {
        if dfuControlPointCharacteristic != nil {
            //We are overriding our own control point characteristic since the peripheral didn't have it's own and it's immutable, this has the same effect
            targetPeripheral.basePeripheral.setNotifyValue(true, for: dfuControlPointCharacteristic!)
            targetPeripheral.basePeripheral.writeValue(Data(bytes: [0x01]), for: dfuControlPointCharacteristic!, type: CBCharacteristicWriteType.withResponse)
            bootloaderState = .jumpToBootloaderCommandSent
        } else {
            targetPeripheral.delegate = self
            targetPeripheral.basePeripheral.delegate = targetPeripheral
            if targetPeripheral.jumpToBootloader() {
                bootloaderState = .jumpToBootloaderCommandSent
            } else {
                bootloaderState = .deviceNotSupported
                centralManager.cancelPeripheralConnection(targetPeripheral.basePeripheral)
            }
        }
    }
    
    private func scanForDFUPeripheral() {
        bootloaderState = .scanningBootloaderPeripheral
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [getSecureDFUServiceUUID()], options: nil)
    }

    private func didDiscoverDFUPeripheral(aPeripheral: CBPeripheral) {
        bootloaderState = .discoveredBootloaderPeripheral
        thingyDFUDelegate?.dfuDidJumpToBootloaderMode(newPeripheral: ThingyPeripheral(withPeripheral: aPeripheral, andDelegate: nil))
        centralManager.stopScan()
        centralManager.delegate = originalCentralManagerDelegate
        flashPeripheral(aPeripheral: aPeripheral)
    }
    
    private func flashPeripheral(aPeripheral: CBPeripheral) {
        dfuInitiator = DFUServiceInitiator(centralManager: centralManager, target: aPeripheral).with(firmware: targetFirmware)
        dfuInitiator.delegate = self
        dfuInitiator.progressDelegate = self
        dfuInitiator.logger = self
        dfuController = dfuInitiator.start()
    }

    private func didFinishFlashProcess() {
        thingyDFUDelegate?.dfuDidFinishUploading()
        didFinishDFUProcess()
    }
    
    private func didFinishDFUProcess() {
        restoreDelegates()
        targetPeripheral.state = .disconnected
        thingyDFUDelegate?.dfuDidComplete(thingy: targetPeripheral)
    }
    
    private func didStartDFUProcess() {
        bootloaderState = .startedDFUProcess
        thingyDFUDelegate?.dfuDidStart()
    }
    
    private func didStartUploadProcess() {
        thingyDFUDelegate?.dfuDidStartUploading()
    }
    
    private func didAbort() {
        restoreDelegates()
        targetPeripheral.state = .disconnected
        thingyDFUDelegate?.dfuDidAbort()
    }
    
    //MARK: - DFUProgressDelegate
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int,
                                     currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        thingyDFUDelegate?.dfuDidProgress(withCompletion: progress, forPart: part, outOf: totalParts, andAverageSpeed: avgSpeedBytesPerSecond)
    }

    //MARK: - DFUServiceDelegate
    public func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .completed:
            didFinishFlashProcess()
        case .uploading:
            didStartUploadProcess()
        case .starting:
            didStartDFUProcess()
        case .aborted:
            didAbort()
        default:
            break
        }
    }
    
    public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        restoreDelegates()
        targetPeripheral.state = .disconnected
        let anError = NSError(domain: "com.nordicsemi.dfu", code: error.rawValue, userInfo: nil)
        thingyDFUDelegate?.dfuDidFail(withError: anError, andMessage: message)
    }

    //MARK: - LoggerDelegate
    public func logWith(_ level:LogLevel, message:String) {
        // print("\(level.name()): \(message)")
    }

    //MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager state = \(central.state)")
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if bootloaderState == .connecting {
            if peripheral.services == nil || peripheral.services!.count == 0 {
                bootloaderState = .discoveringServices
                peripheral.discoverServices([getSecureDFUServiceUUID()])
            } else {
                if peripheral.services!.count > 2 {
                    //We are in application mode, we can now send a jump to bootloader
                    sendJumpToBootloaderCommand()
                    targetPeripheral.basePeripheral.delegate = targetPeripheral
                }
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if bootloaderState == .deviceNotSupported {
            // The DFU characteristics were not found or jump to bootloader failed
            dfuError(.deviceNotSupported, didOccurWithMessage: "No characteristics found in DFU Service")
            return
        }
        if bootloaderState == .connecting {
            // Device is not reachable and DFU coundn't start
            dfuError(.failedToConnect, didOccurWithMessage: "Device not available")
            return
        }
        
        //When were connected to a peripheral in application mode
        //We manually jump to bootloader, so we handle the disconnection manually here
        //Instead of using the ThingyPeripheral
        if bootloaderState == .jumpToBootloaderCommandSent {
            dfuControlPointCharacteristic = nil
            bootloaderState = .jumpToBootloaderCompleted
            scanForDFUPeripheral()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Thingy")")
        // TODO: and?
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if bootloaderState == .scanningBootloaderPeripheral {
            if peripheral.name?.lowercased() == "thingydfu" {
                didDiscoverDFUPeripheral(aPeripheral: peripheral)
            }
        }
    }

    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for aService in peripheral.services! {
            if aService.uuid == getSecureDFUServiceUUID() {
                peripheral.discoverCharacteristics(nil, for: aService)
            }
            //Ignore other services
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.characteristics != nil else {
            bootloaderState = .initial
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        
        switch service.characteristics!.count {
        case 1:
            //We have an application mode, jump to bootloader
            for aCharacterstic in service.characteristics! {
                if aCharacterstic.uuid == getJumpToBootloaderCharacteristicUUID() {
                    dfuControlPointCharacteristic = aCharacterstic
                } else if aCharacterstic.uuid == getNewJumpToBootloaderCharacteristicUUID() {
                    dfuControlPointCharacteristic = aCharacterstic
                }
                sendJumpToBootloaderCommand()
            }
        case 2:
            //We are in bootloader start DFU process
            //First attempt: Start with merged SD/BL/APP bundled firmware
            //If we get an error, try only ApplicationFirmware
            didDiscoverDFUPeripheral(aPeripheral: peripheral)
        default:
            print("Unknown state")
        }
    }
    
    //MARK: - ThingyPeripheralDelegate
    public func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        if state == .disconnected && bootloaderState == .jumpToBootloaderCommandSent {
            bootloaderState = .jumpToBootloaderCompleted
            centralManager.delegate = self
            scanForDFUPeripheral()
        }
    }
}
