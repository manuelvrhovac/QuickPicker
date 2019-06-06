//
//  hhh.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 06/07/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit

protocol SmartLayoutProtocol: class {
    
    /// spacing between cells and also all the contentOffset (top, bottom, sides)
    var spacing: CGFloat { get set }
    
    /// maximum width of a cell. The width of the cell will be smaller than this.
    var maximumItemWidth: CGFloat { get set }
    
    /// needed to perform check if collectionView's frame changed
    var oldWidth: CGFloat { get set }
    
    var itemAdditionalHeight: CGFloat { get set }
    var itemHeightToWidthRatio: CGFloat { get set }

    
}

extension SmartLayoutProtocol where Self: UICollectionView {
    
    var flowLayout: UICollectionViewFlowLayout {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            let flowLayout = UICollectionViewFlowLayout()
            self.collectionViewLayout = flowLayout
            return flowLayout
        }
        return flowLayout
    }
    
    @discardableResult
    func smartLayout() -> CGSize {
        return smartLayoutNow(force: true)
    }
    
    @discardableResult
    func smartLayoutIfNeeded() -> CGSize {
        return smartLayoutNow(force: false)
    }
    
    @discardableResult
    private func smartLayoutNow(force: Bool) -> CGSize {
        let oldDirection = flowLayout.scrollDirection
        let isVertical = oldDirection == .vertical
        let width = isVertical ? frame.width : frame.height
        let spacing = self.spacing
        if oldWidth == width && !force {
            return flowLayout.itemSize
        }
        self.oldWidth = width
        var index = 0
        var itemWidth: CGFloat
        repeat {
            index += 1
            itemWidth = (width - CGFloat(index + 1) * spacing) / CGFloat(index)
        } while itemWidth > maximumItemWidth
        
        let itemHeight = itemWidth * itemHeightToWidthRatio + itemAdditionalHeight
        
        // add more padding to sides to get uniform spacing between the cells (0.5 points for retina):
        let remainder = itemWidth.truncatingRemainder(dividingBy: 0.5)
        let sideAdd = remainder * CGFloat(index)
        itemWidth -= remainder
        
        // Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = oldDirection
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        collectionViewLayout = layout
        if isVertical {
            contentInset = .init(top: spacing,
                                 left: spacing + sideAdd / 2,
                                 bottom: contentInset.bottom,
                                 right: spacing + sideAdd / 2)
        } else {
            contentInset = .init(top: spacing + sideAdd / 2,
                                 left: spacing,
                                 bottom: spacing + sideAdd / 2,
                                 right: contentInset.bottom)
        }
        //contentOffset.y = contentInset.top
        print(" Old\(oldWidth) new: \(width), insetTop: \(contentInset.top) SmartLayout executing")
        return layout.itemSize
    }
}

class SmartLayoutCollectionView: UICollectionView, SmartLayoutProtocol {

    var oldWidth: CGFloat = 0.0
    var spacing: CGFloat = 0.0
    var maximumItemWidth: CGFloat = 0.0
    
    var itemAdditionalHeight: CGFloat = 0.0
    var itemHeightToWidthRatio: CGFloat = 1.0

    
    override func layoutSubviews() {
        smartLayoutIfNeeded()
        super.layoutSubviews()
    }
    
    init(spacing: CGFloat, maximumItemWidth: CGFloat) {
        let flow = UICollectionViewFlowLayout()
        flow.itemSize = CGSize(width: 0, height: 0)
        self.spacing = spacing
        self.maximumItemWidth = maximumItemWidth
        super.init(frame: CGRect(), collectionViewLayout: flow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
