// swiftlint:disable all
//
//  Created by Manuel Vrhovac on 10/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//


import Foundation
import UIKit

public extension UIImage {
    
    func calculatePNGRepresentationMemorySizeInKB() -> Int {
        if let imageData = self.pngData() {
            let bytes = imageData.count
            return Int(bytes) / 1000
        }
        return 0
    }
    
    var template: UIImage {
        return self.withRenderingMode(.alwaysTemplate)
    }
    
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets
    }
    
    
}

public extension UIScrollView {
    
    func scrollToTopMargin(animated: Bool = false) {
        guard animated else {
            contentOffset.y = -self.layoutMargins.top
            return
        }
        UIView.animate(withDuration: 0.4) {
            self.contentOffset.y = -self.layoutMargins.top
        }
    }
    
    func scrollToTopMarginIfOnEdge(animated: Bool = false) {
        let top = -layoutMargins.top
        let zero = (-layoutMargins.top + contentInset.top)
        if contentOffset.y > top && contentOffset.y <= zero  {
            scrollToTopMargin(animated: animated)
        }
    }
    
}

extension UICollectionView {
    var allIndexPaths: [IndexPath] {
        return (0..<numberOfSections).flatMap { section in
            return (0..<numberOfItems(inSection: section)).map { row in
                return IndexPath(row: row, section: section)
            }
        }
    }
    var loadedCells: [UICollectionViewCell] {
        return allIndexPaths.compactMap(self.cellForItem(at:))
    }
    
    func registerNibForCellWith(reuseIdentifier: String, bundle: Bundle) {
        register(.init(nibName: reuseIdentifier,
                       bundle: bundle),
                 forCellWithReuseIdentifier: reuseIdentifier)
    }
}


extension UIImage {
    
    func colorOfPixelAt(x: Int, y: Int) -> UIColor {
        /*x
        if x < 0 || x > Int(size.width) || y < 0 || y > Int(size.height) {
            return nil
        }*/
        
        let provider = self.cgImage!.dataProvider
        let providerData = provider!.data
        let data = CFDataGetBytePtr(providerData)
        
        let numberOfComponents = 4
        let pixelData = ((Int(size.width) * y) + x) * numberOfComponents
        
        let r = CGFloat(data![pixelData]) / 255.0
        let g = CGFloat(data![pixelData + 1]) / 255.0
        let b = CGFloat(data![pixelData + 2]) / 255.0
        let a = CGFloat(data![pixelData + 3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension UIView {
    
    
    func animateShrinkGrow(duration: Double) {
        let oldAlpha = alpha
        UIView.animate(withDuration: duration,
                       delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.0,
                       options: [.autoreverse],
                       animations: {
                        self.transform = .init(scaleX: 0.85, y: 0.85)
                        self.isUserInteractionEnabled = false
                        self.alpha = oldAlpha * 0.8
        }, completion: { _ in
            self.transform = .identity
            self.isUserInteractionEnabled = true
            self.alpha = oldAlpha
        })
    }
    
    var hasVisibleSubviews: Bool {
        return self.subviews.contains(where: {!$0.isHidden})
    }
    
    func hideIfNoVisibleSubviews() {
        self.isHidden = !self.hasVisibleSubviews
    }
    
    var isShown: Bool { get { return !isHidden } set { isHidden = !newValue} }
    
    var allSubviews: [UIView] {
        if self.subviews.count == 0 { return [self] }
        if self is UITextField { return [self] }
        if self is UISlider { return [self] }
        if self is UISegmentedControl { return [self] }
        if self is UIButton { return [self] }
        if self is UILabel { return [self] }
        if self is UISwitch { return [self] }
        let subviews = (self as? UIStackView)?.arrangedSubviews ?? self.subviews
        var all: [UIView] = []
        for sv in subviews {
            all += sv.allSubviews
        }
        return all
    }
    
    func all<T: UIView>(_ viewType: T.Type) -> [T] {
        return UIView.all(viewType, in: self)
    }
    
    var allControls: [UIControl] {
        return all(UIControl.self)
    }
    
    var allSliders: [UISlider] {
        return all(UISlider.self)
    }
    
    var allSwitches: [UISwitch] {
        return all(UISwitch.self)
    }
    
    var allStackViews: [UIStackView] {
        return all(UIStackView.self)
    }
    
    var allTextFields: [UITextField] {
        return all(UITextField.self)
    }
    
    var allLabels: [UILabel] {
        return all(UILabel.self)
    }
    
    var allTextViews: [UITextView] {
        return all(UITextView.self)
    }
    
    var allSegmentedControls: [UISegmentedControl] {
        return all(UISegmentedControl.self)
    }
    
    static func all<T>(_ viewType: T.Type, in mainView: UIView) -> [T] {
        if (T.self == UIStackView.self && mainView is UIStackView) {
            return (mainView as! UIStackView).arrangedSubviews.compactMap { $0 as? T}
        }
        return mainView.allSubviews.compactMap { $0 as? T}
    }
    
    func viewWithRestorationIdentifier(_ id: String) -> UIView? {
        return self.subviews.first(where: {$0.restorationIdentifier == id})
    }
    
    
    func snapToSuperview(side: NSLayoutConstraint.Attribute, constant: CGFloat?, edges: UIEdgeInsets = UIEdgeInsets()) {
        if superview == nil { return }
        snapTo(view: superview!, side: side, constant: constant, edges: edges)
    }
    
    
    func snapTo(view: UIView, side: NSLayoutConstraint.Attribute, constant: CGFloat?, edges: UIEdgeInsets = UIEdgeInsets()) {
        let constants = [edges.top, edges.right, edges.bottom, edges.left]
        let distances = Dictionary(uniqueKeysWithValues: zip(NSLayoutConstraint.Attribute.allSides, constants))
        let snappedDistances = Dictionary(uniqueKeysWithValues: distances.filter { $0.key != side.opposite })
        snapTo(view: view, distances: snappedDistances)
        if let constant = constant { // add width or height
            let widthOrHeightAttribute = side.sizeAttribute
            self.addConstraint(NSLayoutConstraint(
                item: self,
                attribute: widthOrHeightAttribute,
                relatedBy: .equal,
                toItem: nil,
                attribute: widthOrHeightAttribute,
                multiplier: 1.0,
                constant: constant
            ))
        }
    }
    
    func snapToSuperview(insets: UIEdgeInsets) {
        let distances: [NSLayoutConstraint.Attribute: CGFloat] = [
            .bottom: insets.bottom,
            .top: insets.top,
            .left: insets.left,
            .right: insets.right
        ]
        self.snapToSuperview(distances: distances)
    }
    
    func snapToSuperview(distances: [NSLayoutConstraint.Attribute: CGFloat] = [:]) {
        self.snapTo(view: superview, distances: distances)
    }
    
    func snapTo(view: UIView? = nil, distances: [NSLayoutConstraint.Attribute: CGFloat] = [:]) {
        guard let view = view ?? superview else { return }
        var distances = distances
        self.translatesAutoresizingMaskIntoConstraints = false
        if distances.isEmpty {
            let zipped = zip(NSLayoutConstraint.Attribute.allSides, Array(repeating: CGFloat(0), count: 4))
            distances = Dictionary(uniqueKeysWithValues: zipped)
        }
        
        for (attribute, constant) in distances {
            let invert = [.bottom, .right].contains(attribute)
            var existing = view.constraints.first(where: { $0.firstAttribute == attribute })
            if existing == nil {
                existing = NSLayoutConstraint(
                    item: self,
                    attribute: attribute,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: attribute,
                    multiplier: 1.0,
                    constant: constant * (invert ? -1.0 : 1.0)
                )
            }
            view.addConstraint(existing!)
        }
        view.layoutIfNeeded()
    }
    
    func recolorButtonElements(tintColor tint: UIColor? = nil) {
        let t = tint ?? self.tintColor
        for view in self.allSubviews {
            if view is UIButton {
                let button = view as! UIButton
                if button.tintColor == UIColor.clear || button.tintColor == nil { continue }
                guard let image = button.currentBackgroundImage else { continue }
                let colored = image.template
                button.setBackgroundImage(colored, for: .normal)
                button.tintColor = t
            }
        }
    }
    
    var copyView: UIView? {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UIView
    }
}

extension NSLayoutConstraint.Attribute {
    // ordered as in clock 12, 3, 6, 9 (top, trailing, bottom, leading)
    static let allSides: [NSLayoutConstraint.Attribute] = [.top, .trailing, .bottom, .leading]
    var isVertical: Bool { return self == .bottom  || self == .top }
    var isHorizontal: Bool { return self == .leading || self == .trailing }
    var sizeAttribute: NSLayoutConstraint.Attribute { return isVertical ? .height : .width }
    var opposite: NSLayoutConstraint.Attribute {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .trailing: return .leading
        default: return .trailing
        }
    }
    var sideIndex: Int {
        switch self {
        case .top: return 0
        case .trailing: return 1
        case .bottom: return 2
        default: return 3
        }
    }
    
}

extension UIImageView {
    
    func recolorToTint() {
        guard let image = self.image else { return }
        let colored = image.template
        self.image = colored
    }
}

extension UIControl {
    
    func addTargetBlock(for events: UIControl.Event, _ block: @escaping () -> Void) {
        let action1 = ControlAction.init(action: block)
        self.addTarget(action1, action: #selector(action1.action), for: events)
    }
    
    
}

extension UIView {
    
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        return nil
    }
}

extension ProcessInfo {
    
    static var usedRAM: Double {
        var pagesize: vm_size_t = 0
        
        let host_port: mach_port_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(host_port, &pagesize)
        
        var vm_stat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vm_stat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) {
                if (host_statistics(host_port, HOST_VM_INFO, $0, &host_size) != KERN_SUCCESS) {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }
        
        /* Stats in bytes */
        let mem_used: Int64 = Int64(vm_stat.active_count +
            vm_stat.inactive_count +
            vm_stat.wire_count) * Int64(pagesize)
        //let mem_free: Int64 = Int64(vm_stat.free_count) * Int64(pagesize)
        return Double(mem_used)*1E-6
    }
}

public extension CALayer {
    
    func removeShadow() {
        addShadow(.clear, o: 0, r: 0, d: 0)
    }
    
    func addShadow(_ color: UIColor, o: CGFloat, r: CGFloat, d: CGFloat) {
        self.addShadow(color: color, opacity: o, radius: r, distance: d)
    }
    
    func addBorder(_ color: UIColor, width: CGFloat) {
        self.borderColor = color.cgColor
        self.borderWidth = width
    }
    
    func removeBorder() {
        self.borderWidth = 0.0
    }
    
    func addShadow(color: UIColor = .black, opacity: CGFloat, radius: CGFloat, distance: CGFloat) {
        
        //if isSimulator { return }
        //self.removeShadow()
        
        self.shadowColor = color.cgColor
        self.shadowOpacity = Float(opacity)
        self.shadowRadius = radius
        self.shadowOffset = CGSize(width: 0, height: distance)
        self.masksToBounds = false
        
        let rect = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: self.cornerRadius).cgPath
        self.shouldRasterize = true
        self.rasterizationScale = 1
        self.rasterizationScale = UIScreen.main.scale
    }
    
    func addDynamicShadow(color: UIColor = .black, opacity: CGFloat, radius: CGFloat, distance: CGFloat) {
        
        //if isSimulator { return }
        self.shadowColor = color.cgColor
        self.shadowOpacity = Float(opacity)
        self.shadowRadius = radius
        self.shadowOffset = CGSize(width: 0, height: distance)
        //self.masksToBounds = false
    }
    
    func addLabelShadow(color: UIColor, opacity: CGFloat, radius: CGFloat, distance: CGFloat) {
        
        //if isSimulator { return }
        
        self.shadowColor = color.cgColor
        self.shadowOpacity = Float(opacity)
        self.shadowRadius = radius
        self.shadowOffset = CGSize(width: 0, height: distance)
        self.masksToBounds = false
        /*
         let rect = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
         self.shadowPath = UIBezierPath(rect: rect).cgPath
         self.shouldRasterize = true
         self.rasterizationScale = 1
         self.rasterizationScale = UIScreen.main.scale*/
    }
    
    
}

extension CAGradientLayer {
    
    enum Point {
        case topLeft
        case centerLeft
        case bottomLeft
        case topCenter
        case center
        case bottomCenter
        case topRight
        case centerRight
        case bottomRight
        
        var point: CGPoint {
            switch self {
            case .topLeft:
                return CGPoint(x: 0, y: 0)
            case .centerLeft:
                return CGPoint(x: 0, y: 0.5)
            case .bottomLeft:
                return CGPoint(x: 0, y: 1.0)
            case .topCenter:
                return CGPoint(x: 0.5, y: 0)
            case .center:
                return CGPoint(x: 0.5, y: 0.5)
            case .bottomCenter:
                return CGPoint(x: 0.5, y: 1.0)
            case .topRight:
                return CGPoint(x: 1.0, y: 0.0)
            case .centerRight:
                return CGPoint(x: 1.0, y: 0.5)
            case .bottomRight:
                return CGPoint(x: 1.0, y: 1.0)
            }
        }
    }
    
    convenience init(start: Point, end: Point, colors: [UIColor], type: CAGradientLayerType) {
        self.init()
        self.startPoint = start.point
        self.endPoint = end.point
        self.colors = colors.map { $0.cgColor}
        self.locations = (0..<colors.count).map(NSNumber.init)
        self.type = type
    }
}

extension UINavigationItem {
    
    func addRightBarButtonItem(_ item: UIBarButtonItem) {
        if self.rightBarButtonItems == nil {
            self.rightBarButtonItems = []
        }
        self.rightBarButtonItems!.append(item)
    }
    
    func addLeftBarButtonItem(_ item: UIBarButtonItem) {
        if self.leftBarButtonItems == nil {
            self.leftBarButtonItems = []
        }
        self.leftBarButtonItems!.append(item)
    }
    
    func insertRightBarButtonItem(_ item: UIBarButtonItem, at index: Int) {
        if self.rightBarButtonItems == nil {
            self.rightBarButtonItems = []
        }
        self.rightBarButtonItems!.insert(item, at: index)
    }
    
    func insertLeftBarButtonItem(_ item: UIBarButtonItem, at index: Int) {
        if self.leftBarButtonItems == nil {
            self.leftBarButtonItems = []
        }
        self.leftBarButtonItems!.insert(item, at: index)
    }
}

extension UISegmentedControl {
        
    var segmentImageViews: [UIImageView] {
        return subviews.flatMap { $0.subviews }.compactMap { subview in
            if let iv = subview as? UIImageView, let i = iv.image, i.size.width > 5 {
                return iv
            }
            return nil
        }
    }
    
    var imageContentMode: ContentMode {
        get {
            for subview in subviews.flatMap({ $0.subviews }) {
                if let iv = subview as? UIImageView, let i = iv.image, i.size.width > 5 {
                    return iv.contentMode
                }
            }
            return contentMode
        }
        set {
            for subview in subviews.flatMap({ $0.subviews }) {
                if let iv = subview as? UIImageView, let i = iv.image, i.size.width > 5 {
                    iv.contentMode = .scaleAspectFit
                }
            }
        }
    }
    
    func addSegment(with image: UIImage?, animated: Bool) {
        insertSegment(with: image, at: numberOfSegments, animated: animated)
    }

}

/**
 SelfID is a protocol that returns class name and things created using its class name as identifier.
 
 For example, every class has
 - selfID: class name
 - selfBundle: bundle initialized with Self.self as class
 
 View controllers also have:
 - selfNib: Nib initialized with selfID as nibName and selfBundle as bundle
 - initFromStoryboard():
 */
protocol SelfID: class {}

extension SelfID {
    
    static var selfID: String { return "\(Self.self)" }
    var selfID: String { return Self.selfID }
    
    static var selfBundle: Bundle { return .init(for: Self.self as AnyClass) }
    var selfBundle: Bundle { return .init(for: Self.self as AnyClass) }
}

extension SelfID where Self: UIViewController {
    
    //static func fromStoryboard() -> Self! { return Self.initWithStoryboardName(selfID) }
    static var selfNib: UINib { return UINib(nibName: selfID, bundle: selfBundle) }
    static var selfStoryboard: UIStoryboard { return UIStoryboard(type: Self.self) }
}


extension UIViewController: SelfID {}
extension UIView: SelfID {}


extension UIStoryboard {
    
    
    /// Creates a view controller using type's class name as view controller identifier.
    func instantiateVC<T: SelfID>(_ type: T.Type) -> T {
        return instantiateViewController(withIdentifier: T.selfID) as! T
    }
    
    /// Creates a storyboard using type's class name as storyboard name.
    convenience init<T: SelfID>(type: T.Type) {
        self.init(name: type.selfID, bundle: type.selfBundle)
    }
    
    /// Instantiates a view controller using type's class name as both storyboard name and view controller identifier
    static func instantiateVC<T: UIViewController>(_ type: T.Type) -> T {
        return UIStoryboard(type: type).instantiateVC(type)
    }
    
}
