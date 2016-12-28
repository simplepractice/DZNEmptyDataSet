//
//  DZNEmptyDataSet.swift
//  Sample
//
//  Created by Ignacio Romero on 12/18/15.
//  Copyright © 2015 DZN Labs. All rights reserved.
//

import UIKit

public protocol DZNEmptyDataSetSource: NSObjectProtocol {}

extension DZNEmptyDataSetSource {
    func sectionsToIgnore(forEmptyDataSet scrollView: UIScrollView) -> IndexSet? { return nil }

    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? { return nil }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? { return nil }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? { return nil }

    func imageTintColor(forEmptyDataSet scrollView: UIScrollView) -> UIImage? { return nil }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, state: UIControlState) -> NSAttributedString? { return nil }

    func buttonImage(forEmptyDataSet scrollView: UIScrollView, state: UIControlState) -> UIImage? { return nil }

    func buttonBackgroundImage(forEmptyDataSet scrollView: UIScrollView, state: UIControlState) -> UIImage? { return nil }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? { return nil }

    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIImage? { return nil }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView) -> CGFloat { return 0 }

    func spaceHeight(forEmptyDataSet scrollView: UIScrollView) -> CGFloat { return 0 }
}


public protocol DZNEmptyDataSetDelegate: NSObjectProtocol {}

extension DZNEmptyDataSetDelegate {
    func emptyDataSet(shouldDisplay scrollView: UIScrollView) -> Bool { return true }

    func emptyDataSet(shouldAllowTouch scrollView: UIScrollView) -> Bool { return true }

    func emptyDataSet(shouldAllowScroll scrollView: UIScrollView) -> Bool { return true }

    func emptyDataSet(shouldFadeIn scrollView: UIScrollView) -> Bool { return true }

    func emptyDataSet(shouldAnimateImageView scrollView: UIScrollView) -> Bool { return true }

    func emptyDataSet(_ scrollView: UIScrollView, didTapView: UIView) {}

    func emptyDataSet(_ scrollView: UIScrollView, didTapButton: UIButton) {}

    func emptyDataSet(willAppear scrollView: UIScrollView) {}

    func emptyDataSet(didAppear scrollView: UIScrollView) {}

    func emptyDataSet(willDisappear scrollView: UIScrollView) {}

    func emptyDataSet(didDisappear scrollView: UIScrollView) {}
}

// MARK: - UIScrollView extension

extension UIScrollView {
    
    // MARK: - Public Properties
    
    public var emptyDataSetSource: DZNEmptyDataSetSource? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.datasource) as? DZNEmptyDataSetSource
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.datasource, newValue, .OBJC_ASSOCIATION_ASSIGN)
            
            swizzleIfNeeded()
        }
    }
    
    public var emptyDataSetDelegate: DZNEmptyDataSetDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.delegate) as? DZNEmptyDataSetDelegate
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.delegate, newValue, .OBJC_ASSOCIATION_ASSIGN)
            
            swizzleIfNeeded()
        }
    }
    
    // TODO: Not implemented yet
    var isEmptyDataSetVisible: Bool {
        return false
    }
    
    
    // MARK: - Private Properties
    
    fileprivate var didSwizzle: Bool {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.didSwizzle) as? NSNumber
            
            return value?.boolValue ?? false // Returns false if the boolValue is nil.
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.didSwizzle, NSNumber(value: newValue as Bool), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var emptyDataSetView: DZNEmptyDataSetView? {
        get {
            var view = objc_getAssociatedObject(self, &AssociatedKeys.view) as? DZNEmptyDataSetView
            
            if view == nil {
                view = DZNEmptyDataSetView(frame: self.bounds)
                view?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view?.backgroundColor = .clear
                view?.isHidden = false
                
                let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(UIScrollView.didTapView(_:)))
                view?.addGestureRecognizer(tapGesture)
                
                self.emptyDataSetView = view
            }
            
            return view
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.view, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    // MARK: - Public Methods
    
    fileprivate struct AssociatedKeys {
        static var datasource = "emptyDataSetSource"
        static var delegate = "emptyDataSetDelegate"
        static var view = "emptyDataSetView"
        static var didSwizzle = "didSwizzle"
    }
    
    public func reloadEmptyDataSet() {
        
        // Calls the original implementation
        self.reloadEmptyDataSet()
        
        self.invalidateLayout()
        
        guard self.canDisplay && self.shouldDisplay else { return }
        guard let view = self.emptyDataSetView else { return }
        
        print("reloadEmptyDataSet")
        
        var counter = 0
        
        // Configure Image
        if let image = self.topImage, let imageView = view.imageView {
            imageView.image = image;
            view.contentView.addSubview(imageView)
            
            counter += 1
        }
        
        // Configure title label
        if let attributedText = self.attributedTitle, let label = view.titleLabel {
            label.attributedText = attributedText;
            view.contentView.addSubview(label)
            
            counter += 1
        }
        
        // Configure detail label
        if let attributedText = self.attributedDescription, let label = view.detailLabel {
            label.attributedText = attributedText;
            view.contentView.addSubview(label)
            
            counter += 1
        }
        
        // Configure button
        if let attributedText = self.attributedButtonTitle(UIControlState()), let button = view.button {
            button.setAttributedTitle(attributedText, for: UIControlState())
            view.contentView.addSubview(button)
            
            button.addTarget(self, action: #selector(UIScrollView.didTapView(_:)), for: .touchUpInside)
            
            counter += 1
        }
        
        guard counter > 0 else { return }
        
        willAppear()
        
        // Configure the contnet view
        view.isHidden = false
        view.clipsToBounds = true
        view.fadeInOnDisplay = self.shouldFadeIn
        view.verticalOffset = self.verticalOffset

        // Adds subview
        self.addSubview(view)
        
        // Configure the empty dataset view
        self.isScrollEnabled = self.shouldScroll
        self.isUserInteractionEnabled = self.shouldTouch
        self.backgroundColor = self.backgroundColor()
        
        view.setupViewConstraints();
        view.layoutIfNeeded();
        
        didAppear()
    }
    
    // TODO: Add tests
    fileprivate var itemsCount: Int {
        
        var items = 0
        
        guard self.responds(to: #selector(getter: UIPickerView.dataSource)) else { return items }
        
        if let tableView = self as? UITableView {
            guard let sections = tableView.dataSource?.numberOfSections?(in: tableView) else { return items }
            
            for i in 0..<sections where !self.sectionsToIgnore.contains(i) {
                guard let item = tableView.dataSource?.tableView(tableView, numberOfRowsInSection: i) else { continue }
                items += item
            }
        }
        else if let collectionView = self as? UICollectionView {
            guard let sections = collectionView.dataSource?.numberOfSections?(in: collectionView) else { return items }
            
            for i in 0..<sections where !self.sectionsToIgnore.contains(i) {
                guard let item = collectionView.dataSource?.collectionView(collectionView, numberOfItemsInSection: i) else { continue }
                items += item
            }
        }
        
        return items
    }
    
    // TODO: Add tests
    fileprivate var sectionsToIgnore: IndexSet {
        return emptyDataSetSource?.sectionsToIgnore(forEmptyDataSet: self) ?? IndexSet(integer: -1)
    }
    
    fileprivate var attributedTitle: NSAttributedString? {
        return emptyDataSetSource?.title(forEmptyDataSet: self)
    }
    
    fileprivate var attributedDescription: NSAttributedString? {
        return emptyDataSetSource?.description(forEmptyDataSet: self)
    }
    
    fileprivate var topImage: UIImage? {
        return emptyDataSetSource?.image(forEmptyDataSet: self)
    }
    
    fileprivate func attributedButtonTitle(_ state: UIControlState) -> NSAttributedString? {
        return emptyDataSetSource?.buttonTitle(forEmptyDataSet: self, state: state)
    }
    
    fileprivate var verticalOffset: CGFloat {
        return emptyDataSetSource?.verticalOffset(forEmptyDataSet: self) ?? 0
    }
    
    fileprivate func backgroundColor() -> UIColor {
        return emptyDataSetSource?.backgroundColor(forEmptyDataSet: self) ?? .clear
    }
    
    fileprivate var canDisplay: Bool {
        return self.itemsCount > 0 ? false : true
    }
    
    fileprivate var shouldDisplay: Bool {
        return emptyDataSetDelegate?.emptyDataSet(shouldDisplay: self) ?? true
    }
    
    fileprivate var shouldFadeIn: Bool {
        return emptyDataSetDelegate?.emptyDataSet(shouldFadeIn: self) ?? true
    }
    
    fileprivate var shouldScroll: Bool {
        return emptyDataSetDelegate?.emptyDataSet(shouldAllowScroll: self) ?? true
    }
    
    fileprivate var shouldTouch: Bool {
        return emptyDataSetDelegate?.emptyDataSet(shouldAllowTouch: self) ?? true
    }
    
    func didTapView(_ sender: AnyObject?) {
        if let view = sender as? UIView {
            emptyDataSetDelegate?.emptyDataSet(self, didTapView: view)
        } else if let gestureRecognizer = sender as? UIGestureRecognizer, let view = gestureRecognizer.view {
            emptyDataSetDelegate?.emptyDataSet(self, didTapView: view)
        }
    }
    
    func willAppear() {
        emptyDataSetDelegate?.emptyDataSet(willAppear: self)
    }
    
    func didAppear() {
        emptyDataSetDelegate?.emptyDataSet(didAppear: self)
    }
    
    func willDisappear() {
        emptyDataSetDelegate?.emptyDataSet(willDisappear: self)
    }
    
    func didDisappear() {
        emptyDataSetDelegate?.emptyDataSet(didDisappear: self)
    }
    
    fileprivate func invalidateLayout() {
        
        guard let view = self.emptyDataSetView, self.subviews.contains(view) else { return }
        
        willDisappear()
        
        // Cleans up the empty data set view
        self.emptyDataSetView?.removeFromSuperview()
        self.emptyDataSetView = nil
        
        self.isScrollEnabled = true
        
        didDisappear()
    }
    
    
    // MARK: - Swizzling
    
    fileprivate func swizzleIfNeeded() {
        
        if !didSwizzle {
            let newSelector = #selector(UIScrollView.reloadEmptyDataSet)
            
            didSwizzle = swizzle(#selector(UICollectionView.reloadData), swizzledSelector: newSelector)
            
            // TODO: Swizzling works, but whenever we swizzle this other method, it breaks.
            //didSwizzle = swizzle(Selector("endUpdates"), swizzledSelector: newSelector)
        }
    }
    
    fileprivate func swizzle(_ originalSelector: Selector, swizzledSelector: Selector) -> Bool {
        guard self.responds(to: originalSelector) else { return false }
        
        let originalMethod = class_getInstanceMethod(type(of: self), originalSelector)
        let swizzledMethod = class_getInstanceMethod(type(of: self), swizzledSelector)
        
        guard originalMethod != nil && swizzledMethod != nil else { return false }
        
        let targetedMethod = class_addMethod(type(of: self), originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if targetedMethod {
            class_replaceMethod(type(of: self), swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            return true
        }
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            return true
        }
    }
}


// MARK: - DZNEmptyDataSetView
private class DZNEmptyDataSetView: UIView, UIGestureRecognizerDelegate {
    
    var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.alpha = 0
        return view
    }()
    
    lazy var titleLabel: UILabel? = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 27)
        label.textColor = UIColor(white: 0.6, alpha: 1)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.accessibilityLabel = "empty set title"
        return label
    }()
    
    lazy var detailLabel: UILabel? = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor(white: 0.6, alpha: 1)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.accessibilityLabel = "empty set detail label"
        return label
    }()
    
    lazy var imageView: UIImageView? = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = false
        view.accessibilityLabel = "empty set background image"
        return view
    }()
    
    lazy var button: UIButton? = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.accessibilityLabel = "empty set button"
        return button
    }()
    
    var customView: UIView? {
        get {
            return nil
        }
        set {
            if let view = self.customView {
                view.removeFromSuperview()
            }
        }
    }
    
    var verticalOffset: CGFloat?
    var verticalSpace: CGFloat = 0
    
    var fadeInOnDisplay = false
    
    var canShowImage: Bool {
        guard let imageView = self.imageView, imageView.superview != nil else { return false }
        return imageView.image != nil
    }
    
    var canShowTitle: Bool {
        guard let label = self.titleLabel, label.superview != nil else { return false }
        return label.attributedText?.string.characters.count ?? 0 > 0
    }
    
    var canShowDetail: Bool {
        guard let label = self.detailLabel, label.superview != nil else { return false }
        return label.attributedText?.string.characters.count ?? 0 > 0
    }
    
    var canShowButton: Bool {
        guard let button = self.button, button.superview != nil else { return false }
        return button.attributedTitle(for: UIControlState())?.string.characters.count ?? 0 > 0
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.addSubview(contentView)
    }
    
    fileprivate func didTapView(_ sender: UIView) {
        print("didTapView: \(sender)")
    }
    
    fileprivate func didTapView() {
        print("didTapView: \(self)")
    }
    
    override func didMoveToSuperview() {
        
        guard let superview = self.superview else { return }
        self.frame = superview.bounds;
        
        if self.fadeInOnDisplay {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.contentView.alpha = 1
            })
        }
        else {
            self.contentView.alpha = 1
        }
    }
    
    func setupViewConstraints() {
        
        let width = self.frame.width
        let padding = Double(width/16.0)
        let space = self.verticalSpace > 0 ? self.verticalSpace : 11 // Default is 11 pts
        let metrics:[String: Double] = ["padding": padding]

        var views:[String: UIView] = [:]
        var names:[String] = []

        _ = self.addEquallyRelatedConstraint(contentView, attribute: .centerX)
        let centerY = self.addEquallyRelatedConstraint(contentView, attribute: .centerY)
        
        self.addConstraintsWithVisualFormat("|[contentView]|", metrics: nil, views: ["contentView": contentView])

        // When a custom offset is available, we adjust the vertical constraints' constants
        if let offset = self.verticalOffset, offset != 0 {
            centerY.constant = offset
        }
        
        // Assign the image view's horizontal constraints
        if self.canShowImage, let imageView = self.imageView {
            
            let name = "imageView"

            names.append(name)
            views.updateValue(imageView, forKey: name)
            
            _ = contentView.addEquallyRelatedConstraint(imageView, attribute: .centerX)
        }
        
        // Assign the title label's horizontal constraints
        if self.canShowTitle, let label = self.titleLabel {
            
            let name = "titleLabel"

            names.append(name)
            views.updateValue(label, forKey: name)
            
            contentView.addConstraintsWithVisualFormat("|-(padding@750)-[\(name)]-(padding@750)-|", metrics: metrics as [String : AnyObject]?, views: views)
        }
        
        // Assign the detail label's horizontal constraints
        if self.canShowDetail, let label = self.detailLabel {
            
            let name = "detailLabel"
            
            names.append(name)
            views.updateValue(label, forKey: name)
            
            contentView.addConstraintsWithVisualFormat("|-(padding@750)-[\(name)]-(padding@750)-|", metrics: metrics as [String : AnyObject]?, views: views)
        }
        
        // Assign the button's horizontal constraints
        if self.canShowButton, let button = self.button {
            
            let name = "button"
            
            names.append(name)
            views.updateValue(button, forKey: name)
            
            contentView.addConstraintsWithVisualFormat("|-(padding@750)-[\(name)]-(padding@750)-|", metrics: metrics as [String : AnyObject]?, views: views)
        }
        
        var verticalFormat = ""

        for i in 0..<names.count {
            let name = names[i]
            
            verticalFormat += "[\(name)]"
            
            if (i < views.count-1) {
                verticalFormat += "-(\(space)@750)-"
            }
        }
        
        // Assign the vertical constraints to the content view
        if (verticalFormat.characters.count > 0) {
            contentView.addConstraintsWithVisualFormat("V:|\(verticalFormat)|", metrics: metrics as [String : AnyObject]?, views: views)
        }
    }
    
//    func prepareForReuse() {
//        
//        guard contentView.subviews.count > 0 else { return }
//        
//        titleLabel?.text = nil
//        titleLabel?.frame = CGRectZero
//        
//        detailLabel?.text = nil
//        detailLabel?.frame = CGRectZero
//
//        // Removes all subviews
//        contentView.subviews.forEach({$0.removeFromSuperview()})
//        
//        // Removes all layout constraints
//        contentView.removeConstraints(contentView.constraints)
//        self.removeConstraints(self.constraints)
//    }
}

// MARK: - UIView extension
private extension UIView {
    
    func addConstraintsWithVisualFormat(_ format: String, metrics: [String : AnyObject]?, views: [String : AnyObject]) {
        
        let noLayoutOptions = NSLayoutFormatOptions(rawValue: 0)
        let constraints = NSLayoutConstraint.constraints(withVisualFormat: format, options: noLayoutOptions, metrics: metrics, views: views)
        
        self.addConstraints(constraints)
    }
    
    func addEquallyRelatedConstraint(_ view: UIView, attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        
        let constraint = NSLayoutConstraint(item: view, attribute: attribute, relatedBy: .equal, toItem: self, attribute: attribute, multiplier: 1, constant: 0)
        self.addConstraint(constraint)
        
        return constraint
    }
}
