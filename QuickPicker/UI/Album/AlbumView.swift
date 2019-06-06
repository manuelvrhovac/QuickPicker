//
//  AlbumCoverCollectionView.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 01/07/2018.
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
        
        delay(1.0) {
            print(self.contentOffset.y)
        }
        setupBindings()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isTracking else { return }
        scrollView.scrollToTopMarginIfOnEdge()
    }
    
    func setupBindings() {
        viewModel.selectedIndexPath.skip(1).bind(onNext: highlightIndexPath).disposed(by: bag)
    }
    
    func highlightIndexPath(_ indexPath: IndexPath) {
        let cell = cellForItem(at: indexPath)!
        UIView.animate(withDuration: 0.4, animations: {
            cell.transform = CGAffineTransform(translationX: 0, y: 3.0).concatenating(.init(scaleX: 0.85, y: 0.85))
        }, completion: { _ in
            cell.transform = .identity
        })
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
        viewModel.selectedItemAt(indexPath)
    }
}
