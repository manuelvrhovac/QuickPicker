//
//  ReviewViewController.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 13/08/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import RxSwift
import RxCocoa

extension ReviewViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("Swiped")
        return true
    }
}

extension ReviewViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
        let ivm = viewModel.itemCellViewModel(atIndex: indexPath.row)
        ivm.fetchImage()
        let cell = cv.dequeue(ItemCellView.self, for: indexPath)!
        cell.configure(viewModel: ivm)
        cell.imageView.layer.cornerRadius = 4.0
        return cell
    }
}


class ReviewViewController: UIViewController {
    
    
    var viewModel: ReviewViewModel!
    
    @IBOutlet private(set) weak var countLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var mainStack: UIStackView!
    
    @IBOutlet private(set) weak var cvStack: UIStackView!
    @IBOutlet private(set) weak var addMoreButton: UIButton!
    
    @IBOutlet private(set) weak var buttonStack: UIStackView!
    // MARK: - Properties
    
    var swipeGestureRecognizer: UISwipeGestureRecognizer!
    var leftSwipe: UISwipeGestureRecognizer!
    // MARK: Calculated
    
    var removeButton: UIButton {
        return view.all(UIButton.self).last!
    }
    var mediaStack: UIStackView {
        return imageView.superview as! UIStackView
    }
    
    var cv: SmartLayoutCollectionView!
    var playerView: AVPlayerViewController!
    var player: AVPlayer! {
        get { return playerView.player }
        set { playerView?.player = newValue }
    }
    
    var bag = DisposeBag()
    
    // MARK: - Init

    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmButton.layer.cornerRadius = 10.0
        confirmButton.backgroundColor = view.tintColor
        
        cancelButton.layer.cornerRadius = 10.0
        cancelButton.layer.addShadow(.black, o: 0.18, r: 14.0, d: 8.0)
        
        addMoreButton.layer.cornerRadius = 10.0
        
        imageView.contentMode = .scaleAspectFit
        
        addMoreButton.isHidden = !viewModel.canAddMore
        
        
        leftSwipe = .init(target: self, action: #selector(swipe))
        leftSwipe.direction = .right
        imageView.addGestureRecognizer(leftSwipe)
        
        swipeGestureRecognizer = .init(target: self, action: #selector(swipe))
        swipeGestureRecognizer.direction = .left
        
        imageView.addGestureRecognizer(swipeGestureRecognizer)
        imageView.isUserInteractionEnabled = true
        
        cv = .init(spacing: 3.0, maximumItemWidth: 56)
        cv.flowLayout.scrollDirection = .horizontal
        cvStack.addArrangedSubview(cv)
        
        cv.registerNibForCellWith(reuseIdentifier: ItemCellView.selfID, bundle: bundle)
        cv.dataSource = self
        cv.contentInset = .zero
        cv.layoutMargins = .zero
        cv.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        cv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cvTapped)))
        cv.layer.cornerRadius = 6.0
        cv.alwaysBounceHorizontal = true
        cv.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        reload()
        
        playerView = .init()
        playerView.player = .init()
        playerView.view.backgroundColor = .clear
        mediaStack.addArrangedSubview(playerView.view)
        
        setupBindings()
    }
    
    static func initi(viewModel: ReviewViewModel) -> ReviewViewController {
        let rvc = ReviewViewController.initi(storyboarddName: nil)!
        rvc.viewModel = viewModel
        return rvc
    }

    
    func setupBindings() {
        viewModel.currentIndex.bind(onNext: indexChanged).disposed(by: bag)
        viewModel.onFinish.bind(onNext: clearAndDismiss(result:)).disposed(by: bag)
        
        let assetsChanged = viewModel.assets.share()
        assetsChanged.map { _ in }.bind(onNext: reload).disposed(by: bag)
        
        let assetsCount = assetsChanged.map { $0.count }.share()
        assetsCount.map { $0 < 2 }.bind(to: removeButton.rx.isHidden).disposed(by: bag)
        assetsCount.map { $0 < 2 }.bind(to: cvStack.rx.isHidden).disposed(by: bag)
        assetsCount.map { $0 < 30 }.bind(to: slider.superview!.rx.isHidden).disposed(by: bag)
        
        // Interaction:
        
        removeButton.rx.tap
            .bind(onNext: viewModel.removeCurrentAsset)
            .disposed(by: bag)
        
        let sliderValue = slider.rx.value
            .map { return Int($0 * Float(self.viewModel.numberOfItems - 1)) }
            .distinctUntilChanged()
            .share()
        
        sliderValue
            .throttle(0.1, scheduler: MainScheduler.instance)
            .bind(to: viewModel.currentIndex)
            .disposed(by: bag)
        
        sliderValue
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .bind(onNext: indexChangedScroll)
            .disposed(by: bag)
        
        cancelButton.rx.tap
            .bind(onNext: { self.viewModel.finish(.canceled) })
            .disposed(by: bag)
        
        confirmButton.rx.tap
            .bind(onNext: { self.viewModel.finish(.confirmed) })
            .disposed(by: bag)
        
        addMoreButton.rx.tap
            .bind(onNext: { self.viewModel.finish(.wantsMore) })
            .disposed(by: bag)
        
    }
    
    
    func preview(result: ReviewViewModel.PreviewResult) {
        var isImage = true
        switch result {
        case .image(let image):
            imageView.image = image
            playerView?.player?.pause()
            playerView?.player = .init()
        case .video(let url):
            isImage = false
            player = .init(url: url)
        }
        imageView.isHidden = !isImage
        playerView.view.isHidden = isImage
    }
    
    
    func clearAndDismiss(result: ReviewViewModel.Result) {
        if result != .confirmed {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
    }
    
    func indexChanged(index: Int) {
        guard countLabel != nil else { return }
        countLabel.text = viewModel.countText
        if !slider.isTracking {
            slider.value = Float(index) / Float(viewModel.numberOfItems - 1)
        }
        viewModel.getPreview(atIndex: index) { result in
            guard index == self.viewModel.currentIndex.value else { return }
            self.preview(result: result)
        }
    }
    
    
    func reload() {
        self.cv?.reloadData()
    }
    
    
    func setViews(hidden: Bool) {
        [view].compactMapAs(UIView.self).forEach {
            $0.transform = .init(scaleX: hidden ? 0.7 : 1.0, y: hidden ? 0.7 : 1.0)
            $0.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if viewModel.numberOfItems == 0 {
            dismiss(animated: false, completion: nil)
            return
        }
        
        setViews(hidden: true)
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.setViews(hidden: false)
        }, completion: nil)
        
        
        titleLabel.text = viewModel.title(forLanguage: "en")
        
        if viewModel.is3d {
            //mainStack.arrangedSubviews.forEach { $0.isHidden = true }
            //imageView.isHidden = false
            //confirmButton.isHidden = true
        }
    }
    
    
    // MARK: - Interaction
    
    var currentIndex: Int {
        return viewModel.currentIndex.value
    }
    
    
    @objc
    func swipe(_ swipe: UISwipeGestureRecognizer) {
        let index = currentIndex + (swipe.direction == .left ? 1 : -1)
        viewModel.currentIndex.v = index.fixOverflow(count: viewModel.numberOfItems)
    }
    
    
    func indexChangedScroll(newIndex: Int) {
        UIView.animate(withDuration: 0.1, animations: {
            self.cv.scrollToItem(at: .init(row: newIndex, section: 0), at: .centeredHorizontally, animated: false)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("Will disappear")
        //UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { self.setViews(hidden: true) }, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        delay(0.01) {
            self.moveSliderIfNeeded()
        }
    }
    
    // MARK: - Interaction
    
    @objc
    func cvTapped(tap: UITapGestureRecognizer) {
        let location = tap.location(in: cv)
        if let i = cv.indexPathForItem(at: location)/*, let cell = cv.cellForItem(at: i)*/{
            viewModel.currentIndex.v = i.row
        }
    }
    
    // MARK: - Layout
    
    func moveSliderIfNeeded() {
        let cvContainer = cv.superview! // the container to be moved
        let landscape = mainStack.frame.width > 400
        let isSeparate = mainStack.arrangedSubviews.contains(cvContainer)
        if landscape && isSeparate {
            cvContainer.removeFromSuperview()
            buttonStack.insertArrangedSubview(cvContainer, at: 1)
        }
        if !landscape && !isSeparate {
            cvContainer.removeFromSuperview()
            let sliderI = mainStack.arrangedSubviews.enumerated().first(where: { $0.element === slider })?.offset
            mainStack.insertArrangedSubview(cvContainer, at: (sliderI ?? 2) + 1)
        }
        cv.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        self.view.layoutIfNeeded()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
