//
//  AssetsCollectionViewCell.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/15.
//

import UIKit
import SnapKit
import Photos

class AssetsCollectionViewCell: UICollectionViewCell {

    private let assetImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubviews()
        self.configureLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addSubviews()
        self.configureLayout()
    }
    
    func configureViews(from assetImage: UIImage) {
        self.assetImageView.image = assetImage
    }
    
}

// MARK: - Addsubviews and layout

extension AssetsCollectionViewCell {
    
    private func addSubviews() {
        self.addSubview(self.assetImageView)
    }
    
    private func configureLayout() {
        self.assetImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}
