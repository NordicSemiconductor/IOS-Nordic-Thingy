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
//  ThingyMotionViewController.swift
//
//  Created by Mostafa Berg on 06/10/16.
//

import UIKit
import CoreMotion
import Charts
import IOSThingyLibrary

class ThingyMotionViewController: SwipableTableViewController, ThingyMotionControlDelegate, UIPopoverPresentationControllerDelegate {

    //MARK: - Defaults
    private let defaults : UserDefaults!
    private let keyGravityVectorEnabled  = "gravityvector_enabled"
    private let keyHeadingEnabled        = "heading_enabled"
    private let keyPedometerEnabled      = "pedometer_enabled"
    private let keyQuaternionEnabled     = "quaternion_enabled"
    private let keyOrientationEnabled    = "orientation_enabled"
    private let keyTapEnabled            = "tap_enabled"

    //MARK: - Properties and data
    var gravityVectorGraphHandler   : GraphDataHandler!
    
    private weak var settingsViewController: ThingyNavigationController?
    
    //MARK: - IBOutlets
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var control3DMotion: UIButton!
    @IBOutlet weak var controlMotionButton: UIButton!
    @IBOutlet weak var controlGravityButton: UIButton!

    //MARK: 3D
    @IBOutlet weak var sceneView: MotionModelScene!
    
    //MARK: - Motion
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var stepCountDurationLabel: UILabel!
    @IBOutlet weak var tapCountLabel: UILabel!
    @IBOutlet weak var tapDirectionLabel: UILabel!
    @IBOutlet weak var headingAnglesLabel: UILabel!
    @IBOutlet weak var headingTextLabel: UILabel!
    @IBOutlet weak var orientationIcon: UIImageView!
    @IBOutlet weak var orientationLabel: UILabel!
    @IBOutlet weak var headingIcon: UIImageView!

    //MARK: Gravity Vector
    @IBOutlet weak var gravityVectorChartView: LineChartView!
    @IBOutlet weak var scrollGravityVectorGraphButton: UIButton!
    @IBOutlet weak var clearGravityVectorGraphButton: UIButton!

    //MARK: - IBActions
    @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        toggleRevealView()
    }
    
    //MARK: - UIVIewController Implementation
    required init?(coder aDecoder: NSCoder) {
        defaults = UserDefaults.standard
        defaults.register(defaults:
            [
                keyQuaternionEnabled     : true,  // 3D enabled by default
                keyGravityVectorEnabled  : false,
                keyHeadingEnabled        : false,
                keyPedometerEnabled      : false,
                keyOrientationEnabled    : false,
                keyTapEnabled            : false,
            ]
        )
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate graph handlers
        initGraphViews()
        cleanupData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.start()
        settingsViewController = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if defaults.bool(forKey: kViewedMenuTooltip) == true && defaults.bool(forKey: kViewedSensorsTooltip) == false {
            setSeenSensorsTooltip()
            performSegue(withIdentifier: "showServicesTip", sender: nil)
        }
    }

    private func setSeenSensorsTooltip() {
        guard defaults.bool(forKey: kViewedSensorsTooltip) == false else {
            return
        }
        defaults.set(true, forKey: kViewedSensorsTooltip)
        defaults.synchronize()
    }

    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Segue for the popover configuration window
        if segue.identifier == "show3DControl" {
            let controller = segue.destination as! Thingy3DControlViewController
            controller.delegate = self
            controller.quaternionEnabled    = defaults.bool(forKey: keyQuaternionEnabled)
            controller.popoverPresentationController?.sourceView = sender as! UIButton
            controller.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showGravityVectorControl" {
            let controller = segue.destination as! ThingyGravityVectorControlViewController
            controller.delegate = self
            controller.gravityVectorEnabled = defaults.bool(forKey: keyGravityVectorEnabled)
            controller.popoverPresentationController?.sourceView = sender as! UIButton
            controller.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showMotionControl" {
            let controller = segue.destination as! ThingyMotionControlViewController
            controller.delegate = self
            controller.headingEnabled       = defaults.bool(forKey: keyHeadingEnabled)
            controller.pedometerEnabled     = defaults.bool(forKey: keyPedometerEnabled)
            controller.orientationEnabled   = defaults.bool(forKey: keyOrientationEnabled)
            controller.tapEnabled           = defaults.bool(forKey: keyTapEnabled)
            controller.popoverPresentationController?.sourceView = sender as! UIButton
            controller.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showInfo" {
            segue.destination.popoverPresentationController?.sourceView = sender as! UIButton
            segue.destination.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showSettings" {
            settingsViewController = segue.destination as? ThingyNavigationController
            settingsViewController?.setTargetPeripheral(targetPeripheral, andManager: thingyManager)
        } else if segue.identifier == "showServicesTip" {
            // Show user tip to enable/disable services
            segue.destination.popoverPresentationController?.sourceView = control3DMotion
            segue.destination.popoverPresentationController?.delegate = self
        }
    }
    
    func setControlButtonsState(enabled newValue: Bool) {
        settingsButton.isEnabled        = newValue
        control3DMotion.isEnabled       = newValue
        controlMotionButton.isEnabled   = newValue
        controlGravityButton.isEnabled  = newValue
    }

    //MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // This method must return .none in order to show the ThingyMotionControlViewController as popover
        return .none
    }
    
    //MARK: - Thingy API
    override func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        navigationItem.title = "Motion"
        
        setControlButtonsState(enabled: peripheral.state == .ready)

        settingsViewController?.thingyPeripheral(peripheral, didChangeStateTo: state)
        if settingsViewController == nil && state == .ready {
            enableNotifications()
        }
    }
    
    override func targetPeripheralWillChange(old: ThingyPeripheral, new: ThingyPeripheral?) {
        disableNotifications()
        if new != nil {
            gravityVectorGraphHandler.clearGraphData()
        }
    }
    
    //MARK: - Implementation
    private func initGraphViews() {
        gravityVectorGraphHandler = GraphDataHandler(withGraphView: gravityVectorChartView,
                                                     noDataText: "No Gravity data",
                                                     minValue: -10, maxValue: 10,
                                                     numberOfDataSets: 3,
                                                     dataSetNames: ["X-Axis", "Y-Axis", "Z-Axis"],
                                                     dataSetColors: [UIColor.nordicRed,
                                                                     UIColor.nordicGrass,
                                                                     UIColor.nordicLake],
                                                     andMaxVisibleEntries: 10)
        gravityVectorGraphHandler.scrollGraphButton = scrollGravityVectorGraphButton
        gravityVectorGraphHandler.clearGraphButton = clearGravityVectorGraphButton
        
        if #available(iOS 13.0, *) {
            gravityVectorChartView.xAxis.labelTextColor = UIColor.label
            gravityVectorChartView.getAxis(.left).labelTextColor = UIColor.label
            gravityVectorChartView.legend.textColor = UIColor.label
        }
    }

    private func cleanupData() {
        //Default state for labels
        stepCountDurationLabel.text = "00:00:00"
        stepCountLabel.text         = "0"
        tapCountLabel.text          = "0"
        tapDirectionLabel.text      = "N/A"
        headingAnglesLabel.text     = "0"
        headingTextLabel.text       = "N/A"
        orientationLabel.text       = "N/A"
    }
    
    //MARK: - ThingyMotionControlDelegate

    func gravityVectorNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyGravityVectorEnabled)
        if enabled {
            targetPeripheral?.beginGravityVectorUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Start gravity vector updates: \(success)")
            }, andNotificationHandler: { (x, y, z) -> (Void) in
                self.gravityVectorGraphHandler.addPoints(withValues: [Double(x), Double(y), Double(z)])
            })
        } else {
            stopGravityVectorNotifications()
        }
    }

    func headingNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyHeadingEnabled)
        if enabled {
            targetPeripheral?.beginHeadingUpdates(withCompletoinHandler: { (success) -> (Void) in
                print("Start heading updates: \(success)")
            }, andNotificationHandler: { (heading) -> (Void) in
                self.headingAnglesLabel.text = String(format:"%.1f°", heading)
                if heading > 0 && heading < 90 {
                    self.headingTextLabel.text = "NE"
                } else if heading < 180 && heading > 90 {
                    self.headingTextLabel.text = "NW"
                } else if heading < 270 && heading > 180 {
                    self.headingTextLabel.text = "SW"
                } else if heading > 270 && heading < 360 {
                    self.headingTextLabel.text = "SE"
                } else if heading == 0 || heading == 360 {
                    self.headingTextLabel.text = "EAST"
                } else if heading == 90 {
                    self.headingTextLabel.text = "NORTH"
                } else if heading == 180 {
                    self.headingTextLabel.text = "WEST"
                } else if heading == 270 {
                    self.headingTextLabel.text = "SOUTH"
                } else {
                    self.headingTextLabel.text = "UNKNOWN"
                }
                self.rotateView(aView: self.headingIcon, withAngle: Double(heading), andDuration: 0.1)
            })
        } else {
           stopHeadingNotificatoins()
        }
    }
    
    func pedometerNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyPedometerEnabled)
        if enabled {
            targetPeripheral?.beginPedometerUpdates(withCompletoinHandler: { (success) -> (Void) in
                print("Pedometer updates enabled: \(success)")
            }, andNotificationHandler: { (step, time) -> (Void) in
                self.stepCountLabel.text         = String(format: "%d", step)
                let formattedTime                = self.formatMillisecondsToReadableTime(time: time)
                self.stepCountDurationLabel.text = formattedTime
            })
        } else {
            stopPedometerNotificatoins()
        }
    }
    
    func quaternionNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyQuaternionEnabled)
        let updateInterval = 0.1
        if enabled {
            targetPeripheral?.beginQuaternionUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Quaternion updates enabled: \(success)")
            }, andNotificationHandler: { (w, x, y, z) -> (Void) in
                self.sceneView.setThingyQuaternion(x: x, y: y, z: z, w: w,
                                                   andUpdateInterval: TimeInterval(updateInterval))
            })
        } else {
            stopQuaternionNotifications()
        }
    }
    
    func orientationNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyOrientationEnabled)
        if enabled {
            targetPeripheral?.beginOrientationUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Orientation updates enabled: \(success)")
            }, andNotificationHandler: { (orientation) -> (Void) in
                var readableOrientation: String
                switch orientation {
                    case .landscape:
                        readableOrientation = "LANDSCAPE"
                        self.rotateView(aView: self.orientationIcon, withAngle: 90, andDuration: 0.5)
                    case .portrait:
                        readableOrientation = "PORTRAIT"
                        self.rotateView(aView: self.orientationIcon, withAngle: 0, andDuration: 0.5)
                    case .reverseLandscape:
                        readableOrientation = "REV. LANDSCAPE"
                        self.rotateView(aView: self.orientationIcon, withAngle: -90, andDuration: 0.5)
                    case .reversePortrait:
                        readableOrientation = "REV. PORTRAIT"
                        self.rotateView(aView: self.orientationIcon, withAngle: 180, andDuration: 0.5)
                    default:
                        readableOrientation = "N/A"
                        self.rotateView(aView: self.orientationIcon, withAngle: 0, andDuration: 0.5)
                }
                self.orientationLabel.text = readableOrientation
            })
        } else {
            stopOrientationNotifications()
        }
    }
    
    func tapNotificationsDidChangeTo(enabled: Bool) {
        defaults.set(enabled, forKey: keyTapEnabled)
        if enabled {
            targetPeripheral?.beginTapUpdates(withCompletionHandler: { (success) -> (Void) in
                print("Tap updates enabled: \(success)")
            }, andNotificationHandler: { (tapDirection, tapCount) -> (Void) in
                
                var directionString: String

                switch tapDirection {
                case .XDown:
                    directionString = "X-DOWN"
                case .XUp:
                    directionString = "X-UP"
                case .YDown:
                    directionString = "Y-DOWN"
                case .YUp:
                    directionString = "Y-UP"
                case .ZDown:
                    directionString = "Z-DOWN"
                case .ZUp:
                    directionString = "Z-UP"
                default:
                    directionString = "N/A"
                }
                
                self.tapCountLabel.text = String(format:"%d", tapCount)
                self.tapDirectionLabel.text = directionString
            })
        } else {
            stopTapNotifications()
        }
    }

    //MARK: - Convenience
    private func enableNotifications() {
        if defaults.bool(forKey: keyGravityVectorEnabled) {
            gravityVectorNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyHeadingEnabled) {
            headingNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyPedometerEnabled) {
            pedometerNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyQuaternionEnabled) {
            quaternionNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyOrientationEnabled) {
            orientationNotificationsDidChangeTo(enabled: true)
        }
        if defaults.bool(forKey: keyTapEnabled) {
            tapNotificationsDidChangeTo(enabled: true)
        }
    }
    
    private func disableNotifications() {
        if settingsViewController == nil {
            stopTapNotifications()
            stopHeadingNotificatoins()
            stopPedometerNotificatoins()
            stopQuaternionNotifications()
            stopOrientationNotifications()
            stopGravityVectorNotifications()
        }
    }

    private func stopQuaternionNotifications() {
        targetPeripheral?.stopQuaternionUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Quaternion updates disabled: \(success)")
            // Slowly animate 3d model back to identity
            self.sceneView.setThingyQuaternion(x: 0, y: 0, z: 0, w: 1, andUpdateInterval: 1)
        })
    }
    private func stopGravityVectorNotifications() {
        targetPeripheral?.stopGravityVectorUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Gravity vector updates disabled: \(success)")
        })
    }
    
    private func stopHeadingNotificatoins() {
        targetPeripheral?.stopHeadingataUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Heading updates disabled: \(success)")
        })
    }
    
    private func stopPedometerNotificatoins() {
        targetPeripheral?.stopPedometerUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Pedometer updates disabled: \(success)")
        })
    }
    
    private func stopOrientationNotifications() {
        targetPeripheral?.stopOrientationUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Orientation updates disabled: \(success)")
        })
    }
    
    private func stopTapNotifications() {
        targetPeripheral?.stopTapUpdates(withCompletionHandler: { (success) -> (Void) in
            print("Tap updates disabled: \(success)")
        })
    }
    
    private func rotateView(aView: UIView, withAngle anAngle: Double, andDuration aDuration: Double) {
        let radians = anAngle * .pi / 180
        let rotation = CATransform3DMakeRotation(CGFloat(radians), 0, 0, 1)
        aView.layer.transform = rotation
        let currentAngle = aView.layer.value(forKeyPath: "transform.rotation.z")
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fillMode = CAMediaTimingFillMode.forwards
        rotateAnimation.fromValue = currentAngle
        rotateAnimation.duration = aDuration
        aView.layer.add(rotateAnimation, forKey: nil)
    }
    
    private func formatMillisecondsToReadableTime(time: UInt32) -> String {
        let date = Date(timeIntervalSince1970: Double(time) / 1000)
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "mm:ss:SSS"
        
        return formatter.string(from: date)
    }
}
