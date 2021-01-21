//
//  ViewController.swift
//  AESDecoder
//
//  Created by Максим Кудрявцев on 20.01.2021.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var keyTextField: NSTextField!
    
    private var fileURL: URL?
    private var textFieldText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        keyTextField.delegate = self
        if let key = UserDefaults.standard.string(forKey: "aesKey") {
            keyTextField.stringValue = key
            textFieldText = key
        }
    }
    
    @IBAction func saveFileButtonAction(_ sender: Any) {
        guard let text = textView.textStorage?.mutableString else {
            printError("Cant save file. Text of textView is nil")
            return
        }
        let string = String(text)
        FileManager.openSaveToFileDialog(string: string, withFileName: "logs.txt")
    }
    
    @IBAction func chooseFileButtonAction(_ sender: Any) {
        guard !textFieldText.isEmpty else {
            let alert = NSAlert.init()
            alert.messageText = "Error"
            alert.informativeText = "Enter 256 bit AES decoding key firstly."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        FileManager.openChooseFileDialog(title: "Choose a .txt aes decoded file", fileTypes: ["txt"]) { [weak self] response, fileURL in
            guard let self = self else {
                print("self is nil")
                return
            }
            guard response == .OK else {
                self.printError("response is not OK")
                return
            }
            guard let fileURL = fileURL else {
                self.printError("fileURL is nil")
                return
            }
            self.fileURL = fileURL
            let password = self.keyTextField.stringValue
            do {
                let data = try Data(contentsOf: fileURL)
                let decryptedData = try RNCryptor.decrypt(data: data, withPassword: password)
                guard let decryptedString = String(bytes: decryptedData, encoding: .utf8) else {
                    self.printError("Cant init string from decrypted data using utf8 encoding")
                    return
                }
                self.textView.textStorage?.mutableString.setString("")
                self.textView.textStorage?.append(NSAttributedString(string: decryptedString, attributes: [.foregroundColor: NSColor.white]))
            } catch {
                self.printError(error.localizedDescription)
            }
        }
    }
    
    func printError(_ error: String) {
        textView.textStorage?.mutableString.setString("")
        textView.textStorage?.append(NSAttributedString(string: "FinesAESDecoder error: \(error)", attributes: [.foregroundColor: NSColor.white]))
    }
}

extension ViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        textFieldText = textField.stringValue
        UserDefaults.standard.set(textField.stringValue, forKey: "aesKey")
    }
}

struct FileManager {
    static func openChooseFileDialog(title: String, fileTypes: [String], completion: @escaping (NSApplication.ModalResponse, URL?) -> Void) {
         let dialog = NSOpenPanel()
         dialog.title                   = title
         dialog.showsResizeIndicator    = false
         dialog.showsHiddenFiles        = true
         dialog.canChooseDirectories    = false
         dialog.canCreateDirectories    = false
         dialog.allowsMultipleSelection = false
         dialog.allowedFileTypes        = fileTypes
         dialog.begin { response in
             completion(response, dialog.url)
         }
     }
     
    static func openSaveToFileDialog(string: String, withFileName fileName: String) {
         let savePanel = NSSavePanel()
         savePanel.allowedFileTypes = ["txt"]
         savePanel.nameFieldStringValue = fileName
         savePanel.begin { result in
             guard result == .OK, let fileUrl = savePanel.url else {
                 NSSound.beep()
                 return
             }
             do {
                 try string.write(to: fileUrl, atomically: true, encoding: .utf8)
             } catch {
                print(error)
                 // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
             }
         }
     }
}
