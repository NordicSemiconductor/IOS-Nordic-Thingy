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
//  SoundViewController.swift
//
//  Created by Aleksander Nowakowski on 10/01/2017.
//

import UIKit
import IOSThingyLibrary
import AVFoundation
import Charts

class SoundViewController: SwipableTableViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var microphoneBackground: UIView!
    @IBOutlet weak var microphonePulse: UIView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var thingyButton: UIButton!
    @IBOutlet weak var thingyPulse: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeControl: UISlider!
    @IBOutlet weak var soundGraph: LineChartView!
    
    //MARK: - Actions
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        toggleRevealView()
    }
    
    @IBAction func pianoButtonDown(_ sender: UIButton) {
        if isRecordingPiano {
            let now = CFAbsoluteTimeGetCurrent()
            let delay = lastToneRecordTime == nil ? 0 : (now - lastToneRecordTime!)
            lastToneRecordTime = now
            records.append((frequency: UInt16(sender.tag), delay: Int(delay * 1000))) // convert to milliseconds
        }
        play(toneWithFrequency: UInt16(sender.tag), forMilliseconds: 300)
    }
    
    @IBAction func pianoButtonCancel(_ sender: UIButton) {
        //play(toneWithFrequency: UInt16(sender.tag), forMilliseconds: 0)
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        isRecordingPiano = !isRecordingPiano
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        isPlayingPiano = !isPlayingPiano
    }
    
    @IBAction func microphoneButtonTapped(_ sender: UIButton) {
        if isReceivingMicrophone == false {
            toggleStreamingMicrophone()
        }
    }
    
    @IBAction func thingyButtonTapped(_ sender: UIButton) {
        if isStreamingMicrophone == false {
            toggleReceivingMicrophone()
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: UIBarButtonItem) {
        showInfo()
    }
    
    //MARK: - Properties and data
    private var recordingSession            : AVAudioSession!
    private var engine                      : AVAudioEngine?
    private var player                      : AVAudioPlayerNode?
    private var isStreamingMicrophone       : Bool = false
    private var isReceivingMicrophone       : Bool = false
    private var soundGraphHandler           : SoundGraphDataHandler!
    private var volumeSliderTapRecognizer   : UITapGestureRecognizer!
    private var isPlayingPiano = false {
        didSet {
            if isPlayingPiano {
                playButton.setTitle("Stop", for: .normal)
                recordButton.isEnabled = false
                playToneWithIndex(0)
            } else {
                playButton.setTitle("Play", for: .normal)
                recordButton.isEnabled = true
            }
        }
    }
    private var isRecordingPiano = false {
        didSet {
            if isRecordingPiano {
                recordButton.setTitle("Stop", for: .normal)
                // When there was a recording already, hide the play button and clear it
                if records.isEmpty == false {
                    UIView.animate(withDuration: 0.3) {
                        self.playButton.alpha = 0
                    }
                    records.removeAll()
                    lastToneRecordTime = nil
                }
            } else {
                recordButton.setTitle("Record", for: .normal)
                // If something has been recorded, show the Play button
                if records.isEmpty == false {
                    UIView.animate(withDuration: 0.3) {
                        self.playButton.alpha = 1
                    }
                }
            }
        }
    }
    private var records: [(frequency: UInt16, delay: Int)] = []
    private var lastToneRecordTime: CFAbsoluteTime?
    
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
        }
    }
    //MARK: - UI View Conrtroller
    override func viewDidLoad() {
        microphoneBackground.layer.cornerRadius = microphoneBackground.bounds.size.width / 2
        microphonePulse.layer.cornerRadius = microphonePulse.bounds.size.width / 2
        thingyPulse.layer.cornerRadius = thingyPulse.bounds.size.width / 2
        soundGraphHandler = SoundGraphDataHandler(withGraphView: soundGraph,
                                                  andMaxVisibleEntries: 50) // The greater value the more UI is lagging
        volumeSliderTapRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(didTapSlider(recognizer:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        volumeControl.addGestureRecognizer(volumeSliderTapRecognizer)
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setPreferredSampleRate(8000) // 8 kHz
            try recordingSession.setPreferredOutputNumberOfChannels(1)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to start Record session")
        }
        
        // As the sound quality is perfect only on iPhone 7 and iPhone 7 Plus
        // (or newer devices) let's show a message to the user explaining it.
        // It will only be shown once unless user clicks the (i) icon.
        let key = "SoundInfoShown"
        let infoShown = UserDefaults.standard.bool(forKey: key)
        if infoShown == false {
            showInfo()
            
            // Save that the info was read
            UserDefaults.standard.set(true, forKey: key)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        try? recordingSession.setActive(false)
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Info
    private func showInfo() {
        let message = "The streaming quality depends on your iDevice capabilities and connection parameters. A throughput of at least 8 Kbps is required to stream without lagging and only iPhone 7 or newer devices are able to provide it. When using an older device you will hear interruptions as some packets will have to be skipped.\n\nStreaming formats:\nUP: 8-bit PCM with sample rate 8 KHz,\nDOWN: ADPCM format, decoded to 16-bit PCM with sample rate 8 KHz\nOther options:\n- Frequency, volume and duration\n-sample sounds"
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
            alert.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    //MARK: - Sound control
    private func toggleStreamingMicrophone() {
        if isStreamingMicrophone == false {
            startStreamingMicrophone()
        } else {
            stopStreamingMicrophone()
        }
    }
    
    private func startStreamingMicrophone() {
        if isStreamingMicrophone == false && targetPeripheral != nil {
            recordingSession.requestRecordPermission { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Permission granted")
                        print("Starting recording...")
                        if self.startRecording() {
                            self.isStreamingMicrophone = true
                            self.startSendingAnimation()
                        } else {
                            print("Recording failed. Required format not supported")
                            // Show alert to the user
                            let alert = UIAlertController(title: "Not supported", message: "Required audio format is not supported on this iOS version. Please update your iDevice.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                                alert.dismiss(animated: true)
                            }))
                            self.present(alert, animated: true)
                        }
                    } else {
                        print("Permission denied")
                    }
                }
            }
        }
    }
    
    private func stopStreamingMicrophone() {
        if isStreamingMicrophone {
            isStreamingMicrophone = false
            print("Recording stopped")
            stopRecording()
            stopSendingAnimation()
        }
    }
    
    private func toggleReceivingMicrophone() {
        if isReceivingMicrophone == false {
            startReceivingMicrophone()
        } else {
            stopReceivingMicrophone()
        }
    }
    
    private func startReceivingMicrophone() {
        if isReceivingMicrophone == false {
            targetPeripheral?.beginMicrophoneUpdates(withCompletionHandler: { success in
                if success {
                    print("Microphone updates enabled")
                    self.isReceivingMicrophone = true
                    print("Starting playing...")
                    self.startReceivingAnimation()
                    self.startPlaying()
                } else {
                    print("Microphone updates failed to start")
                }
            }, andNotificationHandler: { (pcm16Data) -> (Void) in
                self.schedule(pcm16Data: pcm16Data)
            })
        }
    }
    
    private func stopReceivingMicrophone() {
        if isReceivingMicrophone {
            targetPeripheral?.stopMicrophoneUpdates(withCompletionHandler: { success in
                if success {
                    print("Microphone updates stopped")
                } else {
                    print("Microphone updates failed to stop")
                }
            })
            isReceivingMicrophone = false
            print("Playing stopped")
            stopPlaying()
            stopReceivingAnimation()
        }
    }
    
    //MARK: - UI Animations
    private func startSendingAnimation() {
        microphoneButton.isSelected = true
        microphoneBackground.backgroundColor = UIColor.red
        UIView.animate(withDuration: 1.0, delay: 1.0, options: [.repeat], animations: {
            self.microphonePulse.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
            self.microphonePulse.alpha = 0.1
        })
    }
    
    private func stopSendingAnimation() {
        microphoneButton.isSelected = false
        microphoneBackground.backgroundColor = UIColor.black
        microphonePulse.layer.removeAllAnimations()
        microphonePulse.transform = CGAffineTransform.identity
        microphonePulse.alpha = 0.3
        soundGraphHandler.clearGraphData()
    }
    
    private func startReceivingAnimation() {
        thingyButton.isSelected = true
        UIView.animate(withDuration: 1.0, delay: 1.0, options: [.repeat], animations: {
            self.thingyPulse.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
            self.thingyPulse.alpha = 0.1
        })
    }
    
    private func stopReceivingAnimation() {
        thingyButton.isSelected = false
        thingyPulse.layer.removeAllAnimations()
        thingyPulse.transform = CGAffineTransform.identity
        thingyPulse.alpha = 0.3
        soundGraphHandler.clearGraphData()
    }
    
    //MARK: - Thingy API
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        print("Sound thingy state: \(state), view loaded: \(isViewLoaded)") // TODO: remove
        
        navigationItem.title = "Sound"
        
        recordButton.isEnabled = state == .ready
        playButton.isEnabled = state == .ready
        if state == .ready {
            peripheral.beginButtonStateNotifications(withCompletionHandler: { success in
                if success {
                    print("Button state notifications enabled")
                } else {
                    print("Button state notifications failed to start")
                }
            }, andNotificationHandler: { (buttonState: ThingyButtonState) in
                // When Thingy button is clicked (pressed and released) toggle the Thingy microphone
                if buttonState == .released {
                    // Ignore when phone is streaming its microphone
                    if self.isStreamingMicrophone == false {
                        self.toggleReceivingMicrophone()
                    }
                }
            })
        } else if state == .disconnected || state == .disconnecting {
            stopStreamingMicrophone()
            stopReceivingMicrophone()
        }
    }
    
    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        recordButton.isEnabled = new != nil
        playButton.isEnabled = new != nil
        stopStreamingMicrophone()
        stopReceivingMicrophone()
        targetPeripheral?.stopSpeakerStatusNotifications(withCompletionHandler: nil)
        targetPeripheral?.stopButtonStateUpdates(withCompletionHandler: { success in
            if success {
                print("Button state notifications disabled")
            } else {
                print("Button state notifications failed to stop")
            }
        })
    }
    
    //MARK: - Table View Controller Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1: // 8-bit PCM
            do {
                switch indexPath.row {
                case 0: // Evil laugh
                    let url = Bundle.main.url(forResource: "evil_laugh_8kHz", withExtension: "wav")!
                    let data = try Data(contentsOf: url)
                    targetPeripheral?.play(pcm16bit: data.subdata(in: 44 ..< data.count - 44)) // skip header
                    break
                case 1: // Grapevine
                    let url = Bundle.main.url(forResource: "grapevine_8kHz", withExtension: "wav")!
                    let data = try Data(contentsOf: url)
                    targetPeripheral?.play(pcm16bit: data.subdata(in: 44 ..< data.count - 44)) // skip header
                    break
                case 2: // Ukulele
                    let url = Bundle.main.url(forResource: "ukulele_8kHz", withExtension: "wav")!
                    let data = try Data(contentsOf: url)
                    targetPeripheral?.play(pcm16bit: data.subdata(in: 44 ..< data.count - 44)) // skip header
                    break
                case 3: // Learning computer
                    let url = Bundle.main.url(forResource: "learning_computer_8kHz", withExtension: "wav")!
                    let data = try Data(contentsOf: url)
                    targetPeripheral?.play(pcm16bit: data.subdata(in: 44 ..< data.count - 44)) // skip header
                    break
                default:
                    break
                }
            } catch {
                print("Can't play sound")
            }
        case 2: // Sound effects
            targetPeripheral?.play(soundEffect: ThingySoundEffect(rawValue: UInt8(indexPath.row))!)
        default:
            break
        }
    }

    private func play(toneWithFrequency frequency: UInt16, forMilliseconds duration: UInt16) {
        let volume = UInt8(volumeControl.value)
        targetPeripheral?.play(toneWithFrequency: frequency, forMilliseconds: duration, andVolume: volume)
    }
    
    private func playToneWithIndex(_ index: Int) {
        guard isPlayingPiano else {
            return
        }
        
        let tone = records[index]
        play(toneWithFrequency: tone.frequency, forMilliseconds: 300)
        
        if index + 1 < records.count {
            let nextTone = records[index + 1]
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(nextTone.delay), execute: { self.playToneWithIndex(index + 1) })
        } else {
            isPlayingPiano = false
        }
    }
    
    //MARK: - AV Audio methods
    /// This method starts capturing microphone data and sends them to the Thingy.
    private func startRecording() -> Bool {
        // The sound will be sent using 8-bit PCM, 8000 Hz. Capturing audio with this format is not possible (16-bit PCM 
        // is the lowest available) so conversino will be done later.
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 8000, channels: 1, interleaved: true)
        
        engine = AVAudioEngine()
        let inputNode = engine!.inputNode
        if inputNode.outputFormat(forBus: 0).sampleRate == 0 {
            // On iOS 8 the 8 KHz sampling is not supported
            return false
        }
        let mixer = AVAudioMixerNode()
        engine!.attach(mixer)
        engine!.connect(inputNode, to: mixer, format: inputNode.outputFormat(forBus: 0))
        engine!.connect(mixer, to: engine!.mainMixerNode, format: format)
        engine!.mainMixerNode.volume = 0
        
        // Install a tap to get bytes while they are recorded. Buffer size 800 is the lowest possible and covers 1/10 second.
        mixer.installTap(onBus: 0, bufferSize: 800, format: mixer.outputFormat(forBus: 0)) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            let rawData = buffer.int16ChannelData![0]
            
            var graphData = [Double]()
            // Unfortunatelly we can't show all samples on the graph, it would be too slow.
            // We show only every n-th sample from whole 800 samples in the buffer.
            for i in stride(from: 0, to: buffer.frameLength, by: 800 / self.soundGraphHandler.maximumVisiblePoints) {
                graphData.append(Double(rawData[Int(i)]) / Double(Int16.max))
            }
            DispatchQueue.main.async {
                guard self.engine != nil && self.engine!.isRunning else {
                    return
                }
                self.soundGraphHandler.addPoints(withValues: graphData)
            }
                
            let data = Data(bytes: rawData, count: Int(buffer.frameLength * 2))
            self.targetPeripheral?.play(pcm16bit: data)
        }
        
        do {
            engine!.prepare()
            try engine!.start()
        } catch {
            print("AVAudioEngine.start() error: \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    private func stopRecording() {
        // Remove the tap and stop recording.
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine?.reset()
        engine = nil
    }
    
    private func startPlaying() {
        // The pcmFormatInt16 format is not supported in AvAudioPlayerNode
        // Later on we will have to devide all values by Int16.max to get values from -1.0 to 1.0
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: true)
        
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        engine!.attach(player!)
        engine!.connect(player!, to: engine!.mainMixerNode, format: format)
        engine!.mainMixerNode.volume = 1.0
        
        do {
            engine!.prepare()
            try engine!.start()
        } catch {
            print("AVAudioEngine.start() error: \(error.localizedDescription)")
        }
        player!.play()
    }
    
    private func schedule(pcm16Data: [Int16]) {
        guard let engine = engine, engine.isRunning else {
            // Streaming has been already stopped
            return
        }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.mainMixerNode.inputFormat(forBus: 0), frameCapacity: AVAudioFrameCount(pcm16Data.count))!
        buffer.frameLength = buffer.frameCapacity
        
        var graphData = [Double]()
        for i in 0 ..< pcm16Data.count {
            buffer.floatChannelData![0 /* channel 1 */][i] = Float32(pcm16Data[i]) / Float32(Int16.max) // TODO: 32 - increases volume, this should be done on Thingy
            // print("Value \(i): \(pcm16Data[i]) => \(buffer.floatChannelData![0][i])")
            
            // Unfortunatelly we can't show all samples on the graph, it would be too slow.
            // We show only every n-th sample from whole 800 samples in the buffer keeping the same precission as when sending sound.
            if i % (800 / self.soundGraphHandler.maximumVisiblePoints) == 0 {
                graphData.append((Double((buffer.floatChannelData![0][i]))))
            }
        }
        DispatchQueue.main.async {
            guard self.engine != nil && self.engine!.isRunning else {
                return
            }
            self.soundGraphHandler.addPoints(withValues: graphData)
        }
        
        player!.scheduleBuffer(buffer, completionHandler: nil)
    }
    
    private func stopPlaying() {
        player?.stop()
        engine?.stop()
        engine?.reset()
        player = nil
        engine = nil
    }
}
