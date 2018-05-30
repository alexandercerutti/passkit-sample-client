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
	var selectedPassType : String? = nil
	
	@IBOutlet weak var passTypePickerView: UIPickerView!
	@IBOutlet weak var urlField: UITextField!
	@IBOutlet weak var connectingLabel: UILabel!
	@IBOutlet weak var resultArea: UITextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.passTypePickerView.delegate = self
		self.passTypePickerView.dataSource = self
		
		self.selectedPassType = self.passTypes[0]
	}
	
	// MARK: - Custom Functions
	
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

		guard !(self.urlField.text?.isEmpty)! else {
			self.resultArea.text = "Insert a Passkit Webserver URL to proceed."
			self.resultArea.isHidden = false
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
			return
		}
		
		session.dataTask(with: requestURL) { (data, res, error) in
			DispatchQueue.main.async {
				guard error == nil else {
					print(error?.localizedDescription)
					return
				}

				if data != nil {
					do {
						// I check if the retrieved buffer can be parsed as JSON Structure
						// If decoding fails, .pkpass is returned, error from server otherwise.

						let decoder = JSONDecoder()
						let result = try decoder.decode(serverMessageError.self, from: data!)
						print(result)
					
						self.resultArea.text = result.message
						self.resultArea.isHidden = false
						
					} catch {
						let pass = PKPass(data: data!, error: nil)
						let lib = PKPassLibrary()
						
						print("Serial Number: \(pass.serialNumber)")
						guard PKPassLibrary.isPassLibraryAvailable() else {
							self.resultArea.text = "Pass Library is not available."
							self.resultArea.isHidden = false
							return
						}

						if (lib.containsPass(pass)) {
							self.resultArea.text = "Library already contains this pass."
							self.resultArea.isHidden = false
							return
						}
						
						self.resultArea.text = "Fetching..."
						self.resultArea.isHidden = false

						
						// I present a PassKitViewController containing the downloaded pass
						let passvc = PKAddPassesViewController(pass: pass)
						self.present(passvc, animated: true) {
							self.resultArea.text = "Done!"
						}
					}
				}
			}
		}.resume()
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