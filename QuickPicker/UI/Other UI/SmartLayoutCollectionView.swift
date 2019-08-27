//
//  Created by Manuel Vrhovac on 26/08/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation

/// A collection view implementing the SmartLayoutProtocol - resizes cell according to available space and defined maximum cell width.
class SmartLayoutCollectionView: UICollectionView, SmartLayoutProtocol {
    
    var oldWidth: CGFloat = 0.0
    
    /// Spacing between the cells and edges of screen
    var spacing: CGFloat = 0.0
    
    /// Cell width won't exceed this value
    var maximumItemWidth: CGFloat = 0.0
    
    /// Additional height to each cell (fixed)
    var itemAdditionalHeight: CGFloat = 0.0
    
    /// Ratio of height and width for each cell
    var itemHeightToWidthRatio: CGFloat = 1.0
    
    override func layoutSubviews() {
        smartLayoutIfNeeded()
        super.layoutSubviews()
    }
    
    init(spacing: CGFloat, maximumItemWidth: CGFloat) {
        let flow = UICollectionViewFlowLayout()
        flow.itemSize = .init(width: 0, height: 0)
        self.spacing = spacing
        self.maximumItemWidth = maximumItemWidth
        super.init(frame: .init(), collectionViewLayout: flow)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
