//  structs.swift
//  Passkit-sample-client
//
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import Foundation


//struct wspassParameters : Encodable {
//	let serialNumber: String? = "00000-11111111-2222222-333-444-6"
//	let userInfo: String? = nil
//	let webServiceURL: String? = nil
//	let backgroundColor: String? = nil
//	let foregroundColor: String? = nil
//	let labelColor: String? = nil
//	let groupingIdentifier: String? = nil
//	
//	subscript(name: String) {
//		
//	}
//}

struct wspassLocation : Encodable {
	let longitude: Double
	let latitude: Double
	var altitude: Double? = nil
	var relevantText: String? = nil

	init(long longitude: Double, lat latitude: Double) {
		self.longitude = longitude
		self.latitude = latitude
	}
	
	init(long longitude: Double, lat latitude: Double, altitude: Double) {
		self.longitude = longitude
		self.latitude = latitude
		self.altitude = altitude
	}
}

enum BarcodeFormat : String, Encodable {
	case qr = "PKBarcodeFormatQR"
	case pdf417 = "PKBarcodeFormatPDF417"
	case aztec = "PKBarcodeFormatAztec"
	case code128 = "PKBarcodeFormatCode128"
}

struct wspassBarcode : Encodable {
	let format: BarcodeFormat
	let message: String
	let messageEncoding: String
	let altText: String?
}


