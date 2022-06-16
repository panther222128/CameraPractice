//
//  MediaPickerViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos
import SnapKit

class MediaPickerViewController: UIViewController {
    
    private var viewModel: MediaPickerViewModel!
    
    lazy var assetsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let assetsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return assetsCollectionView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.assetsCollectionView.dataSource = self
        self.assetsCollectionView.delegate = self
        self.registerCellID()
        self.addSubviews()
        self.configureLayout()
        self.fetchAssets()
        self.bind()
    }
    
    static func create(with viewModel: MediaPickerViewModel) -> MediaPickerViewController {
        let viewController = MediaPickerViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func bind() {
        self.viewModel.phAssetsRequestResult.bind { [weak self] assets in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.assetsCollectionView.reloadData()
            }
        }
    }
    
    private func fetchAssets() {
        DispatchQueue.main.async {
            self.viewModel.fetchAssetCollection()
        }
    }
    
}

// MARK: - AddSubviews, layout, cellID

extension MediaPickerViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.assetsCollectionView)
    }
    
    private func configureLayout() {
        self.assetsCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func registerCellID() {
        self.assetsCollectionView.register(AssetsCollectionViewCell.self, forCellWithReuseIdentifier: "AssetsCollectionViewCellID")
    }
    
}

extension MediaPickerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let phAssetsRequestResult = self.viewModel.phAssetsRequestResult
        guard let value = phAssetsRequestResult.value else { return  -1 }
        let count = value.count
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetsCollectionViewCellID", for: indexPath) as? AssetsCollectionViewCell else { return UICollectionViewCell() }
        self.viewModel.requestImage(at: indexPath.row, size: CGSize(width: cell.frame.width, height: cell.frame.width)) { image, error in
            guard let image = image else { return }
            cell.configureViews(from: image)
        }
        return cell
    }
    
}

extension MediaPickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let asset = self.viewModel.phAssetsRequestResult.value else { return }
        self.viewModel.didSelectItem(at: indexPath.row, isPhoto: asset[indexPath.row].mediaType == .image)
    }
    
}

extension MediaPickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let width = collectionView.frame.width
        let height = collectionView.frame.height
        let itemsPerRow: CGFloat = 2
        let widthPadding = sectionInsets.left * (itemsPerRow + 1)
        let itemsPerColumn: CGFloat = 3
        let heightPadding = sectionInsets.top * (itemsPerColumn + 1)
        let cellWidth = (width - widthPadding) / itemsPerRow
        let cellHeight = (height - heightPadding) / itemsPerColumn
        
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
}
