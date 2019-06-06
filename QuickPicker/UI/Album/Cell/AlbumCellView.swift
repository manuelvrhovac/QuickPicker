//
//  AlbumCollectionViewCell.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 01/07/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
//import Photos

class AlbumCellView: UICollectionViewCell {
    
    private var viewModel: AlbumCellViewModel!
    
    @IBOutlet private weak var shadowButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var triangle: UIImageView!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var quadroStack: UIStackView!
    
    
    func configure(viewModel: AlbumCellViewModel) {
        self.viewModel = viewModel
        self.viewModel.fetchAssetAndImage()
        reconfigure()
    }
    
    func reconfigure() {
        if viewModel.image != nil {
            imageView.image = viewModel.image
            imageView.transform = .identity
            icon.image = viewModel.icon
            triangle.isHidden = viewModel.icon == nil
            icon.isHidden = viewModel.icon == nil
        } else {
            imageView.image = viewModel.icon
            imageView.transform = .init(scaleX: 0.5, y: 0.5)
            triangle.isHidden = true
            icon.isHidden = true
        }
        
        titleLabel.text = viewModel.title
        
        subtitleLabel.text = viewModel.subtitle
        subtitleLabel.isHidden = viewModel.subtitle == nil
        viewModel.onRefreshUI = {
            self.reconfigure()
        }
        
    }
    
    
    override func willMove(toSuperview newSuperview: UIView?) {
        imageView.tintColor = .white
        shadowButton.layer.addDynamicShadow(color: .black, opacity: 0.14, radius: 8.0, distance: 4.0)
        imageView.superview!.layer.cornerRadius = 6.0
        imageView.superview!.clipsToBounds = true
        triangle.clipsToBounds = true
    }
    
}

/*
class AlbumCollectiojnViewCell: UICollectionViewCell {
    
    static let placeholderImage = UIImage(bundleNamed: "placeholder")
    
    @IBOutlet private weak var shadowButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var triangle: UIImageView!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var quadroStack: UIStackView!
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.transform = .identity
            triangle.alpha = 1.0
            icon.alpha = 1.0
            if let firstImage = newValue {
                imageView.image = firstImage
            }
            else if let iconImage = icon.image {
                imageView.image = iconImage.template
                imageView.tintColor = .white
                imageView.transform = .init(scaleX: 0.5, y: 0.5)
                triangle.alpha = 0.0
                icon.alpha = 0.0
            }
            else {
                imageView.image = AlbumCollectionViewCell.placeholderImage
            }
        }
    }
    
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            guard let text = newValue else {
                subtitleLabel.isHidden = true
                return
            }
            subtitleLabel.isHidden = false
            subtitleLabel.text = text
        }
    }
    
    
    var collection: PHAssetCollection? {
        didSet{
            collectionDidSet()
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        shadowButton.layer.addDynamicShadow(color: .black, opacity: 0.1, radius: 8.0, distance: 4.0)
        imageView.superview!.layer.cornerRadius = 6.0
        imageView.superview!.clipsToBounds = true
        triangle.clipsToBounds = true
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setup()
    }
    
    func collectionDidSet() {
        titleLabel.text = collection?.localizedTitle ?? ""
        let c = collection?.estimatedAssetCount ?? 0
        subtitleLabel.text = c < 99999 ? "\(c) items" : " "
        imageView.image = AlbumCollectionViewCell.placeholderImage
        icon.image = collection?.assetCollectionSubtype.icon
        
        
        subtitleLabel.isHidden = subtitleLabel.text!.isEmpty
        icon.isHidden = icon.image == nil
        triangle.isHidden = icon.image == nil
    }
    
    override func prepareForReuse() {
        collection = nil
    }
    
    
}*/
 

extension UICollectionView {
    
    /// Dequeues a custom type of cell. The reuseIdentifier needs to be set as class name.
    func dequeue<T>(_ type: T.Type, for indexPath: IndexPath) -> T? {
        let reuseIdentifier = "\(T.self)"
        return dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? T
    }
}
