//
//  ItemViewModel.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 15/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//
/*
import Foundation
import UIKit
//import Photos
import KVFetcher
import AVKit

protocol DefaultCellProtocol {
 
    associatedtype Cell: UICollectionViewCell
}

extension DefaultCellProtocol where Self: UICollectionView {
 
    var loadedDefaultCells: [Cell] {
        return loadedCells.compactMapAs(Cell.self)
    }
    
    /// Cell .xib name and reuseIdentifier need to be exact same as cell class name.
    func registerForDefaultCell(bundle: Bundle?) {
        let bundle = bundle ?? Bundle.main
        let id = Cell.selfID
        register(.init(nibName: id, bundle: bundle), forCellWithReuseIdentifier: id)
    }
    func defaultCellForItem(at indexPath: IndexPath) -> Cell? {
        return cellForItem(at: indexPath) as? Cell
    }

    func dequeueReusableDefaultCell(at indexPath: IndexPath) -> Cell? {
        return dequeueReusableCell(withReuseIdentifier: Cell.selfID, for: indexPath) as? Cell
    }
    
    func defaultCellForItem(at location: CGPoint) -> Cell?{
        guard let ip = indexPathForItem(at: location) else { return nil }
        return defaultCellForItem(at: ip)
    }
}

class ItemView: SmartLayoutCollectionView, DefaultCellProtocol {
    typealias Cell = ItemCellView
    
    static var maxItemWidth: CGFloat {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return 100.0
        case .pad: return 150.0
        default: return 100.0
        }
    }
    
    // MARK: - Public properties:
    
    var viewModel: ItemViewModel!
    
    var selectAllBarButtonItem: UIBarButtonItem!
    
    private var swiper: CollectionViewSwiper!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var previewedIndexPath: IndexPath?
    
    
    // MARK: - ViewController lifecycle
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
        super.init(spacing: 2.0, maximumItemWidth: ItemView.maxItemWidth)
        selectAllBarButtonItem = .init(image: viewModel.selectAllButtonImage,
                                       size: .init(width: 36, height: 30),
                                       target: self,
                                       action: #selector(self.selectAllPressed))
    }
    
    override func didMoveToSuperview() {
        if self.dataSource == nil {
            setup()
        }
    }
    
    
    func setup() {
        backgroundColor = .white
        allowsMultipleSelection = viewModel.allowsMultipleSelection
        alwaysBounceVertical = true
        dataSource = self
        registerForDefaultCell(bundle: bundle)
        
        tapGestureRecognizer = .init(target: self, action: #selector(tapped(_:)))
        addGestureRecognizer(tapGestureRecognizer)
        
        swiper = CollectionViewSwiper(collectionView: self)
        swiper.delegate = self
        swiper.isEnabled = viewModel.allowsMultipleSelection
        
        viewModel.onSelectionChanged = {
            self.refreshSelectAllButton()
        }
        viewModel.onReloadFetchResult = {
            self.reloadData()
            self.swiper.isEnabled = self.viewModel.allowsMultipleSelection
        }
                
        delay(0.01) {
            self.reloadData()
            self.smartLayout()
        }
    }
    
    
    @objc
    func tapped(_ gr: UITapGestureRecognizer) {
        if let indexPath = indexPathForItem(at: gr.location(in: self)) {
            viewModel.tapped(indexPath: indexPath)
        }
    }
    
    
    func refreshSelectAllButton() {
        if let button = selectAllBarButtonItem.customView as? UIButton {
            button.setImage(viewModel.selectAllButtonImage, for: .normal)
        }
    }
    
    @objc
    func selectAllPressed() {
        viewModel.selectAll()
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
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableDefaultCell(at: indexPath)!
        let cellViewModel = viewModel.cellModel(for: indexPath)
        cell.configure(viewModel: cellViewModel)
        return cell
    }
}

// MARK: - UIViewControllerPreviewingDelegate methods

extension ItemView: UIViewControllerPreviewingDelegate {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if swiper.state != .ended { return nil }
        guard let indexPath = indexPathForItem(at: location),
            let cell = defaultCellForItem(at: indexPath)
            else { return nil }
        
        previewedIndexPath = indexPath
        previewingContext.sourceRect = cell.frame
        
        
        let detailVC = UIViewController()
        let itemSize = viewModel.itemSize(at: indexPath)
        let ratio = itemSize.width / itemSize.height
        let f = detailVC.view.frame
        let prefContSize = CGSize(width: f.width, height: f.width/ratio)
        
        
        detailVC.preferredContentSize = prefContSize
        
        
        let cellImage = cell.imageView.image!
        let iv = UIImageView(image: cellImage)
        iv.contentMode = .scaleAspectFit
        detailVC.view = iv
        
        viewModel.getPreview(at: indexPath) { result in
            switch result {
            case let .image(image):
                iv.image = image
                break
            case let .video(url):
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                detailVC.view.addSubview(playerViewController.view)
                playerViewController.view.snapToSuperview()
                playerViewController.showsPlaybackControls = false
                player.proceed()
                playerViewController.view.alpha = 0.0
                delay(0.2) {
                    playerViewController.view.alpha = 1.0
                }
            }
        }
        return detailVC
    }
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        /*
         zoomableIVC = ZoomableIVC(image: nil)
         
         if let previewedIndexPath = previewedIndexPath {
         self.previewedIndexPath = nil
         let asset = getAsset(forRow: previewedIndexPath.row)
         assetCacher.fetchValue(for: asset, priority: .now) { (image) in
         i.image = image
         }
         let options = PHImageRequestOptions()
         options.deliveryMode = .highQualityFormat
         options.resizeMode = .fast
         options.isNetworkAccessAllowed = true
         imageManager.requestImage(for: asset, targetSize: CGSize(width: 99999, height: 99999), contentMode: .aspectFit, options: options) { image, _ in
         guard let image = image else { return }
         self.zoomableIVC.image = image
         }
         }
         
         show(zoomableIVC, sender: self)*/
    }
    
}


// MARK: - SwiperDelegate

extension ItemView: CollectionViewSwiperDelegate {
 
    func swiper(_ swiper: CollectionViewSwiper, modifiedCells: [IndexPath : Bool]) {
        viewModel.modifyCells(at: modifiedCells)
    }
}

*/
