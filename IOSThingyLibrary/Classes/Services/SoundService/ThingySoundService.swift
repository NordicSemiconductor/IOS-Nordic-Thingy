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
//  ThingySoundService.swift
//
//  Created by Aleksander Nowakowski on 10/01/2017.
//
//

import CoreBluetooth

public enum ThingySpeakerMode: UInt8 {
    case unknown              = 0
    case frequencyAndDuration = 1
    case eightBitPCM          = 2
    case soundEffect          = 3
}

public enum ThingyMicrophoneMode: UInt8 {
    case unknown = 0
    case adpcm   = 1
    case spl     = 2
}

public enum ThingySoundEffect: UInt8 {
    case collectPoint  = 0
    case collectPoint2 = 1
    case explosion     = 2
    case explosion2    = 3
    case hit           = 4
    case pickup        = 5
    case pickup2       = 6
    case shoot         = 7
    case shoot2        = 8
}

public enum ThingySoundError: Error {
    case charactersticNotDiscovered(characteristicName: String)
    case valueNotSupported(description: String)
}

public typealias MicrophoneNotificationCallback  = (_ pcm8Data: [Int16]) -> (Void)

internal class ThingySoundService: ThingyService {
    internal var microphoneNotificationsEnabled: Bool {
        return getMicrophoneCharacteristic()?.isNotifying ?? false
    }
    internal var statusNotificationsEnabled: Bool {
        return getSpeakerStatusCharacteristic()?.isNotifying ?? false
    }
    
    //MARK: - Initialization
    
    private var speakerMode: ThingySpeakerMode?
    private var microphoneMode: ThingyMicrophoneMode?
    
    required internal init(withService aService: CBService) {
        super.init(withName: "Sound service", andService: aService)
    }
    
    //MARK: - User Interface service implementation
    
    internal func readConfiguration() -> (speakerMode: ThingySpeakerMode, microphoneMode: ThingyMicrophoneMode)? {
        if let speakerMode = speakerMode, let microphoneMode = microphoneMode {
            return (speakerMode, microphoneMode)
        }
        
        if let configCharacteristic = getConfigCharacteristic() {
            let data = configCharacteristic.value
            if data == nil || data!.count != 2 {
                return (.unknown, .unknown)
            }
            
            speakerMode = ThingySpeakerMode(rawValue: data![0]) ?? .unknown
            microphoneMode = ThingyMicrophoneMode(rawValue: data![1]) ?? .unknown
            return (speakerMode!, microphoneMode!)
        }
        return nil
    }
    
    internal func set(speakerMode: ThingySpeakerMode, microphoneMode: ThingyMicrophoneMode) throws {
        if speakerMode == .unknown || microphoneMode == .unknown {
            throw ThingySoundError.valueNotSupported(description: "Given value can not be set")
        }
        
        if let configCharacteristic = getConfigCharacteristic() {
            stopStream()
            self.speakerMode = speakerMode
            self.microphoneMode = microphoneMode
            
            var bytes = [UInt8]()
            bytes.append(speakerMode.rawValue)
            bytes.append(microphoneMode.rawValue)
            
            let data = Data(bytes: bytes)
            configCharacteristic.writeValue(withData: data)
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Sound Configuration")
        }
    }
    
    internal func beginSpeakerStatusNotifications() throws {
        if let speakerStatusCharcateristic = getSpeakerStatusCharacteristic() {
            speakerStatusCharcateristic.startNotifications()
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Speaker Status")
        }
    }
    
    internal func stopSpeakerStatusNotifications() throws {
        if let speakerStatusCharcateristic = getSpeakerStatusCharacteristic() {
            speakerStatusCharcateristic.stopNotifications()
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Speaker Status")
        }
    }
    
    internal func beginMicrophoneNotifications() throws {
        if let microphoneCharcateristic = getMicrophoneCharacteristic() {
            microphoneCharcateristic.startNotifications()
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Microphone")
        }
    }
    
    internal func stopMicrophoneNotifications() throws {
        if let microphoneCharcateristic = getMicrophoneCharacteristic() {
            microphoneCharcateristic.stopNotifications()
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Microphone")
        }
    }
    
    internal func play(soundEffect: ThingySoundEffect) throws {
        if let speakerCharacteristic = getSpeakerCharacteristic() {
            stopStream()
            // Write sample id to the Speaker characteristic
            let bytes = [soundEffect.rawValue]
            let data = Data(bytes: bytes)
            speakerCharacteristic.writeValue(withData: data, type: .withoutResponse)
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Speaker")
        }
    }
    
    internal func play(toneWithFrequency frequency: UInt16, forMilliseconds duration: UInt16, andVolume volume: UInt8) throws {
        if let speakerCharacteristic = getSpeakerCharacteristic() {
            stopStream()
            var dataArray = [UInt8]()
            dataArray.append(UInt8(frequency & 0x00FF))
            dataArray.append(UInt8(frequency >> 8))
            dataArray.append(UInt8(duration & 0x00FF))
            dataArray.append(UInt8(duration >> 8))
            dataArray.append(volume)
            let data = Data(bytes: dataArray)
            speakerCharacteristic.writeValue(withData: data, type: .withoutResponse)
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Speaker")
        }
    }
    
    internal func play(pcm: Data) throws {
        if getSpeakerCharacteristic() != nil {
            streamData = pcm
            bufferFull = false // this will call stream()
        } else {
            throw ThingySoundError.charactersticNotDiscovered(characteristicName: "Speaker")
        }
    }
    
    internal var bufferFull    : Bool = false {
        didSet {
            if streamData != nil && bufferFull == false && streamEnqueued == false {
                // Proceed with streaming
                stream()
            }
        }
    }
    
    //MARK: - Stream implementation
    
    private var streamData     : Data?
    private var streamEnqueued : Bool = false
    
    private func stream() {
        let pcm = streamData!
        let count = pcm.count
        var number = 0
        
        // Get the maximum length of the packet that can be written to Speaker characteristic
        let mtu: Int
        if #available(iOS 9.0, *) {
            // Either MTU or DLE will be used
            mtu = baseService.peripheral.maximumWriteValueLength(for: .withoutResponse)
        } else {
            // MTU and DLE are not supported
            mtu = 20
        }
        
        // Divide the stream on mtu-length packets and send some first, then schedule sending more after a delay
        for i in stride(from: 0, to: count, by: mtu) {
            // iPhone 7+ sends 3 long packets (182 Bytes, using Data Length Extension) each connection interval (which is 30ms).
            // This gives 3*182 B / 30 ms = 18.2 B/ms. Required speed for Thingy sound streaming is 8 kHz = 8 B/ms (one sample is 1B).
            // In order to send in proper speed the code below sends 4 packets each 90 ms. When DLE is used (iPhone 7, 7+) each packet is 182 bytes;
            // on the first interval 3 packets are sent, on the second 1 and the third 0. Then 3, 1, 0 again and again.
            // Synchronizing by a delay is not very reliable so status notifications (buffer full/buffer ready) are also used.
            // The speed is 4 * 182 / 90 ms = 8.09 B/s, almost 8kHz.
            if number == 4 {
                streamEnqueued = true
                streamData = pcm.subdata(in: i ..< count)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(80), execute: {
                    self.streamEnqueued = false
                    guard self.bufferFull == false && self.streamData != nil else {
                        // Streaming will be resumed when buffer is set to ready
                        return
                    }
                    self.stream()
                })
                return
            }
            let data = pcm.subdata(in: i ..< min(i + mtu, count))
            getSpeakerCharacteristic()!.writeValue(withData: data, type: .withoutResponse)
            number = number + 1
        }
        
        // The whole stream has been sent
        streamData = nil
    }
    
    private func stopStream() {
        streamData = nil
        bufferFull = false
    }
    
    //MARK: - ADPCM decoding
    
    /** Intel ADPCM step variation table */
    private static let indexTable : [Int] = [ -1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8 ]
    
    /** ADPCM step size table */
    private static let stepTable : [Int16] = [ 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28,
                                            31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143,
                                            157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544,
                                            598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878,
                                            2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358, 5894,
                                            6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818,
                                            18500, 20350, 22385, 24623, 27086, 29794, 32767 ]
    
    private var frameBuffer = Data()
    
    internal func decodeAdpcm(data: Data) -> [Int16]? {
        frameBuffer.append(data)
        
        // A ADPCM frame on Thingy ia 131 bytes long:
        // 2 bytes - predicted value
        // 1 byte  - index
        // 128 bytes - 256 4-bit samples convertable to 16-bit PCM
        if frameBuffer.count >= 131 {
            // Get the frame
            let currentFrame = frameBuffer.subdata(in: 0 ..< 131)
            // Clear the buffer
            frameBuffer.removeAll()
            
            // Read 16-bit predicted value
            var valuePredicted: Int32 = Int32(Int16(currentFrame[1]) | Int16(currentFrame[0]) << 8)
            // Read the first index
            var index = Int(currentFrame[2])
            
            var nextValue: UInt8 = 0 // value to be read from the frame
            var bufferStep = false   // should the first f second touple be read from nextValue as index delta
            var delta: UInt8 = 0     // index delta; each following frame is calculated based on the previous using an index
            var sign:  UInt8 = 0
            var step = ThingySoundService.stepTable[index]
            var output = [Int16]()
            
            for i in 0 ..< (currentFrame.count - 3) * 2 { // 3 bytes have already been eaten
                if bufferStep {
                    delta = nextValue & 0x0F
                } else {
                    nextValue = currentFrame[3 + i / 2]
                    delta = (nextValue >> 4) & 0x0F
                }
                bufferStep = !bufferStep
                
                index += ThingySoundService.indexTable[Int(delta)]
                index = min(max(index, 0), 88) // index must be <0, 88>
                
                sign  = delta & 8    // the first bit of delta is the sign
                delta = delta & 7    // the rest is a value
                
                var diff : Int32 = Int32(step >> 3)
                if (delta & 4) > 0 {
                    diff += Int32(step)
                }
                if (delta & 2) > 0 {
                    diff += Int32(step >> 1)
                }
                if (delta & 1) > 0 {
                    diff += Int32(step >> 2)
                }
                if sign > 0 {
                    valuePredicted -= diff
                } else {
                    valuePredicted += diff
                }
                
                let value: Int16 = Int16(min(Int32(Int16.max), max(Int32(Int16.min), valuePredicted)))
                
                step = ThingySoundService.stepTable[index]
                output.append(value)
            }
            return output
        }
        return nil
    }
    
    //MARK: - Convenince methods
    
    private func getConfigCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getSoundConfigurationCharacteristicUUID())
    }
    
    private func getSpeakerCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getSpeakerCharacteristicUUID())
    }
    
    private func getSpeakerStatusCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getSpeakerStatusCharacteristicUUID())
    }
    
    private func getMicrophoneCharacteristic() -> ThingyCharacteristic? {
        return getThingyCharacteristicFromList(withIdentifier: getMicrophoneCharacteristicUUID())
    }

}
