//  structs.swift
//  Passkit-sample-client
//
//  Copyright © 2018 Alexander Cerutti. All rights reserved.
//

import Foundation

struct wspassParameters : Encodable {
	let serialNumber: String
	let location: [wspassLocation]?
}

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
	
	init(long longitude: Double, lat latitude: Double, altitude: Double, relevantText: String) {
		self.longitude = longitude
		self.latitude = latitude
		self.altitude = altitude
		self.relevantText = relevantText
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


