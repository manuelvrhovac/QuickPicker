//
//  Created by Manuel Vrhovac on 09/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit


/// CollectionViewSwiper is an object that enables you to select UICollectionView cells by swiping.
///
/// Like in Photos app, you can swipe photos/cells just by swiping one horizontally and then continue downwards/upwards as the collectionview scrolls automatically. After setting up CollectionViewSwiper's delegate, you can listen for 'began', 'changed' and 'ended' events, but most importantly for 'swiper:didModifyCells' event which is called after the user has released the swipe and the cell selection is definite.

class CollectionViewSwiper: NSObject, UIGestureRecognizerDelegate {
    
    typealias DidModifyClosure = (([IndexPath: Bool]) -> Void)
    typealias Delegate = CollectionViewSwiperDelegate
    
    
    // MARK: Public Properties:
    
    public weak var collectionView: UICollectionView!
    public weak var delegate: CollectionViewSwiperDelegate!
    public var onDidModifyCells: DidModifyClosure?
    public var glidingOptions: GlidingOptions
    
    
    // MARK: Calculated
   
    /// State of the swipe gesture (ended or began)
    public var state: UIGestureRecognizer.State {
        return swipingRange.first == nil ? .ended : .began
    }
    
    /// Range that is currently being modified
    public var range: CountableClosedRange<Int>? {
        guard let start = swipingRange.first, let end = swipingRange.last else { return nil }
        return min(start, end)...max(start, end)
    }
    
    /// Check/set swipe and pan gesture recognizers are active
    public var isEnabled: Bool {
        get {
            return swipe.isEnabled && pan.isEnabled
        }
        set {
            swipe.isEnabled = newValue
            pan.isEnabled = newValue
        }
    }
    
    
    // MARK: - Private
    
    private var selectionBeforeSwiping: [Int: Bool] = [:]
    
    private var lastCVFrame: CGRect = .init()
    private var minimumOffset: CGFloat!
    private var maximumOffset: CGFloat!
    
    private let swipe = UISwipeGestureRecognizer()
    private let pan = UIPanGestureRecognizer()
    
    private var glideTimer = Timer()
    
    
    // MARK: Calculated
    
    private var swipingRange: (first: Int?, last: Int?) = (nil, nil) {
        willSet {
            let isSwiping = newValue.first != nil
            let wasSwiping = swipingRange.first != nil
            let stateHasChanged = isSwiping != wasSwiping
            guard stateHasChanged else { return }
            collectionView.isScrollEnabled = !isSwiping
            if isSwiping {
                glideTimer = .scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true, block: checkGlide(_:))
            } else {
                glideTimer.invalidate()
            }
        }
    }
    
    private var loadedCells: [Int: UICollectionViewCell] {
        var dict = [Int: UICollectionViewCell]()
        for index in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) {
                dict[index] = cell
            }
        }
        return dict
    }
    
    
    // MARK: - Init
    
    public init(
        collectionView: UICollectionView,
        glidingOptions: GlidingOptions,
        delegate: CollectionViewSwiperDelegate? = nil,
        onDidModifyCells: DidModifyClosure? = nil
        ) {
        self.glidingOptions = glidingOptions
        self.onDidModifyCells = onDidModifyCells
        self.collectionView = collectionView
        super.init()

        setupGestures()
    }
    
    func setupGestures() {
        swipe.delegate = self
        swipe.cancelsTouchesInView = false
        swipe.direction = [.left, .right]
        swipe.addTarget(self, action: #selector(swiped))
        collectionView.addGestureRecognizer(swipe)
        
        pan.delegate = self
        pan.cancelsTouchesInView = false
        pan.addTarget(self, action: #selector(panned))
        collectionView.addGestureRecognizer(pan)
    }
    
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return true
    }
    
    
    @objc
    private func swiped(swipe: UISwipeGestureRecognizer) {
        let point = swipe.location(in: collectionView)
        swipingRange.first = collectionView.indexPathForItem(at: point)?.row
        delegate?.swiper(self, began: 0)
    }
    
    
    @objc
    private func panned(pan: UIPanGestureRecognizer) {
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
        
        let point = pan.location(in: collectionView)
        let i2 = collectionView.indexPathForItem(at: point)?.row ?? swipingRange.last ?? i1
        let range = min(i1, i2)...max(i1, i2)
        
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
        lastCVFrame = collectionView.frame
        let oldOffset = collectionView.contentOffset
        
        let firstIndex = 0
        collectionView.scrollToItem(at: .init(row: firstIndex, section: 0),
                                    at: .top,
                                    animated: false)
        minimumOffset = collectionView.contentOffset.y
        
        let lastIndex = collectionView.numberOfItems(inSection: 0) - 1
        collectionView.scrollToItem(at: .init(row: lastIndex, section: 0),
                                    at: .bottom,
                                    animated: false)
        maximumOffset = collectionView.contentOffset.y
        
        collectionView.contentOffset = oldOffset
    }
    
    
    @objc
    private func checkGlide(_ timer: Timer) {
        if minimumOffset == nil || maximumOffset == nil || lastCVFrame != collectionView.frame {
            recalculateMinimumAndMaximumOffset()
        }
        
        // Write down how close is the touch to the top (negative) or the bottom (positive)
        // of the collectionview. This will be needed for gliding later.
        
        guard let superview = collectionView.superview else { return }
        let y = pan.location(in: superview).y - collectionView.frame.origin.y
        let distanceFromBottom: CGFloat = max(collectionView.frame.height - y, 0)
        let distanceFromTop: CGFloat = max(0, y)
        let distanceFromEdge: CGFloat = min(distanceFromBottom, distanceFromTop)
        guard distanceFromEdge < glidingOptions.glideDistance else { return }
        
        let isScrollingDown: Bool = distanceFromBottom < distanceFromTop
        let isAtBottom = isScrollingDown && collectionView.contentOffset.y + collectionView.contentInset.top > maximumOffset
        let isAtTop = !isScrollingDown && collectionView.contentOffset.y - collectionView.contentInset.top < minimumOffset
        if isAtBottom || isAtTop {
            collectionView.contentOffset.y = isAtTop ? minimumOffset : maximumOffset
            return
        }
        
        var speedMultiplier: CGFloat {
            switch 100 * distanceFromEdge / glidingOptions.glideDistance {
            case 00..<30: return glidingOptions.ultraFastGlidingFactor // super fast scrolling
            case 30..<60: return glidingOptions.fastGlidingFactor // fast scrolling
            default: return glidingOptions.normalGlidingFactor // slow scroll
            }
        }
        
        collectionView.contentOffset.y += 5.0 * speedMultiplier * (isScrollingDown ? 1 : -1)
    }
    
}

// MARK: -

protocol CollectionViewSwiperDelegate: class {
    
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
