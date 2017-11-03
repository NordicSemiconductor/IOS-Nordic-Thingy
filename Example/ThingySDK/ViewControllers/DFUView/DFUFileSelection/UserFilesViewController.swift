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
//  UserFilesViewController.swift
//
//  Created by Aleksander Nowakowski on 05/05/2017.
//

import UIKit

class UserFilesViewController: UIViewController, FilePreselectionDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Class properties
    var fileDelegate : FileSelectionDelegate?
    var selectedPath : URL?
    var files        : [URL]!
    var documentsDirectoryPath : String?

    //MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    
    
    //MARK: - UIViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        files = [URL]()
        let fileManager = FileManager.default
        let documentsURL = URL(string: documentsDirectoryPath!)
        
        do {
            try files = fileManager.contentsOfDirectory(at: documentsURL!, includingPropertiesForKeys: [], options: .skipsHiddenFiles)
        } catch {
            print("Error \(error)")
        }
        
        // The Navigation Item buttons may be initialized just once, here.
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneButtonTapped))
        tabBarController?.navigationItem.leftBarButtonItem  = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelButtonTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let buttonEnabled = selectedPath != nil
        tabBarController!.navigationItem.rightBarButtonItem!.isEnabled = buttonEnabled
        ensureDirectoryNotEmpty()
    }
    
    //MARK: - UserFilesViewController
    func ensureDirectoryNotEmpty() {
        if files.count == 0 {
            emptyView.isHidden = false
        }
    }
    
    @objc func doneButtonTapped() {
        dismiss(animated: true, completion: nil)
        fileDelegate?.onFileSelected(withURL: selectedPath!)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - FilePreselectionDelegate
    func onFilePreselected(withURL aFileURL: URL) {
        selectedPath = aFileURL
        tableView.reloadData()
        tabBarController!.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count + 1 //Increment one for the tutorial on first row
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row == 0{
            return 84
        } else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        if (indexPath as NSIndexPath).row == 0 {
            // Tutorial row
            return tableView.dequeueReusableCell(withIdentifier: "UserFilesCellHelp", for: indexPath)
        }
        
        ensureDirectoryNotEmpty()  // Always check if the table is empty
        
        // File row
        let aCell = tableView.dequeueReusableCell(withIdentifier: "UserFilesCell", for: indexPath)
        
        // Configure the cell...
        let filePath = files[(indexPath as NSIndexPath).row - 1]
        let fileName = filePath.lastPathComponent
        
        aCell.textLabel!.text = fileName
        aCell.accessoryType = .none
        
        var isDirectory : ObjCBool = false
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.relativePath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                aCell.accessoryType = .disclosureIndicator
                if (fileName.lowercased() == "inbox") {
                    aCell.imageView!.image = UIImage(named:"ic_email")
                } else {
                    aCell.imageView!.image = UIImage(named:"ic_folder")
                }
            } else if fileName.lowercased().contains(".zip") {
                aCell.imageView!.image = UIImage(named:"ic_archive")
            }  else {
                aCell.imageView!.image = UIImage(named: "ic_file")
            }
        } else {
            showFileDoesNotExistAlert()
        }
        
        if let selectedPath = selectedPath, filePath == selectedPath {
            aCell.accessoryType = .checkmark
        }
        return aCell;
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            // Tutorial row
            performSegue(withIdentifier: "openTutorial", sender: self)
        } else {
            // Normal row
            let filePath = files[(indexPath as NSIndexPath).row - 1]
            
            var isDirectory : ObjCBool = false
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath.relativePath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    performSegue(withIdentifier: "openFolder", sender: self)
                } else {
                    onFilePreselected(withURL: filePath)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if (indexPath as NSIndexPath).row > 0 {
            // Inbox folder can't be deleted
            let filePath = files[(indexPath as NSIndexPath).row - 1]
            let fileName = filePath.lastPathComponent
            
            if fileName.lowercased() == "inbox" {
                return .none
            } else {
                return .delete
            }
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let filePath = files[(indexPath as NSIndexPath).row - 1]
            
            do {
                try FileManager.default.removeItem(at: filePath)
                files?.remove(at: (indexPath as NSIndexPath).row - 1)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                
                if filePath == selectedPath {
                    onFilePreselected(withURL:selectedPath!)
                }
            } catch {
                print("An error occured while deleting file\(error)")
            }
        }
    }
    
    //MARK: - Segue navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openFolder" {
            let selectionIndexPath = tableView.indexPathForSelectedRow
            let filePath = files[((selectionIndexPath as NSIndexPath?)?.row)! - 1]
            let fileName = filePath.lastPathComponent
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath.relativePath) {                
                let folderVC = segue.destination as! FolderFilesViewController
                folderVC.directoryPath = filePath
                folderVC.directoryName = fileName
                folderVC.fileDelegate = fileDelegate!
                folderVC.preselectionDelegate = self
                folderVC.selectedPath = selectedPath
            } else {
                showFileDoesNotExistAlert()
            }
        }
    }
    
    private func showFileDoesNotExistAlert() {
        let alert = UIAlertController(title: "Error", message: "File foes not exist!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            alert.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
}
