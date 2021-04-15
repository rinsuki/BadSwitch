//
//  BadAppleData.swift
//  BadMac
//
//  Created by user on 2021/01/12.
//

import Foundation

struct BadAppleData: Decodable {
    let width: Int
    let height: Int
    let fps: Int
    let frames: [String]
    private(set) var url: URL!
    
    init(url: URL) throws {
        let metadata = try Data(contentsOf: url.appendingPathComponent("meta.json"))
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: metadata)
        self.url = url
    }
}
