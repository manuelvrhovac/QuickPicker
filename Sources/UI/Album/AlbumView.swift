//
//  Created by Manuel Vrhovac on 01/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import KVFetcher
import RxSwift

class AlbumView: SmartLayoutCollectionView {
    
    private(set) var viewModel: AlbumViewModel!
    var bag = DisposeBag()
    
    // MARK: - Public methods
    
    init(viewModel: AlbumViewModel) {
        self.viewModel = viewModel
        super.init(spacing: 8.0, maximumItemWidth: 120.0)
    }
    
    override func didMoveToSuperview() {
        if self.dataSource == nil { setup() }
    }
    
    private func setup() {
        let id = AlbumCellView.selfID
        itemAdditionalHeight = 58.0
        itemHeightToWidthRatio = 1
        backgroundColor = .white
        alwaysBounceVertical = true
        delegate = self
        dataSource = self
        register(.init(nibName: id, bundle: bundle), forCellWithReuseIdentifier: id)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isTracking else { return }
        scrollView.scrollToTopMarginIfOnEdge()
    }
    
    func highlightIndexPath(_ indexPath: IndexPath) {
        let cell = cellForItem(at: indexPath)!
        cell.animateShrinkGrow(duration: 0.3)
    }
    
    // MARK: - Private methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension AlbumView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.countIn(section: section)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let cellViewModel = viewModel.cellViewModel(at: indexPath)
        let cell = self.dequeue(AlbumCellView.self, for: indexPath)!
        cell.configure(viewModel: cellViewModel)
        return cell
    }
}


extension AlbumView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        highlightIndexPath(indexPath)
        delay(0.05) {
            self.viewModel.selectedItemAt(indexPath)
        }
    }
}
