//
//  DetailsModalVCViewController.swift
//  Passkit-sample-client
//
//  Created by Alexander Cerutti on 19/08/18.
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import UIKit
import PassKit

class DetailsModalVC: UIViewController {

	@IBOutlet weak var detailList: UITableView!

	let passFields : [[String]] = [
		["webServiceURL", "authenticationToken"],
		["serialNumber", "relevantDate", "passType", "localizedName", "localizedDescription"],
		["organizationName", "passTypeIdentifier", "isRemotePass", "deviceName"]
	]

	let passHeaders : [String] = ["Update Details", "Pass Info", "Generic Info"]

	var passData : PKPass? = nil

	override func viewDidLoad() {
		super.viewDidLoad()

		guard passData != nil else {
			print("Unable to proceed. Pass Data is nil.")
			return
		}

		self.detailList.delegate = self
		self.detailList.dataSource = self
	}
}

extension DetailsModalVC : UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.passFields[section].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cellModelSubtitle", for: indexPath)
		
		let key : String = passFields[indexPath.section][indexPath.row]
		var dataString : String? = nil
		
		if let data = passData?.value(forKey: key) {
			if data is String {
//				print("[DEBUG] \(key) is String: \(data as! String)")
				dataString = data as? String
			} else if data is URL {
//				print("[DEBUG] \(key) is URL: \(data as! URL)")
				dataString = (data as! URL).absoluteString
			} else if data is UInt && key == "passType" {
//				print("[DEBUG] \(key) can be converted as UInt")
				dataString = ["Barcode", "Payment", "Any"][data as! Int]
			} else if data is Bool {
				dataString = (data as! Bool).description
			}
		}
		
		cell.textLabel?.text = key
		cell.detailTextLabel?.text = dataString ?? "n/a"
		
		return cell
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.passHeaders[section]
	}
}
