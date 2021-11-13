//
//  RoundImageView.swift
//  Tinodios
//
//  Copyright © 2019 Tinode. All rights reserved.
//

// Implementation of a circular image view with either an image or letters

import TinodeSDK
import UIKit

@IBDesignable class RoundImageView: UIImageView {
    internal enum Constants {
        static let kForegroundColorDark = UIColor(red: 0xDE/255, green: 0xDE/255, blue: 0xDE/255, alpha: 1.0)
        static let kForegroundColorLight = UIColor.white
    }

    public enum IconType {
        case p2p, grp, none

        init(from: String) {
            switch from {
            case "p2p": self = .p2p
            case "grp": self = .grp
            default: self = .none
            }
        }
    }

    // MARK: - Properties
    public var iconType: IconType = .none {
        didSet {
            updateDefaultIcon()
        }
    }

    /// Element to set default icon type when no other info is provided: "grp" or "p2p".
    @IBInspectable public var defaultType: String? {
        didSet {
            guard let tp = defaultType else { return }
            iconType = IconType(from: tp)
        }
    }

    public var initials: String? {
        didSet {
            setImageFrom(initials: initials)
        }
    }

    public var letterTileFont: UIFont = UIFont.preferredFont(forTextStyle: .caption1) {
        didSet {
            setImageFrom(initials: initials)
        }
    }

    public var letterTileTextColor: UIColor = .white {
        didSet {
            setImageFrom(initials: initials)
        }
    }

    private var radius: CGFloat?

    // MARK: - Overridden Properties
    override var frame: CGRect {
        didSet {
            setCornerRadius()
        }
    }

    override var bounds: CGRect {
        didSet {
            setCornerRadius()
            if let initials = initials {
                // Rescale letters on size changes.
                image = getImageFrom(initials: initials)
            }
        }
    }

    // MARK: - Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepareView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareView()
    }

    convenience public init() {
        self.init(frame: .zero)
    }

    convenience public init(icon: UIImage?, title: String?, id: String?) {
        self.init(frame: .zero)
        self.set(icon: icon, title: title, id: id)
    }

    public func set(icon: UIImage?, title: String?, id: String?) {
        if let icon = icon {
            // Avatar image provided.
            self.image = icon
            // Clear background color.
            self.backgroundColor = nil
        } else {
            if let id = id, !id.isEmpty {
                switch Tinode.topicTypeByName(name: id) {
                case .p2p: iconType = .p2p
                case .grp: iconType = .grp
                default: break
                }
            }

            if let title = title, !title.isEmpty {
                // No avatar image but have avatar name, show initial.
                self.letterTileFont = UIFont.preferredFont(forTextStyle: .title2)
                let (fg, bg) = RoundImageView.selectBackground(id: id, dark: iconType == .p2p)
                self.letterTileTextColor = fg
                self.backgroundColor = bg

                self.initials = String(title[title.startIndex]).uppercased()
            } else {
                // Placeholder image
                updateDefaultIcon()
                self.backgroundColor = nil
            }
        }
    }

    public func setIconType(_ type: IconType) {
        self.iconType = type
    }

    private static func selectBackground(id: String?, dark: Bool = false) -> (UIColor, UIColor) {
        guard let id = id else {
            return (UIColor.white, UIColor.gray)
        }

        let bgColor = UiUtils.letterTileColor(for: id, dark: dark)
        return (dark ? Constants.kForegroundColorDark : Constants.kForegroundColorLight, bgColor)
    }

    private func setImageFrom(initials: String?) {
        guard let initials = initials else { return }
        image = getImageFrom(initials: initials)
    }

    private func getImageFrom(initials: String) -> UIImage {
        let width = frame.width
        let height = frame.height
        if width == 0 || height == 0 { return UIImage() }
        var font = letterTileFont

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!

        let textRect = calcTextRect(outerViewWidth: width)
        // Maybe adjust font size to make sure the text fits inside the circle.
        font = adjustFontSize(text: initials, font: font, width: textRect.width, height: textRect.height)

        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        let textFontAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: letterTileTextColor, NSAttributedString.Key.paragraphStyle: textStyle]

        let textTextHeight: CGFloat = initials.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: textRect)
        initials.draw(in: CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight), withAttributes: textFontAttributes)
        context.restoreGState()

        guard let renderedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            assertionFailure("Could not create image from context")
            return UIImage()
        }
        return renderedImage
    }

    // Find the biggest font to fit the text with the given width and height.
    // If no adjustment is needed, returns the original font.
    private func adjustFontSize(text: String, font: UIFont, width: CGFloat, height: CGFloat) -> UIFont {
        var attributedText = NSAttributedString(string: text, attributes: [.font: font])
        var newFont = font
        while attributedText.width(considering: height) > width {
            newFont = font.withSize(newFont.pointSize / 1.25)
            attributedText = NSAttributedString(string: text, attributes: [.font: newFont])
        }
        return newFont
    }

    // Calculate the size of the square which fits inside the cirlce of the given diameter.
    private func calcTextRect(outerViewWidth diameter: CGFloat) -> CGRect {
        let size = diameter * 0.70710678118 // = sqrt(2) / 2
        let offset = diameter * 0.1464466094 // (1 - sqrt(2) / 2) / 2
        // In case the font exactly fits to the region, put 2 pixels both left and right
        return CGRect(x: offset+2, y: offset, width: size-4, height: size)
    }

    private func prepareView() {
        backgroundColor = .gray
        contentMode = .scaleAspectFill
        layer.masksToBounds = true
        clipsToBounds = true
        setCornerRadius()
        updateDefaultIcon()
    }

    private func updateDefaultIcon() {
        let icon: UIImage?
        switch iconType {
        case .p2p: icon = UIImage(named: "user-96")
        case .grp: icon = UIImage(named: "group-96")
        default: icon =  nil
        }
        self.image = icon
    }

    private func setCornerRadius() {
        layer.cornerRadius = min(frame.width, frame.height)/2
    }
}

// These extensions are needed for selecting the color of avatar background
fileprivate extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter {$0.isASCII}.first?.value
    }
}

fileprivate extension String {
    // ASCII array to map the string
    var asciiArray: [UInt32] {
        return unicodeScalars.filter {$0.isASCII}.map {$0.value}
    }
}

extension String {
    // hashCode produces output equal to the Java hash function.
    func hashCode() -> Int32 {
        var hash: Int32 = 0
        for i in self.asciiArray {
            hash = 31 &* hash &+ Int32(i) // Be aware of overflow operators,
        }
        return hash
    }
}

extension NSAttributedString {
    internal func width(considering height: CGFloat) -> CGFloat {
        let constraintBox = CGSize(width: .greatestFiniteMagnitude, height: height)
        let rect = self.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return rect.width
    }
}
