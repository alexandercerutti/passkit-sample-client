//
//  ViewController.swift
//  PassRequester
//
//  Created by Alexander Cerutti on 08/05/18.
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import UIKit
import PassKit

class ViewController: UIViewController {

	let passTypes : [String] = ["eventTicket", "boardingPass", "coupon", "generic", "storeCard"]
	var passData : PKPass? = nil
	var selectedPassType : String? = nil
	
	@IBOutlet weak var passTypePickerView: UIPickerView!
	@IBOutlet weak var urlField: UITextField!
	@IBOutlet weak var connectingLabel: UILabel!
	@IBOutlet weak var resultArea: UITextView!
	@IBOutlet weak var viewDetailsBtn: UIButton!
	@IBOutlet weak var fetchBtn: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.passTypePickerView.delegate = self
		self.passTypePickerView.dataSource = self
		self.urlField.delegate = self

		self.selectedPassType = self.passTypes[0]

		// for testing:
		urlField.text = "192.168.1.254"

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
		Sends the request to the url inside the text area
	
		- Parameters:
			- sender: the trigger element (may be, e.g. the touch event)
	
		- returns: The result of operation
	*/

	@IBAction func fireRequest(_ sender: Any) {
		self.resultArea.isHidden = true
		self.viewDetailsBtn.isHidden = true
		self.fetchBtn.isEnabled = false

		guard !(self.urlField.text?.isEmpty)! else {
			self.resultArea.text = "Insert a Passkit Webserver URL to proceed."
			self.resultArea.isHidden = false
			self.fetchBtn.isEnabled = true
			return
		}

		var urlPass : String = ""

		if !protocolCheck(in: urlField!.text!) {
			urlPass += "http://"
		}

		urlPass += "\(self.trimSpecialCharacters(in: urlField!.text!)):80/gen/\(selectedPassType!)"

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
			self.resultArea.text = "Unable to encode JSON in http body."
			self.resultArea.isHidden = false
			self.fetchBtn.isEnabled = true
			return
		}
		
		session.dataTask(with: requestURL) { (data, res, error) in
			DispatchQueue.main.async {
				guard error == nil else {
					self.resultArea.text = "\(error?.localizedDescription as! String) Check also the inserted URL/IP."
					self.resultArea.isHidden = false
					self.fetchBtn.isEnabled = true
					return
				}

				if data != nil {
					do {
						// I check if the retrieved buffer can be parsed as JSON Structure
						// If decoding fails, .pkpass is returned, error from server otherwise.

						let decoder = JSONDecoder()
						let result = try decoder.decode(serverMessageError.self, from: data!)

						self.resultArea.text = result.error.message
						self.resultArea.isHidden = false
						self.fetchBtn.isEnabled = true
					} catch {
						let pass = PKPass(data: data!, error: nil)
						let lib = PKPassLibrary()

						guard PKPassLibrary.isPassLibraryAvailable() else {
							self.resultArea.text = "Pass Library is not available."
							self.resultArea.isHidden = false
							self.fetchBtn.isEnabled = true
							return
						}

						if (lib.containsPass(pass)) {
							self.resultArea.text = "Library already contains this pass."
							self.resultArea.isHidden = false
							self.fetchBtn.isEnabled = true
							return
                        }
						
						// I present a PassKitViewController containing the downloaded pass
						let passvc = PKAddPassesViewController(pass: pass)
						self.present(passvc, animated: true) {
							self.passData = pass;
							if self.fetchBtn.title(for: .normal) == "Fetch Pass" {
								self.fetchBtn.setTitle("Fetch Pass Again", for: .normal)
							}
							self.resultArea.text = "Done!"

							self.fetchBtn.isEnabled = true
							self.viewDetailsBtn.isHidden = false
							self.resultArea.isHidden = false
						}
					}
				}
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
