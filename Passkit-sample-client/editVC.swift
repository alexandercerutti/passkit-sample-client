//
//  editVC.swift
//  Passkit-sample-client
//
//  Created by Alexander Cerutti on 25/09/18.
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import UIKit

protocol afterEdit: class {
	func didFinishEditingField(_ value: String, forKey: String)
}

class editVC: UIViewController {
	weak var delegate: afterEdit?
	@IBOutlet weak var textView: UITextView!
	var actualContent : String?

    override func viewDidLoad() {
        super.viewDidLoad()

		if actualContent != nil {
			self.textView.text = actualContent
		}

		self.textView.becomeFirstResponder()
	
		self.textView.layer.borderColor = UIColor.orange.cgColor
		self.textView.layer.borderWidth = 1
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		delegate?.didFinishEditingField(textView.text, forKey: self.title!)
	}
}
