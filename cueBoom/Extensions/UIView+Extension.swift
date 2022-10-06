//
//  UIView+Extension.swift
//  visitsurvey
//
//  Created by AngelDev on 1/20/21.
//

import Foundation
import UIKit

extension NSObject {
    
    class var nameOfClass: String {
        return NSStringFromClass(self).components(separatedBy: ".").last! as String
    }
}

extension UIView {
    
    func createDottedLine(width: CGFloat, color: CGColor) {
        let caShapeLayer = CAShapeLayer()
        caShapeLayer.strokeColor = color
        caShapeLayer.lineWidth = width
        caShapeLayer.lineDashPattern = [2,3]
        let cgPath = CGMutablePath()
        let cgPoint = [CGPoint(x: 0, y: 0), CGPoint(x: self.frame.width, y: 0)]
        cgPath.addLines(between: cgPoint)
        caShapeLayer.path = cgPath
        layer.addSublayer(caShapeLayer)
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    class func NibObject() -> UINib {
        let hasNib: Bool = Bundle.main.path(forResource: self.nameOfClass, ofType: "nib") != nil
        guard hasNib else {
            assert(!hasNib, "Invalid parameter") // assert
            return UINib()
        }
        return UINib(nibName: self.nameOfClass, bundle:nil)
    }
    
    
    class func fromNib<T : UIView>(nibNameOrNil: String? = nil) -> T {
        let v: T? = fromNib(nibNameOrNil: nibNameOrNil)
        return v!
    }
    
    class func fromNib<T : UIView>(nibNameOrNil: String? = nil) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            // Most nibs are demangled by practice, if not, just declare string explicitly
            name = "\(T.self)".components(separatedBy: ".").last!
        }
        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
        for v in nibViews! {
            if let tog = v as? T {
                view = tog
            }
        }
        return view
    }

    // MARK: Frame of UIView - do not touch
    var width: CGFloat {
        get { return self.frame.size.width }
        set {
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    var height: CGFloat {
        get { return self.frame.size.height }
        set {
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    var size: CGSize  {
        get { return self.frame.size }
        set {
            var frame = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
    
    var origin: CGPoint {
        get { return self.frame.origin }
        set {
            var frame = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }
    
    var x: CGFloat {
        get { return self.frame.origin.x }
        set {
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    
    var y: CGFloat {
        get { return self.frame.origin.y }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    var centerX: CGFloat {
        get { return self.center.x }
        set {
            self.center = CGPoint(x: newValue, y: self.centerY)
        }
    }
    
    var centerY: CGFloat {
        get { return self.center.y }
        set {
            self.center = CGPoint(x: self.centerX, y: newValue)
        }
    }
    
    var top : CGFloat {
        get { return self.frame.origin.y }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    var bottom : CGFloat {
        get { return frame.origin.y + frame.size.height }
        set {
            var frame = self.frame
            frame.origin.y = newValue - self.frame.size.height
            self.frame = frame
        }
    }
    
    var right : CGFloat {
        get { return self.frame.origin.x + self.frame.size.width }
        set {
            var frame = self.frame
            frame.origin.x = newValue - self.frame.size.width
            self.frame = frame
        }
    }
    
    var left : CGFloat {
        get { return self.frame.origin.x }
        set {
            var frame = self.frame
            frame.origin.x  = newValue
            self.frame = frame
        }
    }
    
    func origin (_ point : CGPoint) {
        frame.origin.x = point.x
        frame.origin.y = point.y
    }
    
    func bindToKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIView.keyboardWillChange(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    func unbindToKeyboard() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc func keyboardWillChange(notification: Notification) {
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        let curFrame = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue: curve), animations: {
            self.frame.origin.y += deltaY
        })
    }
    
    @IBInspectable var shadowColor: UIColor?{
        set {
            guard let uiColor = newValue else { return }
            layer.shadowColor = uiColor.cgColor
        }
        get{
            guard let color = layer.shadowColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    @IBInspectable var shadowOpacity: Float{
        set { layer.shadowOpacity = newValue }
        get{ return layer.shadowOpacity }
    }
    
    @IBInspectable var shadowOffset: CGSize{
        set { layer.shadowOffset = newValue }
        get { return layer.shadowOffset }
    }
    
    @IBInspectable var shadowRadius: CGFloat{
        set { layer.shadowRadius = newValue }
        get{ return layer.shadowRadius }
    }
    
    //set selected corner only
    //ex : ui_viewTxt.roundCornersWithLayerMask(cornerRadius: 10, corners: [.topRight, .bottomLeft, .bottomRight])
    func roundCornersWithLayerMask(cornerRadius: CGFloat, corners: UIRectCorner) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
    
    func visiblity(gone: Bool, dimension: CGFloat = 0.0, attribute: NSLayoutConstraint.Attribute = .height) -> Void {
        if let constraint = (self.constraints.filter{$0.firstAttribute == attribute}.first) {
            constraint.constant = gone ? 0.0 : dimension
            self.layoutIfNeeded()
            self.isHidden = gone
        }
    }
    
    func addTapGesture(tapNumber: Int, target: Any, action: Selector) {
        let tap = UITapGestureRecognizer(target: target, action: action)
        tap.numberOfTapsRequired = tapNumber
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    func fadeOut(_ duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
    func fadeIn(_ duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
}
