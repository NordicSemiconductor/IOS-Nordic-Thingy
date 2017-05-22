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
//  FolderFilesViewController.swift
//
//  Created by Aleksander Nowakowski on 05/05/2017.
//

import UIKit

class FolderFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Class Properties
    var files                   : [URL]?
    var directoryPath           : URL!
    var directoryName           : String!
    var fileDelegate            : FileSelectionDelegate?
    var preselectionDelegate    : FilePreselectionDelegate?
    var selectedPath            : URL?
    
    //MARK: - View Outlets
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    //MARK: - View Actions
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        doneButtonTappedEventHandler()
    }
    
    //MARK: - UIViewDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if directoryName != nil {
            navigationItem.title = directoryName!
        } else {
            navigationItem.title = "Files"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doneButton.isEnabled = selectedPath != nil
        do {
            try files = FileManager.default.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        } catch {
            print(error)
        }
        ensureDirectoryNotEmpty()
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (files?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "FolderFilesCell", for:indexPath)
        let aFilePath = files?[indexPath.row]
        let fileName = aFilePath?.lastPathComponent
        
        //Configuring the cell
        aCell.textLabel?.text = fileName
        if fileName?.lowercased().contains(".zip") != false {
            aCell.imageView?.image = UIImage(named: "ic_archive")
        } else {
            aCell.imageView?.image = UIImage(named: "ic_file")
        }
        
        if aFilePath == selectedPath {
            aCell.accessoryType = .checkmark
        } else {
            aCell.accessoryType = .none
        }
        
        return aCell
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filePath = files?[indexPath.row]
        selectedPath = filePath
        tableView.reloadData()
        doneButton.isEnabled = true
        preselectionDelegate?.onFilePreselected(withURL: filePath!)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        
        let filePath = files?[indexPath.row]
        do {
            try FileManager.default.removeItem(at: filePath!)
        } catch {
            print("Error while deleting file: \(error)")
            return
        }
        
        files?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        
        if filePath == selectedPath {
            selectedPath = nil
            preselectionDelegate?.onFilePreselected(withURL: filePath!)
            doneButton.isEnabled = false
        }
        
        ensureDirectoryNotEmpty()
    }
    
    //MARK: - FolderFilesViewController Implementation
    func ensureDirectoryNotEmpty() {
        if (files?.count)! == 0 {
            emptyView.isHidden = false
        }
    }
    
    func doneButtonTappedEventHandler() {
        // Go back to DFUViewController
        fileDelegate?.onFileSelected(withURL: self.selectedPath!)
        dismiss(animated: true)
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
    }
}
