//
//  TermsLabel.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/5/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

protocol TermsLabelDelegate: class {
    func labelWasTappedForUsername(_ username: String)
}
import UIKit

class TermsLabel: UILabel {
    private var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    weak var tapDelegate: TermsLabelDelegate?
    
    var stringsToDetect: [String] = ["Terms of Use", "Privacy Policy"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        isUserInteractionEnabled = true
        
        lineBreakMode = .byWordWrapping
        tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(handleLabelTap(recognizer:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.isEnabled = true
        addGestureRecognizer(tapGesture)
        
        //Style the labels attributed text
        let chunk1 = getBaseAttributedString(string: "By proceeding you agree to CueBoom’s ")
        let chunk2 = getBaseAttributedString(string: " and acknowledge you have read the ")
        
        let termsOfUse = getBaseAttributedString(string: "Terms of Use")
        termsOfUse.underline()
        
        let privacyPolicy = getBaseAttributedString(string: "Privacy Policy.")
        privacyPolicy.underline()

        let finalString = NSMutableAttributedString()
        finalString.append(chunk1)
        finalString.append(termsOfUse)
        finalString.append(chunk2)
        finalString.append(privacyPolicy)
        
        self.attributedText = finalString

        
    }
    
    func getBaseAttributedString(string: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    
    
    @objc func handleLabelTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: self)
        let tapIndex = indexOfAttributedTextCharacterAtPoint(point: tapLocation)
        
        for str in stringsToDetect {
            if let ranges = self.attributedText?.rangesOf(subString: str) {
                for range in ranges {
                    if tapIndex > range.location + 10 && tapIndex < range.location + range.length + 10 {
                        tapDelegate?.labelWasTappedForUsername(str)
                        return
                    }
                }
            }
        }
    }
    
    func indexOfAttributedTextCharacterAtPoint(point: CGPoint) -> Int {
        guard let attributedString = self.attributedText else { return -1 }
        
        let mutableAttribString = NSMutableAttributedString(attributedString: attributedString)
        // Add font so the correct range is returned for multi-line labels
        mutableAttribString.addAttributes([NSAttributedString.Key.font: font], range: NSRange(location: 0, length: attributedString.length))
        
        let textStorage = NSTextStorage(attributedString: mutableAttribString)
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: frame.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return index
    }
}

extension NSAttributedString {
    func rangesOf(subString: String) -> [NSRange] {
        var nsRanges: [NSRange] = []
        let ranges = string.ranges(of: subString, options: .caseInsensitive, locale: nil)
        
        for range in ranges {
            nsRanges.append(NSRange(range, in: subString))
        }
        
        return nsRanges
    }
}

extension NSMutableAttributedString {
    func underline(){
        self.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, self.length))
    }
}

extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex) ..< self.endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }
}
