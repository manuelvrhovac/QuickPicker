//
//  CollectionViewSwiper.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 09/08/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

protocol CollectionViewSwiperDelegate: class {
    
    /*func swiper(_ swiper: CollectionViewSwiper, began range: CountableClosedRange<Int>)
    func swiper(_ swiper: CollectionViewSwiper, changed range: CountableClosedRange<Int>)
    func swiper(_ swiper: CollectionViewSwiper, ended range: CountableClosedRange<Int>)*/
    func swiper(_ swiper: CollectionViewSwiper, didModifyCells modifiedCells: [IndexPath: Bool])
}

extension CollectionViewSwiperDelegate {
    
    func swiper(_ swiper: CollectionViewSwiper, began index: Int) {}
    func swiper(_ swiper: CollectionViewSwiper, changed range: CountableClosedRange<Int>) {}
    func swiper(_ swiper: CollectionViewSwiper, ended range: CountableClosedRange<Int>) {}
}

extension CollectionViewSwiper {
    
    /// While swiping selection and approaching the edge of screen, collection view starts to scroll automatically. This struct is used to store options of when and how fast will the scrolling occur.
    public struct GlidingOptions {
        
        /// The distance of finger< -> screenedge where scrollview starts to scroll for you while swiping. Default 100px.
        var glideDistance: CGFloat = 100.0
        /// Speed when finger is close to edge of scrollview (100-60% of glideDistance). Default 1.0
        var normalGlidingFactor: CGFloat = 1.0
        /// Speed when finger is very close to edge of scrollview (60-30% of glideDistance). Default 3.0
        var fastGlidingFactor: CGFloat = 3.0
        /// Speed when finger is just next to edge of scrollview (30-0% of glideDistance). Default 6.0
        var ultraFastGlidingFactor: CGFloat = 6.0
        
        /// Collection view will start scrolling when finger is 100px from the edge of screen while swiping selection. Getting down to 60px it scrolls as 3x as fast, and getting under 30px to edge it will scroll 6x as fast!
        public static var `default`: GlidingOptions {
            return .init()
        }
        
        /// Collection view will not scroll when finger approaches the edge of screen while swiping selection.
        public static var none: GlidingOptions {
            return .init(distance: 0.0, normalFactor: 1.0, fastFactor: 1.0, ultraFastFactor: 1.0)
        }
        
        /// Default values: distance=100, normalFactor=1, fastFactor=3, ultraFastFactor=6
        public init(distance: CGFloat, normalFactor: CGFloat, fastFactor: CGFloat, ultraFastFactor: CGFloat) {
            self.glideDistance = distance
            self.normalGlidingFactor = normalFactor
            self.fastGlidingFactor = fastFactor
            self.ultraFastGlidingFactor = ultraFastFactor
        }
        private init() {}
    }
}

/// CollectionViewSwiper is an object that enables you to select UICollectionView cells by swiping.
///
/// Like in Photos app, you can swipe photos/cells just by swiping one horizontally and then continue downwards as the collectionview scrolls automatically. After setting up CollectionViewSwiper's delegate, you can listen for 'began', 'changed' and 'ended' events, but most importantly for 'swiper:didModifyCells' event which is called after the user has released the swipe and the cell selection is definite.

class CollectionViewSwiper: NSObject, UIGestureRecognizerDelegate {
    
    typealias DidModifyClosure = (([IndexPath: Bool]) -> Void)

    // MARK: - Public Properties:
    
    public weak var cv: UICollectionView!
    public weak var delegate: CollectionViewSwiperDelegate!
    public var onDidModifyCells: DidModifyClosure?
   
    public var state: UIGestureRecognizer.State {
        return swipingRange.first == nil ? .ended : .began
    }
    
    public var range: CountableClosedRange<Int>? {
        guard let start = swipingRange.first, let end = swipingRange.last else { return nil }
        return min(start, end)...max(start, end)
    }
    
    public var isEnabled: Bool {
        get {
            return swipe.isEnabled && pan.isEnabled
        }
        set {
            swipe.isEnabled = newValue
            pan.isEnabled = newValue
        }
    }
    
    var glidingOptions: GlidingOptions
    
    // MARK: - Private
    
    private var selectionBeforeSwiping: [Int: Bool] = [:]
    
    private var lastCVFrame: CGRect = .init()
    private var minimumOffset: CGFloat!
    private var maximumOffset: CGFloat!
    
    private let swipe = UISwipeGestureRecognizer()
    private let pan = UIPanGestureRecognizer()
    
    /// A timer is necessary to achieve smooth scrolling while finger is close to edge
    private var glideTimer = Timer()
    
    //private var swipingRange.last: Int? = nil
    
    /*private var swipingRange.first: Int? = nil {
        willSet {
            let isSwiping = newValue != nil
            let wasSwiping = swipingRange.first != nil
            let stateHasChanged = isSwiping != wasSwiping
            guard stateHasChanged else { return }
            cv.isScrollEnabled = !isSwiping
            if isSwiping {
                glideTimer = .scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true, block: checkGlide(_:))
            }
            else {
                glideTimer.invalidate()
            }
        }
    }*/
    
    private var swipingRange: (first: Int?, last: Int?) = (nil, nil) {
        willSet {
            let isSwiping = newValue.first != nil
            let wasSwiping = swipingRange.first != nil
            let stateHasChanged = isSwiping != wasSwiping
            guard stateHasChanged else { return }
            cv.isScrollEnabled = !isSwiping
            if isSwiping {
                glideTimer = .scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true, block: checkGlide(_:))
            } else {
                glideTimer.invalidate()
            }
        }
    }
    
    
    public convenience init(
        collectionView: UICollectionView,
        glidingOptions: GlidingOptions,
        didModifyClosure: DidModifyClosure
        ) {
        self.init(collectionView: collectionView, glidingOptions: glidingOptions)
        
    }
    
    public init(
        collectionView: UICollectionView,
        glidingOptions: GlidingOptions,
        didModifyCellsClosure: DidModifyClosure? = nil
        ) {
        self.glidingOptions = glidingOptions
        self.onDidModifyCells = didModifyCellsClosure
        super.init()
        cv = collectionView
        
        swipe.delegate = self
        swipe.cancelsTouchesInView = false
        swipe.direction = [.left, .right]
        swipe.addTarget(self, action: #selector(swipeGestureRecognizerSwiped(sender:)))
        cv.addGestureRecognizer(swipe)

        pan.delegate = self
        pan.cancelsTouchesInView = false
        pan.addTarget(self, action: #selector(panGestureRecognizerPanned(_:)))
        cv.addGestureRecognizer(pan)
    }
    
    
    private var loadedCells: [Int: ItemCellView] {
        var dict = [Int: ItemCellView]()
        for index in 0 ..< cv.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = cv.cellForItem(at: indexPath) as? ItemCellView {
                dict[index] = cell
            }
        }
        return dict
    }
    
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return true
    }
    
    
    @objc
    private func swipeGestureRecognizerSwiped(sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: cv)
        swipingRange.first = cv.indexPathForItem(at: point)?.row
        delegate?.swiper(self, began: 0)
    }
    
    
    @objc
    private func panGestureRecognizerPanned(_ pan: UIPanGestureRecognizer) {
        guard let i1 = swipingRange.first else { return }
        
        guard pan.state != .ended else {
            let end = swipingRange.last ?? i1
            let range = min(i1, end)...max(i1, end)
            
            var modifiedCells = [IndexPath: Bool]()
            for (index, oldState) in selectionBeforeSwiping {
                let indexPath = IndexPath(row: index, section: 0)
                let shouldFlip = range.contains(index)
                let newState = shouldFlip ? !oldState : oldState
                modifiedCells[indexPath] = newState
            }
            
            delegate?.swiper(self, ended: range)
            delegate?.swiper(self, didModifyCells: modifiedCells)
            onDidModifyCells?(modifiedCells)
            
            swipingRange.first = nil
            swipingRange.last = nil
            selectionBeforeSwiping = [:]
            return
        }
        
        let point = pan.location(in: cv)
        let i2 = cv.indexPathForItem(at: point)?.row ?? swipingRange.last ?? i1
        let range = min(i1, i2)...max(i1, i2)
        /*
        if swipingRange.first == nil {
            selectionBeforeSwiping.removeAll()
            delegate?.swiper(self, began: i1)
        }*/
        
        for (index, cell) in loadedCells {
            // This index is now affected. Save state before changing it.
            if selectionBeforeSwiping[index] == nil {
                selectionBeforeSwiping[index] = cell.isSelected
            }
            let wasSelected = selectionBeforeSwiping[index]!
            // flip it if it's inside the range, or keep it if not
            cell.isSelected = range.contains(index) ? !wasSelected : wasSelected
        }
        
        swipingRange.last = i2
        delegate?.swiper(self, changed: range)
    }
    
    
    // If collectionView frame changed, calculate the minimum and maximum offset
    // minimum offset depends on topLayoutGuide of the viewcontroller
    // normally in iOS 11 you access it by getting safeAreaInsets of a view, but
    // in iOS 10 it doesn't exist. So you scroll up and examine it manually.
    
    func recalculateMinimumAndMaximumOffset() {
        lastCVFrame = cv.frame
        let oldOffset = cv.contentOffset
        cv.scrollToItem(at: .init(row: 0, section: 0), at: .top, animated: false)
        minimumOffset = cv.contentOffset.y
        cv.scrollToItem(at: .init(row: cv.numberOfItems(inSection: 0) - 1, section: 0), at: .bottom, animated: false)
        maximumOffset = cv.contentOffset.y
        cv.contentOffset = oldOffset
    }
    
    
    @objc
    private func checkGlide(_ timer: Timer) {
        if minimumOffset == nil || maximumOffset == nil || lastCVFrame != cv.frame {
            recalculateMinimumAndMaximumOffset()
        }
        
        // Write down how close is the touch to the top (negative) or the bottom (positive)
        // of the collectionview. This will be needed for gliding later.
        
        guard let superview = cv.superview else { return }
        let y = pan.location(in: superview).y - cv.frame.origin.y
        let distanceFromBottom: CGFloat = max(cv.frame.height - y, 0)
        let distanceFromTop: CGFloat = max(0, y)
        let distanceFromEdge: CGFloat = min(distanceFromBottom, distanceFromTop)
        guard distanceFromEdge < glidingOptions.glideDistance else { return }
        
        let isScrollingDown: Bool = distanceFromBottom < distanceFromTop
        let isAtBottom = isScrollingDown && cv.contentOffset.y + cv.contentInset.top > maximumOffset
        let isAtTop = !isScrollingDown && cv.contentOffset.y - cv.contentInset.top < minimumOffset
        if isAtBottom || isAtTop {
            cv.contentOffset.y = isAtTop ? minimumOffset : maximumOffset
            return
        }
        
        var speedMultiplier: CGFloat {
            switch 100 * distanceFromEdge / glidingOptions.glideDistance {
            case 00..<30: return glidingOptions.ultraFastGlidingFactor // super fast scrolling
            case 30..<60: return glidingOptions.fastGlidingFactor // fast scrolling
            default: return glidingOptions.normalGlidingFactor // slow scroll
            }
        }
        
        cv.contentOffset.y += 5.0 * speedMultiplier * (isScrollingDown ? 1 : -1)
    }
    
}
