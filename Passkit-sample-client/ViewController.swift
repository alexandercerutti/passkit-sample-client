//
//  ViewController.swift
//  Passkit-sample-client
//
//  Created by Alexander Cerutti on 08/05/18.
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {

	let passTypes : [String] = ["eventTicket", "boardingPass", "coupon", "generic", "storeCard", "custom"]
	var passData : PKPass? = nil
	var selectedPassType : String? = nil
	
	@IBOutlet weak var passTypePickerView: UIPickerView!
	@IBOutlet weak var urlField: UITextField!
	@IBOutlet weak var connectingLabel: UILabel!
	@IBOutlet weak var resultArea: UITextView!
	@IBOutlet weak var resultAreaView: UIView!
	@IBOutlet weak var viewDetailsBtn: UIButton!
	@IBOutlet weak var fetchBtn: UIButton!
	
	let errorsDict : [String : String] = [
		"missingURL": "Insert a Passkit Webserver URL to proceed",
		"noConn": "%s. Check also the inserted URL/IP",
		"noLib": "Pass Library is not available on this device",
		"alreadyAvailable": "Library already contains this pass",
		"misBuffer": "Passed data is not a valid buffer",
		"misJSONEncoding": "Unable to encode JSON in http body"
	]
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.passTypePickerView.delegate = self
		self.passTypePickerView.dataSource = self
		self.urlField.delegate = self

		self.selectedPassType = self.passTypes[0]

		// for testing:
		urlField.text = UserDefaults.standard.string(forKey: "lastAddress") ?? ""

		self.fetchBtn.setTitle("Fetch Pass", for: .normal)
		self.fetchBtn.setTitle("Fetching...", for: .disabled)
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? DetailsModalVC {
            vc.passData = self.passData
        }
    }
	
	// MARK: - Custom Functions

    @IBAction func viewDetails(_ sender: Any) {
        self.performSegue(withIdentifier: "DetailsModalVC", sender: sender)
    }

	/**
		Checks if the selected string contains http/s protocol by using a regular expression
	
		- Parameters:
			- string: The string to be checked
	
		- returns: The result of operation
	*/
	
	func protocolCheck(in string: String) -> Bool {
		let pattern = "(https?)://"
		let regex = try! NSRegularExpression(pattern: pattern, options: [])
		let matches = regex.matches(
			in: string,
			options: [],
			range: NSRange(
				location: 0,
				length: Array(string).count
			)
		)

		return matches.count > 0
	}
	
	/**
		Checks if in the selected string a port has been selected
	
		- Parameters:
			- string: url-string
	
		- returns: the results
	*/
	
	func portCheck(in string: String) -> Bool {
		let pattern = ":\\d{2,5}"
		let regex = try! NSRegularExpression(pattern: pattern, options: [])
		let matches = regex.matches(
			in: string,
			options: [],
			range: NSRange(location: 0, length: Array(string).count)
		)
		
		return matches.count > 0
	}

	/**
		Removes all the not-allowed characters from a string
	
		- Parameters:
			- string: The string to be parsed
	
		- returns: The string parsed
	*/
	
	func trimSpecialCharacters(in string: String) -> String {
		let allowedCharacters : Set<Character> = Set(Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890-=[].:!_/"));
		
		return String(Array(string).filter { allowedCharacters.contains($0) })
	}
	
	/**
		Prepares the request to the url inside the text area
	
		- Parameters:
			- sender: the trigger element (may be, e.g. the touch event)
	*/

	@IBAction func prepareRequest(_ sender: Any) {
		self.resultAreaView.isHidden = true
		self.resultArea.isHidden = true
		self.viewDetailsBtn.isHidden = true
		self.fetchBtn.isEnabled = false

		if self.selectedPassType == "custom" {
			let alertController = UIAlertController(title: "Pass Type", message: "Insert a pass model name to continue", preferredStyle: .alert)
			
			let confirm = UIAlertAction(title: "Done", style: .default) { _ in
				let passType = alertController.textFields?[0].text
				
				if passType == nil || (passType?.isEmpty)! {
					self.present(alertController, animated: true, completion: nil)
					return
				}
				
				self.connect(passType!);
			}
			
			let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
			
			alertController.addTextField { textField in
				textField.placeholder = "Enter custom pass name"
			}
			
			alertController.addAction(confirm)
			alertController.addAction(cancel)
			
			self.present(alertController, animated: true, completion: nil)
		} else {
			self.connect(self.selectedPassType!)
		}
	}
	
	/**
		Fires the request to the url inside the text area

		- Parameters:
			- passType: the passType to be joined to the urlString
	*/
	
	func connect(_ passType : String) {
		var urlPass : String = ""

		guard !(self.urlField.text?.isEmpty)! else {
			self.resultArea.text = errorsDict["missingURL"]
			self.resultAreaView.isHidden = false
			self.resultArea.isHidden = false
			self.fetchBtn.isEnabled = true
			return
		}

		urlPass += "\(self.trimSpecialCharacters(in: urlField!.text!))"

		if !portCheck(in: urlField!.text!) {
			urlPass += ":80"
		}

		UserDefaults.standard.set(urlPass, forKey: "lastAddress")
		
		if !protocolCheck(in: urlField!.text!) {
			urlPass = "http://\(urlPass)"
		}

		urlPass += "/gen/\(passType)"

		self.connectingLabel.text = "Connecting to \(urlPass)"
		self.connectingLabel.isHidden = false

		let urlAddress : URL = URL(string: urlPass)!
		let session = URLSession.shared
		var requestURL = URLRequest(url: urlAddress)
		
		requestURL.httpMethod = "POST"
		requestURL.allHTTPHeaderFields = [
			"Content-Type": "application/json"
		]

		let parameters : wspassParameters = wspassParameters(
			serialNumber: "AAAA7726372",
			location: [
				wspassLocation(long: 5.0, lat: 10.5),
				wspassLocation(long: 3322.14, lat: 25.3)
			]
		)
		
		do {
			let encoder = JSONEncoder()
			let jsonData = try encoder.encode(parameters)
			requestURL.httpBody = jsonData
		} catch {
			self.resultArea.text = self.errorsDict["misJSONEncoding"]
			self.resultAreaView.isHidden = false
			self.resultArea.isHidden = false
			self.fetchBtn.isEnabled = true
			return
		}
		
		session.dataTask(with: requestURL) { (data, res, error) in
			DispatchQueue.main.async {
				guard error == nil else {
					self.resultArea.text = self.errorsDict["noConn"]?.replacingOccurrences(of: "%s", with: error!.localizedDescription)
					self.resultArea.isHidden = false
					self.resultAreaView.isHidden = false
					self.fetchBtn.isEnabled = true
					return
				}

				let contentType = (
					(res as! HTTPURLResponse).allHeaderFields["Content-Type"] as! String).split(separator: ";")[0]

				if contentType == "application/vnd.apple.pkpass" {
					// if the response has MIME application/vnd.apple.pkpass, it means that generation should be correct.
					
					do {
						let pass = try PKPass(data: data!)
						
						guard PKPassLibrary.isPassLibraryAvailable() else {
							self.resultArea.text = self.errorsDict["noLib"]
							self.resultArea.isHidden = false
							self.fetchBtn.isEnabled = true
							return
						}
						
						if (PKPassLibrary().containsPass(pass)) {
							self.resultArea.text = self.errorsDict["alreadyAvailable"]
							self.resultArea.isHidden = false
							self.fetchBtn.isEnabled = true
							return
						}

						// I present a PassKitViewController containing the downloaded pass
						let passvc = PKAddPassesViewController(pass: pass)!
						self.present(passvc, animated: true) {
							self.passData = pass;

							if self.fetchBtn.title(for: .normal) == "Fetch Pass" {
								self.fetchBtn.setTitle("Fetch Pass Again", for: .normal)
							}

							self.resultArea.text = "Done!"
							self.viewDetailsBtn.isHidden = false
						}
					} catch {
						self.resultArea.text = self.errorsDict["misBuffer"]
					}
				} else if contentType == "application/json" {
					// To be written if server returns a JSON structure. Requires structs to be added inside structs.swift
					do {
						// let result = JSONDecoder().decode(<< decode structure >>, from: data!)
						// self.resultArea.text = << Your content >>
					} catch {
						self.resultArea.text = "Returned JSON error (not parsable at the moment)";
					}
				} else {
					self.resultArea.text = String(data: data!, encoding: .utf8)
				}
				
				self.resultAreaView.isHidden = false
				self.resultArea.isHidden = false
				self.fetchBtn.isEnabled = true
			}
		}.resume()
	}
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return self.passTypes.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return passTypes[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		self.selectedPassType = self.passTypes[pickerView.selectedRow(inComponent: component)]
	}
}

