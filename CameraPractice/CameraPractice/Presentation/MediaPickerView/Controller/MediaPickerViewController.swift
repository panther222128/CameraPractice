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
    private let combineMovieButton = UIButton()
    private var isCombineMode: Bool = false
    private var selectedIndex = [IndexPath]()
    lazy var combineModeSegmentedControl: UISegmentedControl = {
        let combineModeSegmentedControl = UISegmentedControl(items: ["Default", "Combine Mode"])
        combineModeSegmentedControl.selectedSegmentIndex = 0
        return combineModeSegmentedControl
    }()
    lazy var assetCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let assetsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        return assetsCollectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind()
        self.assetCollectionView.dataSource = self
        self.assetCollectionView.delegate = self
        self.registerCellID()
        self.addSubviews()
        self.configureLayout()
        self.configureCombineMovieButton()
        self.configureCombineModeSegmentedControl()
        self.fetchAssets()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.assetCollectionView.reloadData()
        }
    }
    
    static func create(with viewModel: MediaPickerViewModel) -> MediaPickerViewController {
        let viewController = MediaPickerViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func bind() {
        self.viewModel.assetsRequestResult.bind { [weak self] assets in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.assetCollectionView.reloadData()
            }
        }
    }
    
    private func fetchAssets() {
        DispatchQueue.main.async {
            self.viewModel.fetchAssetCollection()
        }
    }
    
    private func showCombineSuccessAlert() {
        
    }
    
    private func showErrorAlert(errorMessage: String) {
        DispatchQueue.main.async {
            let authorizationAlert = UIAlertController(title: "오류 발생", message: "\(errorMessage)", preferredStyle: UIAlertController.Style.alert)
            let addAuthorizationAlertAction = UIAlertAction(title: "OK", style: .default)
            authorizationAlert.addAction(addAuthorizationAlertAction)
            self.present(authorizationAlert, animated: true, completion: nil)
        }
    }

}

// MARK: - CombineMovieButton

extension MediaPickerViewController {
    
    private func configureCombineMovieButton() {
        self.combineMovieButton.addTarget(self, action: #selector(self.combineMovieButtonAction), for: .touchUpInside)
        self.combineMovieButton.setTitle("Combine", for: .normal)
    }
    
    @objc func combineMovieButtonAction() {
        let assetIndex = self.selectedIndex.map( { $0.row } )
        self.viewModel.didCombineMovies(assetIndex: assetIndex) { result in
            switch result {
            case .success(let url):
                self.showCombineSuccessAlert()
            case .failure(let error):
                self.showErrorAlert(errorMessage: error.localizedDescription)
            }
        }
    }
    
}

// MARK: - CombineModeSegmentedControl

extension MediaPickerViewController {
    
    private func configureCombineModeSegmentedControl() {
        self.combineModeSegmentedControl.addTarget(self, action: #selector(self.setCombineMode), for: .valueChanged)
        self.combineModeSegmentedControl.layer.borderWidth = 2
        self.combineModeSegmentedControl.layer.borderColor = UIColor.systemPink.cgColor
    }
    
    @objc func setCombineMode(segment: UISegmentedControl) {
        switch segment.selectedSegmentIndex {
        case 0:
            self.isCombineMode = false
        case 1:
            self.isCombineMode = true
            self.assetCollectionView.isEditing = true
            self.assetCollectionView.allowsSelectionDuringEditing = true
            self.assetCollectionView.allowsMultipleSelectionDuringEditing = true
        default:
            self.isCombineMode = false
        }
    }
    
}

// MARK: - Add subviews, layout, cellID

extension MediaPickerViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.assetCollectionView)
        self.view.addSubview(self.combineModeSegmentedControl)
        self.view.addSubview(self.combineMovieButton)
    }
        
    private func configureLayout() {
        self.assetCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        self.combineModeSegmentedControl.snp.makeConstraints {
            $0.leading.equalTo(self.view.snp.leading).offset(100)
            $0.top.equalTo(self.view.snp.top).offset(80)
            $0.trailing.equalTo(self.view.snp.trailing).offset(-100)
            $0.height.equalTo(38)
        }
        self.combineMovieButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
    }
    
    private func registerCellID() {
        self.assetCollectionView.register(AssetsCollectionViewCell.self, forCellWithReuseIdentifier: "AssetsCollectionViewCellID")
    }
    
}

extension MediaPickerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let assetsRequestResult = self.viewModel.assetsRequestResult
        guard let value = assetsRequestResult.value else { return  -1 }
        let count = value.count
        return count
    }
    
    // MARK: - Need to error handling
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetsCollectionViewCellID", for: indexPath) as? AssetsCollectionViewCell else { return UICollectionViewCell() }
        self.viewModel.requestImage(at: indexPath.row, size: CGSize(width: cell.frame.width, height: cell.frame.width)) { image, error in
            guard let image = image else { return }
            cell.configureViews(from: image)
        }
        if self.selectedIndex.contains(indexPath) {
            cell.contentView.layer.borderWidth = 2
            cell.contentView.layer.borderColor = UIColor.systemPink.cgColor
        } else {
            cell.contentView.layer.borderWidth = 0
            cell.contentView.layer.borderColor = nil
        }
        cell.layoutSubviews()
        return cell
    }
    
}

extension MediaPickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isCombineMode {
            self.viewModel.didSelectItem(at: indexPath.row)
        } else {
            if self.selectedIndex.contains(indexPath) {
                self.selectedIndex = self.selectedIndex.filter( { $0 != indexPath } )
            } else {
                self.selectedIndex.append(indexPath)
            }
        }
        collectionView.reloadData()
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
