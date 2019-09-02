//
//  Created by Manuel Vrhovac on 01/01/2019.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class AlbumCellView: UICollectionViewCell {
    
    @IBOutlet private weak var shadowButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var triangle: UIImageView!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var quadroStack: UIStackView!
    
    private var viewModel: AlbumCellViewModel!
    private var bag = DisposeBag()
    
    func configure(viewModel: AlbumCellViewModel) {
        self.viewModel = viewModel
        self.bag = .init()
        self.setupBindings()
        if self.viewModel.keyAssetImage.value == nil {
            self.viewModel.fetchAssetAndImage()
        }
    }
    
    func imageOrIconChanged(_ tuple: (image: UIImage?, icon: UIImage?)) {
        let (image, icon) = tuple
        if image != nil {
            imageView.image = image
            imageView.transform = .identity
            iconImageView.image = icon
            triangle.isHidden = icon == nil
            iconImageView.isHidden = icon == nil
        } else {
            imageView.image = icon
            imageView.transform = .init(scaleX: 0.5, y: 0.5)
            triangle.isHidden = true
            iconImageView.isHidden = true
        }
    }
    
    func setupBindings() {
        Observable.combineLatest(viewModel.keyAssetImage, viewModel.icon)
            .bind(onNext: imageOrIconChanged)
            .disposed(by: bag)
        
        viewModel.subtitle
            .bind(to: subtitleLabel.rx.text)
            .disposed(by: bag)
        
        viewModel.title
            .bind(to: titleLabel.rx.text)
            .disposed(by: bag)
    }
    
    
    override func willMove(toSuperview newSuperview: UIView?) {
        imageView.tintColor = .white
        shadowButton.layer.addDynamicShadow(opacity: 0.14, radius: 8.0, distance: 4.0)
        imageView.superview!.layer.cornerRadius = 6.0
        imageView.superview!.clipsToBounds = true
        triangle.clipsToBounds = true
    }
    
}

extension UICollectionView {
    
    /// Dequeues a custom type of cell. The reuseIdentifier needs to be set as class name.
    func dequeue<T>(_ type: T.Type, for indexPath: IndexPath) -> T? {
        let reuseIdentifier = "\(T.self)"
        return dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? T
    }
}
