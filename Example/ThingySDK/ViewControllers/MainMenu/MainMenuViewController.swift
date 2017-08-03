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
//  MainMenuViewController.swift
//
//  Created by Mostafa Berg on 05/10/16.
//

import UIKit
import IOSThingyLibrary

fileprivate let tableHeaderIdentifier       = "ExpandableMenuHeaderView"
fileprivate let tableCellIdentifier         = "MenuItemCell"
fileprivate let deviceCellIdentifier        = "DeviceItemCell"
fileprivate let tableHeaderHeight : CGFloat = 48

class MainMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ExpandableTableHeaderViewDelegate, ThingyPeripheralDelegate {

    //MARK: Properties
    public  var targetNavigationController : MainNavigationViewController!
    public  var newThingyDelegate          : NewThingyDelegate?
    private var thingyManager              : ThingyManager?
    private var targetPeripheral           : ThingyPeripheral? {
        get {
            return newThingyDelegate?.targetPeripheral
        }
        set {
            newThingyDelegate?.targetPeripheral = newValue
        }
    }
    private var mainHeaderIsExpanded       : Bool
    private var menuPeripherals            : [ThingyPeripheral]

    //MARK: Menu Content
    private let menuSections = [
        "DEVICES",
        "SERVICES",
        "MORE"
    ]

    private let serviceMenuItems = [
        "Environment",
        "UI",
        "Motion",
        "Sound",
        "Cloud",
        "Configuration"
    ]
    
    private let moreMenuItems = [
        "Device Firmware Update",
        "About"
    ]
    
    private let serviceMenuIcons = [
        #imageLiteral(resourceName: "ic_wb_sunny_24pt"),
        #imageLiteral(resourceName: "ic_widgets_24pt"),
        #imageLiteral(resourceName: "ic_motion_24pt"),
        #imageLiteral(resourceName: "ic_sound_24pt"),
        #imageLiteral(resourceName: "ic_cloud_upload"),
        #imageLiteral(resourceName: "ic_settings_24pt")
    ]
    
    private let moreMenuIcons = [
        #imageLiteral(resourceName: "ic_dfu_24pt"),
        #imageLiteral(resourceName: "ic_info_24pt")
    ]
    
    //MARK: Outlets
    @IBAction func addButtonTapped(_ sender: Any) {
        targetNavigationController.showInitialConfigurationView()
        revealViewController().revealToggle(animated: true)
    }

    @IBOutlet weak var menuTableView: UITableView!
    
    //MARK: UIView implementation
    required init?(coder aDecoder: NSCoder) {
        menuPeripherals = [ThingyPeripheral]()
        mainHeaderIsExpanded = true
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let sectionView = UINib(nibName: "MenuExpandableHeaderView", bundle: nil)
        menuTableView.register(sectionView, forHeaderFooterViewReuseIdentifier: tableHeaderIdentifier)
        menuTableView.sectionHeaderHeight = tableHeaderHeight
        setupTargetController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadPeripherals(activeOnly: !mainHeaderIsExpanded)
        menuTableView.reloadData()
    }
    
    //MARK: - MenuViewController Implementation
    private func setupTargetController() {
        if targetNavigationController == nil {
            targetNavigationController = revealViewController().frontViewController as! MainNavigationViewController
        }
    }
    
    private func reloadPeripherals(activeOnly: Bool) {
        guard thingyManager != nil else {
            print("No manager set")
            return
        }
        
        menuPeripherals.removeAll()
        if activeOnly {
            if let activePeripherals = thingyManager!.activePeripherals() {
                menuPeripherals = activePeripherals
            }
        } else {
            if let storedPeripherals = thingyManager!.storedPeripherals() {
                menuPeripherals = storedPeripherals
            }
        }
    }
    
    func setThingyManager(_ aManager: ThingyManager) {
        thingyManager = aManager
    }
    
    func thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState) {
        print("Menu: Peripheral state changed to \(state)")
        reloadPeripherals(activeOnly: !mainHeaderIsExpanded)
        // This callback may be called before the view is loaded when first device was added using Add Thingy button on the main screen
        // before the menu was opened
        if isViewLoaded && menuTableView.isEditing == false {
            if menuPeripherals.isEmpty && mainHeaderIsExpanded == false {
                let expandableSection = menuTableView.viewWithTag(1) as! ExpandableTableHeaderView
                expandableSection.toggle(force: true)
            } else {
                menuTableView.reloadData()
            }
        }
        showDFUAlert()
    }

    //MARK: - Implementation
    private func showDFUAlert() {
        guard targetPeripheral != nil && targetPeripheral!.state == .ready else {
            return
        }

        let configFirmwareVersion = targetPeripheral?.readFirmwareVersion() ?? "0.0.0"
        if configFirmwareVersion == "0.0.0" {
            return
        }
        if configFirmwareVersion.versionToInt().lexicographicallyPrecedes(kCurrentDfuVersion.versionToInt()) {
            var message: String
            message = "\r\nUpdating is recommended as it ensures full compatibilty with the Thingy app and includes all the latest features and bug fixes."
            let dfuAlert = UIAlertController(title: "Firmware update available for \((targetPeripheral?.name)!)", message: message, preferredStyle: .alert)
            dfuAlert.addAction(UIAlertAction(title: "Update to \(kCurrentDfuVersion)", style: .default, handler: { (action) in
                self.targetNavigationController.showDFUView()
            }))
            dfuAlert.addAction(UIAlertAction(title: "Not now", style: .cancel))
                present(dfuAlert, animated: true)
        }
    }

    //MARK: -
    //MARK: ExpandableTableHeaderViewDelegate methods
    //MARK: -
    func canCollapse(forSection section: Int) -> Bool {
        guard section == 0 else {
            return false
        }
        
        return connectedPeripheralCount() > 0
    }
    
    func didExpandHeaderView(forSection section: Int) {
        guard section == 0 && mainHeaderIsExpanded == false else {
            //We are only interested in the first section that contains devices when the header is closed
            return
        }

        mainHeaderIsExpanded = true
        //Get current peripheral paths to remove
        var oldPaths = [IndexPath]()

        let connectedMenuPeripheralCount = connectedPeripheralCount()

        for i in 0 ..< connectedMenuPeripheralCount {
            oldPaths.append(IndexPath(row: i, section: section))
        }

        reloadPeripherals(activeOnly: false)

        //Create paths to add for new Thingies
        var newPaths: [IndexPath] = [IndexPath]()
        for i in 0 ..< menuPeripherals.count {
            newPaths.append(IndexPath(row: i, section: section))
        }
        
        menuTableView.beginUpdates()
        if oldPaths.count > 0 {
            menuTableView.deleteRows(at: oldPaths, with: .fade)
        } else {
            // Delete "No devices"
            menuTableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .fade)
        }
        if newPaths.count > 0 {
            menuTableView.insertRows(at: newPaths, with: .fade)
        } else {
            // Add "No devices"
            menuTableView.insertRows(at: [IndexPath(row: 0, section: section)], with: .fade)
        }
        updateServicesMenu()
        menuTableView.endUpdates()
    }
    
    func didCollapseHeaderView(forSection section: Int) {
        guard section == 0 && mainHeaderIsExpanded == true else {
            //We are only interested in the first section that contains devices when the header is expanded
            return
        }

        mainHeaderIsExpanded = false
        //Get current peripheral paths to remove
        var oldPaths: [IndexPath] = [IndexPath]()
        for i in 0 ..< menuPeripherals.count {
            oldPaths.append(IndexPath(row: i, section: section))
        }
        reloadPeripherals(activeOnly: true)
        //Create paths to add for new Thingies
        var newPaths = [IndexPath]()
        
        let connectedPeripherals = connectedPeripheralCount()
        
        for i in 0 ..< connectedPeripherals {
            newPaths.append(IndexPath(row: i, section: section))
        }

        menuTableView.beginUpdates()
        if oldPaths.count > 0 {
            menuTableView.deleteRows(at: oldPaths, with: .fade)
        } else {
            // Delete "No devices"
            menuTableView.deleteRows(at: [IndexPath(row: 0, section: section)], with: .fade)
        }
        if newPaths.count > 0 {
            menuTableView.insertRows(at: newPaths, with: .fade)
        } else {
            // Add "No devices"
            menuTableView.insertRows(at: [IndexPath(row: 0, section: section)], with: .fade)
        }
        updateServicesMenu()
        menuTableView.endUpdates()
    }

    private func updateServicesMenu() {
        if connectedPeripheralCount() > 0 {
            if menuTableView.numberOfRows(inSection: 1) == 0 {
                //We have connected peripherals, add all menu items
                var menuSectionPaths = [IndexPath]()
                //Then read all other menu rows
                for i in 0 ..< serviceMenuItems.count {
                    menuSectionPaths.append(IndexPath(row: i, section: 1))
                }
                menuTableView.insertRows(at: menuSectionPaths, with: .fade)
            }
        } else {
            if menuTableView.numberOfRows(inSection: 1) == serviceMenuItems.count {
                //No peripherals conected, but we are showing menu, only display DFU and about buttons
                var menuSectionPaths = [IndexPath]()
                //Then read all other menu rows
                for i in 0 ..< serviceMenuItems.count {
                    menuSectionPaths.append(IndexPath(row: i, section: 1))
                }
                
                menuTableView.deleteRows(at: menuSectionPaths, with: .fade)
            }
        }
    }
    
    private func connectedPeripheralCount() -> Int {
        var connectedMenuPeripheralCount = 0
        for aPeripheral in menuPeripherals {
            if aPeripheral.basePeripheral.state == .connected {
                connectedMenuPeripheralCount += 1
            }
        }
        return connectedMenuPeripheralCount
    }
    
    //MARK: -
    //MARK: UItableViewDelegate methods
    //MARK: -
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return ("Forget")
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(section) {
            
        case 0:
            if mainHeaderIsExpanded {
                let count = menuPeripherals.count
                return max(count, 1) // 1 for 'No connected devices'
            } else {
                let count = connectedPeripheralCount()
                return max(count, 1) // 1 for 'No devices'
            }
        
        case 1:
            let connectedPeripherals = connectedPeripheralCount()
            if connectedPeripherals == 0 {
                return 0
            } else {
                return serviceMenuItems.count
            }
            
        case 2:
            return moreMenuItems.count
        
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) as! MenuItemTableViewCell

        switch (indexPath.section) {
            case 0:
                if menuPeripherals.isEmpty {
                    aCell.updateCell(withTitle: "No Thingy configured", andIcon: #imageLiteral(resourceName: "ic_developer_board_24pt"), isTransparent: true)
                } else {
                    let aPeripheral = menuPeripherals[indexPath.row]
                    aCell.updateCell(withTitle: aPeripheral.name, andIcon: #imageLiteral(resourceName: "ic_developer_board_24pt"), isActive: aPeripheral == targetPeripheral, isTransparent: aPeripheral.state != .ready)
                }

            case 1:
                if connectedPeripheralCount() > 0 {
                    aCell.updateCell(withTitle: serviceMenuItems[indexPath.row], andIcon: serviceMenuIcons[indexPath.row])
                }

            case 2:
                aCell.updateCell(withTitle: moreMenuItems[indexPath.row], andIcon: moreMenuIcons[indexPath.row])

            default:
                aCell.updateCell(withTitle: "Menu", andIcon: nil)
        }

        return aCell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return menuSections.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: tableHeaderIdentifier) as! ExpandableTableHeaderView
        
        switch section {
        case 0:
            headerView.isOpen = mainHeaderIsExpanded
            headerView.updateContents(withTitle: menuSections[section], andIsExpandable: true)
        case 1:
            if connectedPeripheralCount() > 0 {
                headerView.isOpen = false
                headerView.updateContents(withTitle: menuSections[section], andIsExpandable: false)
            }
        case 2:
            headerView.isOpen = false
            headerView.updateContents(withTitle: menuSections[section], andIsExpandable: false)
        default:
            break
        }
        
        headerView.tag      = section + 1
        headerView.delegate = self
        headerView.section  = section

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && connectedPeripheralCount() == 0 {
            return 0
        } else {
            return tableView.sectionHeaderHeight
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && menuPeripherals.isEmpty == false //Only devices are editable
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard indexPath.row <= menuPeripherals.count && thingyManager != nil else {
                //Nothing to delete
                return
            }
            //We are deleting a thingy
            let peripheralToRemove = menuPeripherals[indexPath.row]
            
            var message: String
            if peripheralToRemove.state == .connected {
                message = "Are you sure you want to forget this Thingy?\nThis Thingy will also be disconnected."
            } else {
                message = "Are you sure you want to forget this Thingy?"
            }
            let alert = UIAlertController(title: "Do you want to proceed?", message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)) //NOOP
            alert.addAction(UIAlertAction(title: "Forget", style: .destructive) { (action) in
                self.removePeripheral(peripheralToRemove, at: indexPath)
            })
            present(alert, animated: true)
        }
    }
    
    private func removePeripheral(_ peripheralToRemove: ThingyPeripheral, at indexPath: IndexPath) {
        let removedPeripheralWasDisconnected = peripheralToRemove.state == .disconnected
        
        // Note: If the peripheral was connected, calling the removePeripheral(...) method below will invoke
        // thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState)
        // which will refresh the list of menuPeripherals. Let's keep the original list here so we know which raw should be reloaded.
        let peripheralsBeforeRemoving = menuPeripherals
        
        if thingyManager!.removePeripheral(peripheralToRemove) {
            // If the current active peripheral was removed, switch to the other, preferably a connected one.
            if peripheralToRemove == targetPeripheral {
                targetPeripheral = thingyManager!.activePeripherals()?.first ?? thingyManager!.storedPeripherals()?.first
            }
            
            if mainHeaderIsExpanded == false {
                // Devices list is collapsed. Only connected ones are visible.
                
                // If the device was connected, the method above stated to disconnect the device and set state of
                // the peripheralToRemove first to .disconnecting and immediately after that to .disconnected.
                // Each state change will invoke the thingyPeripheral(_ peripheral: ThingyPeripheral, didChangeStateTo state: ThingyPeripheralState)
                // method in this class which will refresh menu peripherals list.
                // If it was the last connected peripheral the menuPeripherals list is now empty.
                if menuPeripherals.isEmpty {
                    let expandableSection = menuTableView.viewWithTag(1) as! ExpandableTableHeaderView
                    expandableSection.toggle(force: true)
                } else {
                    // There is at least one more connected Thingy.
                    reloadPeripherals(activeOnly: !mainHeaderIsExpanded)
                    menuTableView.beginUpdates()
                    menuTableView.deleteRows(at: [indexPath], with: .automatic)
                    menuTableView.reloadRows(at: [IndexPath(row: indexPath.row > 0 ? 0 : 1, section: indexPath.section)], with: .automatic) // The first connected Thingy is now active one
                    menuTableView.endUpdates()
                }
            } else {
                // Devices list is expended. All configured devices are visible.
                // Get the row number of the new targetPeripheral before the list of peripherals is reloaded
                let targetPeripheralIndex = targetPeripheral != nil ? peripheralsBeforeRemoving
                    .index(of: targetPeripheral!) : nil
                
                // Reload peripherals list
                reloadPeripherals(activeOnly: !mainHeaderIsExpanded)
                
                // Refresh the table view
                menuTableView.beginUpdates()
                menuTableView.deleteRows(at: [indexPath], with: .automatic)
                if menuPeripherals.isEmpty {
                    menuTableView.insertRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .automatic)
                } else if targetPeripheralIndex != nil { // This is the new targetPeripheral, switched above
                    menuTableView.reloadRows(at: [IndexPath(row: targetPeripheralIndex!, section: indexPath.section)], with: .automatic)
                }
                updateServicesMenu()
                menuTableView.endUpdates()
            }
        
            
            if let thingyManager = thingyManager {
                if thingyManager.removePeripheral(peripheralToRemove) {
                    print("Peripheral removed")
                } else {
                    print("Failed to remove peripheral")
                }
            }
            
            // If the last peripheral has been removed show the "empty view"
            // However, when the peripheral was connected at the time it was removed
            // the removePeripheral method above will start disconnecting the device and set its state
            // to .disconnecting and immediately after that to .disconnected.
            // At the same time an alert controller will be shown by the RootViewController's peripheral 
            // state change delegate method which prevents from performing segue here.
            // The "empty view" will be shown when the alert is dismissed.
            if menuPeripherals.isEmpty && removedPeripheralWasDisconnected {
                targetNavigationController.showEmptyView()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var shouldToggleRevealView = true

        switch indexPath.section {
        case 0:
            if menuPeripherals.count > indexPath.row {
                let peripheral = menuPeripherals[indexPath.row]
                if peripheral.state == .disconnected || peripheral.state == .disconnecting {
                    thingyManager!.connect(toDevice: peripheral)
                    targetPeripheral = peripheral
                } else {
                    if peripheral == targetPeripheral {
                        thingyManager!.disconnect(fromDevice: peripheral)
                        targetPeripheral = thingyManager!.activePeripherals()?.first
                        shouldToggleRevealView = false
                    } else {
                        targetPeripheral = peripheral
                    }
                }
            } else {
                // "No Thingy configured" clicked
                targetNavigationController.showEmptyView()
            }
        case 1:
            if connectedPeripheralCount() > 0 {
                switch(indexPath.row){
                    case 0:
                        targetNavigationController.showEnvironmentView()
                    case 1:
                        targetNavigationController.showUIView()
                    case 2:
                        targetNavigationController.showMotionView()
                    case 3:
                        targetNavigationController.showSoundView()
                    case 4:
                        targetNavigationController.showCloudView()
                    case 5:
                        targetNavigationController.showConfigurationView()
                    default:
                        print("Unknown Selection")
                }
            }
        case 2:
            switch(indexPath.row) {
                case 0:
                    targetNavigationController.showDFUView()
                case 1:
                    targetNavigationController.showAboutView()
                default:
                    print("Unkown Selection")
            }
        default:
            print("Unkown selection")
        }
        
        if shouldToggleRevealView {
            revealViewController().revealToggle(animated: true)
        }
    }
    
    //MARK: - UIScrollViewDelegate methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Prevent table view from bouncing at the top
        if scrollView.contentOffset.y < 0 {
            scrollView.contentOffset.y = 0
        }
    }
}
