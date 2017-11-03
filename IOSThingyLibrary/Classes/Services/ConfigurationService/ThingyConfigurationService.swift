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
//  ThingyConfigurationService.swift
//
//  Created by Mostafa Berg on 10/10/16.
//
//

import CoreBluetooth

public enum ThingyConfigurationError: Error {
    case nameTooLong(currentLength: Int)
    case advertisingIntervalOutOfRange(currentInterval: Int)
    case timeoutOutOfRange(curentTimeout: Int)
    case cloudTokenTooLong(currentLength: Int)
    case eddystoneURLMalformed
    case charactersticNotDiscovered(characteristicName: String)
}

internal class ThingyConfigurationService: ThingyService {

    //MARK: - Initialization
    
    required internal init(withService aService: CBService) {
        super.init(withName: "Configuration service", andService: aService)
    }
    
    //MARK: - Configuration service implementation

    internal func readFirmwareVersion() -> String? {
        if let firmwareVersionCharacteristic = getFirmwareVersionCharacteristic() {
            let firmwareData = firmwareVersionCharacteristic.value
            if firmwareData != nil {
                let major = UInt8((firmwareData?[0])!)
                let minor = UInt8((firmwareData?[1])!)
                let patch = UInt8((firmwareData?[2])!)
                let versionString = "\(major).\(minor).\(patch)"
                return versionString
            }
            return nil
        }
        return nil
    }
    
    internal func readName() -> String {
        if let nameCharacteristic = getNameCharacteristic() {
            if let nameData = nameCharacteristic.value {
                return String(data: nameData, encoding: .utf8)!
            }
            return ""
        }
        return ""
    }

    internal func set(name aName: String) throws {
        guard aName.utf16.count <= 10 else {
            throw ThingyConfigurationError.nameTooLong(currentLength: aName.utf8.count)
        }

        if let nameCharacteristic = getNameCharacteristic() {
            let nameData = aName.data(using: .utf8)
            nameCharacteristic.writeValue(withData: nameData)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Device Name")
        }
    }

    internal func readAdvertisingParameters() -> (interval: UInt16, timeout: UInt8)? {
        if let advertisingParametersCharacteristic = getAdvertisingParametersCharacteristic() {
            let parameterdata = advertisingParametersCharacteristic.value
            if parameterdata != nil {
                var byteArray = [UInt8](parameterdata!)
                let interval: UInt16 = UInt16(byteArray[0]) | UInt16(byteArray[1]) << 8
                let timeout = byteArray[2]
                return (interval, timeout)
            }
        }
        return nil
    }
    
    internal func set(advertisingInterval anInterval: UInt16, andTimeout aTimeout: UInt8) throws {
        guard anInterval >= 12 && anInterval <= 8000 else {
            throw ThingyConfigurationError.advertisingIntervalOutOfRange(currentInterval: Int(anInterval))
        }
        
        guard aTimeout >= 0 && aTimeout <= 180 else {
            throw ThingyConfigurationError.timeoutOutOfRange(curentTimeout: Int(aTimeout))
        }

        if let advertisingParamsCharacteristic = getAdvertisingParametersCharacteristic() {
            var dataArray = [UInt8]()
            let uInt8Value0 = UInt8(anInterval >> 8)
            let uInt8Value1 = UInt8(anInterval & 0x00FF)
            dataArray.append(uInt8Value1)
            dataArray.append(uInt8Value0)
            dataArray.append(aTimeout)
            
            let data = Data(bytes: dataArray)
            advertisingParamsCharacteristic.writeValue(withData: data)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Advertising Parameters")
        }
    }

    internal func readConnectionParameters() -> (minimumInterval: UInt16, maximumInterval: UInt16, slaveLatency: UInt16, supervisionTimeout: UInt16)? {
        if let connectionParamsCharacteristic = getConnectionParametersCharacteristic() {
            let connectionParamsData = connectionParamsCharacteristic.value
            
            if connectionParamsData != nil {
                let byteArray = [UInt8](connectionParamsData!)
                let minimumInterval   : UInt16 = UInt16(byteArray[0]) | UInt16(byteArray[1]) << 8
                let maximumInterval   : UInt16 = UInt16(byteArray[2]) | UInt16(byteArray[3]) << 8
                let slaveLatency      : UInt16 = UInt16(byteArray[4]) | UInt16(byteArray[5]) << 8
                let supervisionTimeout: UInt16 = UInt16(byteArray[6]) | UInt16(byteArray[7]) << 8
                
                return(minimumInterval, maximumInterval, slaveLatency, supervisionTimeout)
            }
        }
        return nil
    }
    
    internal func set(minConnectionInterval aMinInterval: UInt16, maxConnectionInterval aMaxInterval: UInt16, slaveLatency aSlaveLatency: UInt16, andSupervisionTimeout aSupervisionTimeout: UInt16) throws {
        if let connectionParamsCharacteristic = getConnectionParametersCharacteristic() {
            var dataArray = [UInt8]()
            dataArray.append(UInt8(aMinInterval & 0x00FF))
            dataArray.append(UInt8(aMinInterval >> 8))
            dataArray.append(UInt8(aMaxInterval & 0x00FF))
            dataArray.append(UInt8(aMaxInterval >> 8))
            dataArray.append(UInt8(aSlaveLatency & 0x00FF))
            dataArray.append(UInt8(aSlaveLatency >> 8))
            dataArray.append(UInt8(aSupervisionTimeout & 0x00FF))
            dataArray.append(UInt8(aSupervisionTimeout >> 8))
            
            let data = Data(bytes: dataArray)
            connectionParamsCharacteristic.writeValue(withData: data)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Connection Parameters")
        }
    }

    internal func readCloudToken() -> String? {
        if let tokenCharacteristic = getCloudTokenCharacteristic() {
            let tokenData = tokenCharacteristic.value
            if tokenData != nil {
                let tokenString = String(data: tokenData!, encoding: .ascii)
                return tokenString
            }
        }
        return nil
    }

    internal func set(cloudToken aToken: String) throws {
        guard aToken.count <= 250 else {
            throw ThingyConfigurationError.cloudTokenTooLong(currentLength: aToken.count)
        }
        
        if let cloudTokenCharacteristic = getCloudTokenCharacteristic() {
            let tokenData = aToken.data(using: .ascii)
            cloudTokenCharacteristic.writeValue(withData: tokenData)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Cloud Token")
        }
    }
    
    internal func readEddystoneUrl() -> URL? {
        if let eddystoneCharacteristic = getEddystoneCharacteristic() {
            let eddystoneData = eddystoneCharacteristic.value
            if eddystoneData != nil {
                let eddystoneURL = URL(withEddystoneData: eddystoneData!)
                return eddystoneURL
            }
        }
        return nil
    }

    internal func disableEddystone() throws {
        if let eddystoneCharacteristic = getEddystoneCharacteristic() {
            //Tip: Writing 0 bytes will disable the Eddystone frame
            eddystoneCharacteristic.writeValue(withData: Data())
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Eddystone URL")
        }
    }

    internal func set(eddystoneUrl anEddystoneUrl: URL) throws {
        if let eddystoneCharacteristic = getEddystoneCharacteristic() {
            let eddystoneURLData = anEddystoneUrl.eddystoneEncodedData()
            
            guard eddystoneURLData != nil else{
                throw ThingyConfigurationError.eddystoneURLMalformed
            }

            eddystoneCharacteristic.writeValue(withData: eddystoneURLData)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "Eddystone URL")
        }
    }
    
    internal func readMTU() -> (peripheralRequestsMtu: Bool, mtu: UInt16)? {
        if let mtuCharacteristic = getMTUCharacteristic() {
            let data = mtuCharacteristic.value
            if let data = data {
                let requests : Bool = data[0] == 0x01
                let mtu : UInt16    = UInt16(data[0]) | UInt16(data[1]) << 8
                return (requests, mtu)
            }
        }
        return nil
    }
    
    /*
    // Thingy can set the MTU only once. iPhone sends MTU request just after connecting automatically. This method would not work on iOS.
    internal func set(mtu: UInt16, andRequestFromThingy request: Bool) throws {
        if let mtuCharacteristic = getMTUCharacteristic() {
            var dataArray = [UInt8]()
            dataArray.append(UInt8(request ? 1 : 0))
            dataArray.append(UInt8(mtu & 0x00FF))
            dataArray.append(UInt8(mtu >> 8))
            
            let data = Data(bytes: dataArray)
            mtuCharacteristic.writeValue(withData: data)
        } else {
            throw ThingyConfigurationError.charactersticNotDiscovered(characteristicName: "MTU")
        }
    }
    */

    //MARK: - Convenince methods
    
    private func getNameCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getDeviceNameCharacteristicUUID())
    }
    
    private func getAdvertisingParametersCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getAdvertisingparamtersCharacteristicUUID())
    }
    
    private func getAppearanceCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getAppearanceCharacteristicUUID())
    }
    
    private func getConnectionParametersCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getConnectionParametersCharacteristicUUID())
    }
    
    private func getEddystoneCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getEddystoneURLCharacteristicUUID())
    }
    
    private func getCloudTokenCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getCloudTokenCharacteristicUUID())
    }
    
    private func getFirmwareVersionCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getFirmwareVersionCharacteristicUUID())
    }
    
    private func getMTUCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getMTUCharacteristicUUID())
    }
}
