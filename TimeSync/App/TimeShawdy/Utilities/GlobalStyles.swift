//
//  GlobalColors.swift
//  TimeShawdy
//
//  Created by Hunter Deibler on 2/19/24.
//

import SwiftUI

struct GlobalColors {
    static let darkblue_heading1 = Color(hex: "#072835")
    static let lightblue_heading2 = Color(hex: "#074C62")
    static let blue_highlight1 = Color(hex: "#C1DDDE")
    static let darkorange_highlight2 = Color(hex: "#D9780B")
    static let lightorange_highlight3 = Color(hex: "#E9BB88")
    

}


struct GlobalFonts {
    static func mainHeading(size: CGFloat) -> Font {
        Font.custom("Montserrat-Black", size: size).italic()
        
    }
    
    static func subHeading(size: CGFloat, italic: Bool = false) -> Font {
        let fontName = italic ? "Montserrat-SemiBoldItalic" : "Montserrat-SemiBold"
        return Font.custom(fontName, size: size)
    }
    
    static func body(size: CGFloat) -> Font {
        Font.custom("Poppins-Regular", size: size)
    }
}






extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}




extension UIColor {
    static let darkblueHeading1 = UIColor(hex: "#072835")
    static let lightblueHeading2 = UIColor(hex: "#074C62")
    static let blueHighlight1 = UIColor(hex: "#C1DDDE")
    static let darkorangeHighlight2 = UIColor(hex: "#D9780B")
    static let lightorangeHighlight3 = UIColor(hex: "#E9BB88")
    

    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])

        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                a = CGFloat(hexNumber & 0x000000ff) / 255
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }

        return nil
    }
}

// Conversion of GlobalFonts to UIFont
extension UIFont {
    static func mainHeading(size: CGFloat) -> UIFont {
        return UIFont(name: "Montserrat-BlackItalic", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func subHeading(size: CGFloat, italic: Bool = false) -> UIFont {
        let fontName = italic ? "Montserrat-SemiBoldItalic" : "Montserrat-SemiBold"
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func body(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}
