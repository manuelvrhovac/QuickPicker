//
//  ItemRXXViewModel+3D.swift
//  QuickPicker
//
//  Created by Manuel Vrhovac on 26/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import AVKit
import KVFetcher

// MARK: - UIViewControllerPreviewingDelegate methods

extension ItemView: UIViewControllerPreviewingDelegate {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
    
    func previewingContext(
        _ previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint
        ) -> UIViewController? {
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
        let prefContSize = CGSize(width: f.width, height: f.width / ratio)
        
        
        detailVC.preferredContentSize = prefContSize
        
        
        let cellImage = cell.imageView.image!
        let iv = UIImageView(image: cellImage)
        iv.contentMode = .scaleAspectFit
        detailVC.view = iv
        
        viewModel.getPreview(at: indexPath) { result in
            switch result {
            case let .image(image):
                iv.image = image
            case let .video(url):
                let player = AVPlayer(url: url ?? .init(fileURLWithPath: ""))
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                detailVC.view.addSubview(playerViewController.view)
                playerViewController.view.snapToSuperview()
                playerViewController.showsPlaybackControls = false
                player.play()
                playerViewController.view.alpha = 0.0
                delay(0.2) {
                    playerViewController.view.alpha = 1.0
                }
            }
        }
        return detailVC
    }
    
    
    func previewingContext(
        _ previewingContext: UIViewControllerPreviewing,
        commit viewControllerToCommit: UIViewController
        ) {
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
