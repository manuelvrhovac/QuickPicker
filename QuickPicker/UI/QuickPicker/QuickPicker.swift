//
//  SmartSelectVC.swift
//  Wideshow4
//
//  Created by Manuel Vrhovac on 01/07/2018.
//  Copyright © 2018 Manuel Vrhovac. All rights reserved.
//

import UIKit
import Photos
import RxSwift
import RxCocoa

public class QuickPicker: UIViewController {
    
    
    // MARK: - IBOutlets
    
    weak var viewModel: QuickPickerModel!
    var bag: DisposeBag = .init()
    var toolbar: QPToolbarView!
    
    @IBOutlet private weak var containerStack: UIStackView!
    @IBOutlet private(set) weak var toolbarContainerStack: UIView!

    // MARK: - Private properties
    
    private var navigationControllers = [TabKind: UINavigationController]()
    
    var allItemViews: [ItemView] {
        return navigationControllers
            .flatMap { $0.value.viewControllers }
            .compactMap { $0.view as? ItemView }
    }
    
    
    var itemViews: [ItemView] {
        return selectedNavigationController.viewControllers.map { $0.view }.compactMapAs(ItemView.self)
    }
    
    var albumViews: [AlbumView] {
        return selectedNavigationController.viewControllers.map { $0.view }.compactMapAs(AlbumView.self)
    }
    
    private var selectedItemViewController: ItemView? {
        return itemViews.first
    }

    private var selectedNavigationController: UINavigationController {
        return navigationControllers[viewModel.selectedAlbumKind.value]!
    }
    
    
    // MARK: - Initialization
    
    public static func fromStoryboard(viewModel: QuickPickerModel) -> QuickPicker {
        let qp = QuickPicker.initi(storyboarddName: nil, bundle: bundle)!
        qp.viewModel = viewModel
        return qp
    }
    
    
    // MARK: - ViewController Lifecycle
    
    func createAndBindViewController(with kind: TabKind) -> UIViewController {
        switch viewModel.itemOrAlbumViewModels[kind]! {
        case let ivm as ItemViewModel:
            return createAndBindItemViewController(with: ivm)
        case let avm as AlbumViewModel:
            return createAndBindAlbumViewController(with: avm)
        default: fatalError("unknown view model")
        }
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.tintColor = viewModel.tintColor
        
        for kind in viewModel.tabs {
            let vc: UIViewController = createAndBindViewController(with: kind)
            let nc = CTNavigationController(customToolbarView: nil, rootViewController: vc)
            nc.setToolbarHidden(false, animated: true)
            navigationControllers[kind] = nc
            containerStack.addArrangedSubview(nc.view)
        }
        
        // Now add the toolbar to toolbarContainer:
        
        let toolbarViewModel = QPToolbarViewModel(quickPickerModel: viewModel)
        
        toolbar = QPToolbarView.initFromNib(viewModel: toolbarViewModel)
        toolbar.qpm = viewModel
        toolbarContainerStack.addSubview(toolbar)
        toolbar.snapToSuperview()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        // Bind views:
        
        viewModel.userError.bind(onNext: displayUserError).disposed(by: bag)
        
        
        viewModel.itemViewModels.bind(onNext: { ivms in
            guard let itemViewModel = ivms.last else { return }
            let vc = self.createAndBindItemViewController(with: itemViewModel)
            self.selectedNavigationController.pushViewController(vc, animated: true)
        }).disposed(by: bag)
        
        
        viewModel.reviewViewModel.bind(onNext: { rvm in
            guard let rvm = rvm else { return }
            let rvc = ReviewViewController.initi(viewModel: rvm)
            self.present(rvc, animated: false, completion: nil)
        }).disposed(by: bag)
        
        viewModel.onFinish.bind(onNext: { _ in
            self.clear()
        }).disposed(by: bag)
        
        viewModel.selectedAlbumKind.accept(viewModel.tabs.first!)
        viewModel.selectedAlbumKind.bind(onNext: albumKindChanged).disposed(by: bag)
        toolbar.segment.selectedSegmentIndex = 0
        
        delay(0.1) {
            self.toolbar.segment.selectedSegmentIndex = 0
        }
    }
    
    
    func createAndBindItemViewController(with itemViewModel: ItemViewModel) -> UIViewController {
        let itemView = ItemView(viewModel: itemViewModel)
        var vc = UIViewController(nibName: nil, bundle: nil)
        vc.navigationItem.insertRightBarButtonItem(createCancelButton(), at: 0)
        if viewModel.selectionMode != .single {
            vc.navigationItem.addRightBarButtonItem(itemView.selectAllBarButtonItem)
        }
        vc.view = itemView
        itemViewModel.title.bind(to: vc.rx.title).disposed(by: bag)
        
        return vc
    }
    
    func createAndBindAlbumViewController(with albumViewModel: AlbumViewModel) -> UIViewController {
        let albumView = AlbumView(viewModel: albumViewModel)
        let vc = UIViewController(nibName: nil, bundle: nil)
        vc.navigationItem.insertRightBarButtonItem(createCancelButton(), at: 0)
        vc.view = albumView
        vc.title = albumViewModel.title
        return vc
    }
    
    
    func clear() {
        self.dismiss(animated: true, completion: nil)
        //viewModel = nil
        //bag = DisposeBag()
    }
    
    func albumKindChanged(albumKind: TabKind) {
        for nc in self.navigationControllers.values {
            nc.view.isHidden = nc !== self.selectedNavigationController
        }
        guard !self.navigationControllers.isEmpty else { return }
        let nc = self.selectedNavigationController as! CTNavigationController
        // Migrate toolbar to this view:
        nc.customToolbarView = toolbar
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let offset = UIScreen.main.bounds.height
        UIView.animate(withDuration: 0.4, animations: {
            self.view.transform = .init(translationX: 0.0, y: offset)
            self.presentedViewController?.view.transform = self.view.transform
        }, completion: { _ in
            mainThread {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                super.dismiss(animated: false, completion: completion)
            }
        })
    }
    
    deinit {
        print("Deinit")
    }
    
    func displayUserError(_ error: String?) {
        guard let error = error else { return }
        print(error)
        displayOverLimitMessage()
    }
    
    
    @objc
    func applicationDidBecomeActive() {
        print("App is active again!")
        /*for selection in selections {
            for asset in selection {
                if asset.
            }
        }*/
        removeDeletedAssetsFromUndoStack()
        
        
        allItemViews.forEach { $0.viewModel.reloadCollection() }
    }
    
    func removeDeletedAssetsFromUndoStack() {
        var allAssets = Set<PHAsset>()
        let d = Date()
        let selections = viewModel.selectionStack.value
        selections.forEach { allAssets.formUnion($0) }
        let allAssetsExist = PHAsset.fetchAndCheckIfAllAssetsExist(allAssets.map { $0 })
        print("Now:", Date().msSince(d))
        guard !allAssetsExist else { return }
        print("Some assets have been deleted!")
        let deletedAssets = allAssets.filter { !$0.existsInPhotos }
        for asset in deletedAssets {
            let thumb = PHImageManager.default().getThumbnail(for: asset)!
            print("asset \(asset.creationDate!): \(thumb.size)")
        }
        let clearedSelections = selections.map { $0.subtracting(deletedAssets) }
        viewModel.selectionStack.accept(clearedSelections)
        
    }
    
    
    func createCancelButton() -> ImageBarButtonItem {
        let cancelButton = ImageBarButtonItem(buttonImage: UIImage(bundleNamed: "cancel").template,
                                              size: CGSize(width: 30.0, height: 30.0))
        cancelButton.button.rx.tap.bind(onNext: viewModel.cancel).disposed(by: bag)
        return cancelButton
    }
    
    
    // MARK: Layout
    

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    

    // MARK: - UI
    
    private func displayOverLimitMessage() {
        guard case .multiple(let max) = viewModel.selectionMode else { return }
        let alert = UIAlertController(title: "Maximum \(max) items", message: "You have selected more items than allowed", preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        mainThread {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
