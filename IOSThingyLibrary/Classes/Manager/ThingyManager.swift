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
//  ThingyManager.swift
//
//  Created by Mostafa Berg on 05/10/16.
//
//

import CoreBluetooth

public class ThingyManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
   
    public private(set) var centralManager : CBCentralManager?
    public var delegate                    : ThingyManagerDelegate
    
    private var peripherals                : [ThingyPeripheral]
    private var peripheralDatabase         : ThingyPeripheralDatabase
    private var state                      : ThingyManagerState

    required public init(withDelegate aDelegate: ThingyManagerDelegate) {
        peripheralDatabase = ThingyPeripheralDatabase()
        delegate           = aDelegate
        peripherals        = [ThingyPeripheral]()
        state              = .unavailable
        super.init()
        //TODO: temporarily disabled restoration until it's fully supported
//        var thingyManagerOptions = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value:true),
//                                     CBCentralManagerOptionRestoreIdentifierKey : "no.nordicsemi.Thingysdk"] as [String : Any]
       
        let thingyManagerOptions = [CBCentralManagerOptionShowPowerAlertKey : NSNumber(value:true)]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: thingyManagerOptions)
        if centralManager!.state == .poweredOn {
            updateState(to: .ready)
        }
    }
    
    //MARK: Implementation

    //MARK: - Peripheral database
    public func addPeripheral(_ aPeripheral: ThingyPeripheral) {
        aPeripheral.isStored = true
        if !peripherals.contains(aPeripheral) {
            peripherals.append(aPeripheral)
        }
        if peripheralDatabase.store(peripheral: aPeripheral) {
            peripheralDatabase.synchronize()
        }
    }

    public func removePeripheral(_ aPeripheral: ThingyPeripheral) -> Bool {
        let indexToRemove = peripherals.index(of: aPeripheral)
        if indexToRemove != nil {
            if aPeripheral.state != .disconnected {
                disconnect(fromDevice: aPeripheral)
            }
            aPeripheral.isStored = false
            if aPeripheral.state == .disconnecting {
                // We must change the state to disconnected here as after removing the peripheral
                // from the peripherals list state change events will no longer be delivered
                aPeripheral.state = .disconnected
            }
            peripherals.remove(at: indexToRemove!)
            if peripheralDatabase.removePeripheral(withUuidString: aPeripheral.basePeripheral.identifier.uuidString) {
                peripheralDatabase.synchronize()
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    public func persistentPeripheralIdentifiers() -> [UUID]? {
        return peripheralDatabase.loadAll()
    }
    
    // All peripherals that are stored but are not active
    public func storedPeripherals() -> [ThingyPeripheral]? {
        return getPeripheralsWithProperties(stored: true)
    }

    public func activePeripherals() -> [ThingyPeripheral]? {
        return getPeripheralsWithProperties(stored: true, active: true)
    }
    
    public func hasStoredPeripherals() -> Bool {
        for aPeripheral in peripherals {
            if aPeripheral.isStored {
                return true
            }
        }
        return false
    }

    private func getPeripheralsWithProperties(stored: Bool, active: Bool? = nil) -> [ThingyPeripheral]? {
        var filteredPeripherals = [ThingyPeripheral]()
        for aPeripheral in peripherals {
            if active == nil {
                if aPeripheral.isStored == stored {
                    filteredPeripherals.append(aPeripheral)
                }
            } else {
                if aPeripheral.isStored == stored {
                    if active! {
                        if aPeripheral.basePeripheral.state == .connected {
                            filteredPeripherals.append(aPeripheral)
                        }
                    } else {
                        if aPeripheral.basePeripheral.state != .connected {
                            filteredPeripherals.append(aPeripheral)
                        }
                    }
                }
            }
        }
        
        if filteredPeripherals.count > 0 {
            return filteredPeripherals
        } else {
            return nil
        }
    }

    //MARK: - Discovery and connection handling
    public func discoverDevices(includingInDfuState include: Bool = false) {
        // Get all Thingy Service Identifiers
        if state == .idle {
            let thingyServices = getThingyServices(includingInDfuState: include)
            updateState(to: .scanning)
            centralManager!.scanForPeripherals(withServices: thingyServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: false)])
        }
    }
    
    public func connect(toDevice aDevice: ThingyPeripheral) {
        if peripherals.contains(aDevice) == false {
            peripherals.append(aDevice)
        }
        if aDevice.state != .connected {
            aDevice.state = .connecting
            centralManager!.connect(aDevice.basePeripheral, options: nil)
        } else {
            // This will call the delegate's method
            if aDevice.basePeripheral.services?.isEmpty ?? true {
                aDevice.state = .connected
            } else {
                aDevice.state = .ready
            }
        }
    }
    
    public func disconnect(fromDevice aDevice: ThingyPeripheral) {
        switch aDevice.state {
        case .disconnecting:
            // Do nothing. We are waiting for the callback
            break;
        case .disconnected:
            // This will call the delegate's method
            aDevice.state = .disconnected
        default:
            aDevice.state = .disconnecting
            centralManager!.cancelPeripheralConnection(aDevice.basePeripheral)
        }
    }

    private func updateState(to aState: ThingyManagerState) {
        state = aState
        delegate.thingyManager(self, didChangeStateTo: aState)
        if aState == .ready {
            let retrievedPeripherals = centralManager!.retrievePeripherals(withIdentifiers: peripheralDatabase.loadAll())
            for aPeripheral in retrievedPeripherals {
                let aThingyPeripheral = ThingyPeripheral(withPeripheral: aPeripheral, andDelegate: nil)
                aThingyPeripheral.isStored = true
                peripherals.append(aThingyPeripheral)
            }
            updateState(to: .idle)
        }
    }
    
    public func stopScan() {
        if state == .scanning {
            centralManager!.stopScan()
            updateState(to: .idle)
        }
    }

    //MARK: CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            updateState(to: .ready)
        } else {
            updateState(to: .unavailable)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // If a ThingyPeripheral is created it sets itself as a CBPeripheral delegate.
        // This way we can find out if this device has already been discovered and reuse the object.
        var aPeripheral: ThingyPeripheral
        if let thingyPeriperal = peripheral.delegate as? ThingyPeripheral {
            aPeripheral = thingyPeriperal
        } else {
            aPeripheral = ThingyPeripheral(withPeripheral: peripheral, andDelegate: nil)
        }
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            let data = Data(manufacturerData.dropFirst(2))
            let pairingCode = data.hexEncodedString()
            delegate.thingyManager(self, didDiscoverPeripheral: aPeripheral, withPairingCode: pairingCode)
        } else {
            delegate.thingyManager(self, didDiscoverPeripheral: aPeripheral, withPairingCode: nil)
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let targetPeripheral = getThingyDevice(forPeripheral: peripheral) {
            targetPeripheral.state = .connected
            print("Connected to \(targetPeripheral.name)")
            if targetPeripheral.ready == false {
                targetPeripheral.discoverServices()
            }
        } else {
            print("Did connect to unstored peripheral")
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let targetPeripheral = getThingyDevice(forPeripheral: peripheral) {
            targetPeripheral.state = .failedToConnect
        } else {
            print("Did fail to connect to unstored peripheral")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let targetPeripheral = getThingyDevice(forPeripheral: peripheral) {
            targetPeripheral.state = .disconnected
        } else {
            print("Did disconnect from unstored peripheral")
        }
    }

    private func getThingyDevice(forPeripheral aPeripheral: CBPeripheral) -> ThingyPeripheral? {
        for aStoredPeripheral in peripherals {
            if aPeripheral == aStoredPeripheral.basePeripheral {
                return aStoredPeripheral
            }
        }
        return nil
    }

    //TODO: Temporarily disabled state restoration until it's fully supported
//    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        print(dict)
//    }
}

let storedPeripheralIdentifiersKey = "storedPeripheralIdentifiers"

fileprivate class ThingyPeripheralDatabase: NSObject {
    
    private var storedPeripheralIdentifiers: [String]!
    
    public override init() {
        if storedPeripheralIdentifiers == nil {
            let storedData = UserDefaults.standard.array(forKey: storedPeripheralIdentifiersKey)
            if storedData != nil {
                storedPeripheralIdentifiers = storedData as! [String]
            } else {
                storedPeripheralIdentifiers = []
            }
        }
        super.init()
    }
    
    public func store(peripheral aPeripheral: ThingyPeripheral) -> Bool {
        let identifier = aPeripheral.basePeripheral.identifier
        if storedPeripheralIdentifiers.contains(identifier.uuidString) {
            return false // Already stored
        }
        
        storedPeripheralIdentifiers.append(identifier.uuidString)
        return true
    }
    
    public func loadAll() -> [UUID] {
        var uuidArray = [UUID]()
        for anIdentifier in storedPeripheralIdentifiers {
            uuidArray.append(UUID(uuidString: anIdentifier)!)
        }
        return uuidArray
    }
    
    public func removeAll() {
        storedPeripheralIdentifiers.removeAll()
        synchronize()
    }
    
    public func removePeripheral(withUuidString aString: String) -> Bool {
        if storedPeripheralIdentifiers.contains(aString) {
            let index = storedPeripheralIdentifiers.index(of: aString)!
            storedPeripheralIdentifiers.remove(at: index)
            return true
        } else {
            return false
        }
    }
    
    public func synchronize() {
        UserDefaults.standard.set(storedPeripheralIdentifiers, forKey: storedPeripheralIdentifiersKey)
        UserDefaults.standard.synchronize()
    }
}
