//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit
//import Photos
import KVFetcher
import AVKit
import RxSwift
import RxCocoa

class ItemView: SmartLayoutCollectionView, DefaultCellProtocol {
    typealias Cell = ItemCellView
    var bag = DisposeBag()
    
    struct SelectAllButtonImages {
        
        static let select = loadBundledImage("selectAll").template
        static let deselect = loadBundledImage("deselectAll").template
        static func image(for value: Bool) -> UIImage {
            return value ? select : deselect
        }
    }
    // MARK: - Properties:
    
    var viewModel: ItemViewModel
    var swiper: CollectionViewSwiper!
    var previewedIndexPath: IndexPath?
    
    lazy var selectAllBarButtonItem: ImageBarButtonItem = .init(buttonImage: nil, size: .init(width: 36, height: 30))

    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    
    // MARK: - ViewController lifecycle
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
        super.init(spacing: 2.0, maximumItemWidth: 100.0)
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        if self.dataSource == nil { setup() }
    }
    
    func setup() {
        backgroundColor = .white
        allowsMultipleSelection = viewModel.allowsMultipleSelection
        alwaysBounceVertical = true
        dataSource = self
        registerForDefaultCell(bundle: bundle)
        
        tapGestureRecognizer = .init()
        addGestureRecognizer(tapGestureRecognizer)
        swiper = .init(collectionView: self,
                       glidingOptions: .default,
                       onDidModifyCells: viewModel.modifyCells)
        swiper.isEnabled = viewModel.allowsMultipleSelection
        
        setupBindings()
        
    }
    
    
    func setupBindings() {
        bag.insert(
            tapGestureRecognizer.rx.event
                .map { self.indexPathForItem(at: $0.location(in: self)) }
                .bind(onNext: viewModel.tappedIndexPath),
            viewModel.fetchResult.bind(onNext: { _ in
                self.reloadData()
                self.swiper.isEnabled = self.viewModel.allowsMultipleSelection
            }),
            selectAllBarButtonItem.button.rx.tap
                .bind(onNext: viewModel.selectAll),
            viewModel.selectAllButtonImage
                .bind(to: selectAllBarButtonItem.button.rx.image()),
            viewModel.maxItemSize
                .bind(onNext: setMaxItemSize)
        )
        //setMaxItemSize(optMaxItemSize: viewModel.maxItemSize.value)
    }
    
    
    func setMaxItemSize(optMaxItemSize: [UIUserInterfaceIdiom: CGFloat]?) {
        let defaultSizes: [UIUserInterfaceIdiom: CGFloat] = [.phone: 100.0, .pad: 150.0]
        let idiom = UIDevice.current.userInterfaceIdiom
        let maxItemSize = optMaxItemSize?[optional: idiom]
            ?? defaultSizes[optional: idiom]
            ?? 100.0
        maximumItemWidth = maxItemSize
        smartLayout()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - CollectionViewDelegate data source

extension ItemView: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let cell = dequeueReusableDefaultCell(at: indexPath)!
        let cellViewModel = viewModel.cellModel(for: indexPath)
        cell.configure(viewModel: cellViewModel)
        return cell
    }
}
