//
//  WidgetColor.swift
//  testWidget
//
//  Created by wxiaopang on 2024/4/23.
//

import Foundation
import SwiftUI

@available(iOS 13.0, *)
extension Color {
    
    //#ARGB
    init?(hexString: String) {
        var hex = hexString;
        guard hexString.starts(with: "#") else {
            return nil
        }
        hex.remove(at: hexString.startIndex)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        var a = 0xFF / 255.0
        if hex.count > 7 {
            a = Double(value >> 24) / 255.0
        }
        let r = Double((value & 0xFF0000) >> 16) / 255.0;
        let g = Double((value & 0xFF00) >> 8) / 255.0;
        let b = Double(value & 0xFF) / 255.0
        self.init(red: Double(r), green: Double(g), blue: Double(b))
        _ = self.opacity(Double(a))
    }
}

