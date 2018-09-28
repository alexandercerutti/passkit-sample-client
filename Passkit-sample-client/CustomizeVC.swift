//
//  CustomizeViewController.swift
//  Passkit-sample-client
//
//  Created by Alexander Cerutti on 23/09/18.
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import UIKit

protocol OptionsProto : class {
	func confirmEdits(_ overrides: [String : String])
}

class CustomizeVC: UIViewController {
	weak var delegate: OptionsProto?
	@IBOutlet weak var tableView: UITableView!
	var overrides: [String : String] = [:]
	
	private let tableViewKeys = ["serialNumber", "userInfo", "webServiceURL", "backgroundColor", "foregroundColor", "labelColor", "groupingIdentifier"];
	
	private var selectedKey : String?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.tableView.delegate = self
		self.tableView.dataSource = self
		
		overrides = tableViewKeys.reduce([String : String]()) {
		(dict, val) -> [String: String] in
			var ovv = dict
			if let v = UserDefaults.standard.value(forKey: val) as? String {
				ovv[val] = v
			}
			return ovv
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		// Executing delegate only if overrides has at least one value
		let ovvalues = Array(overrides.keys)
		if ovvalues.count != 0 {
			self.delegate?.confirmEdits(overrides)
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Passing the title and the previously inserted infos (overrides)
		
		if let editView = segue.destination as? editVC {
			editView.delegate = self
			editView.title = self.selectedKey
			
			if let valueForThisKey = overrides[self.selectedKey!] {
				editView.actualContent = valueForThisKey
			}
		}
	}
}

extension CustomizeVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.tableViewKeys.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "overrideCell", for: indexPath)

		cell.textLabel?.text = self.tableViewKeys[indexPath.row]
		
		return cell
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return CGFloat(65);
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.selectedKey = self.tableViewKeys[indexPath.row]
		performSegue(withIdentifier: "editSegue", sender: nil)
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension CustomizeVC : afterEdit {
	func didFinishEditingField(_ value: String, forKey: String) {
		// setting a default serial number if its value is nil
		
		if !value.isEmpty {
			UserDefaults.standard.set(value, forKey: forKey)
			self.overrides[forKey] = value
		} else if forKey == "serialNumber" {
			self.overrides[forKey] = "0000-1111111-222-3-4444444-55555-6"
		}
	}
}
