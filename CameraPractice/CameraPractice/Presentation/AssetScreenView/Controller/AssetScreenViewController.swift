//
//  PlaybackViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import AVFoundation
import SnapKit
import Photos

class AssetScreenViewController: UIViewController {

    private var viewModel: AssetScreenViewModel!
    
    // MARK: - Views
    private let imageScreenView = UIImageView()
    private let movieScreenView = UIView()
    private let movieActionButton = UIButton()
    private let showEditViewButton = UIButton()
    
    // MARK: - Media
    private let avPlayer = AVPlayer()
    private var avPlayerLayer: AVPlayerLayer?
    private var phAssetMediaType: PHAssetMediaType?
    
    private var isPlayingMovie = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind()
        self.requestAsset()
        self.addSubviews()
        self.configureLayout()
        self.configureView()
        self.configureMovieActionButtion()
        self.configureShowEditViewButton()
    }
    
    static func create(with viewModel: AssetScreenViewModel) -> AssetScreenViewController {
        let viewController = AssetScreenViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func bind() {
        self.viewModel.phAssetMediaType.bind { [weak self] assetMediaType in
            guard let self = self else { return }
            self.phAssetMediaType = assetMediaType
        }
    }
    
}

// MARK: - Request asset

extension AssetScreenViewController {
    
    private func requestAsset() {
        self.viewModel.fetchAssetCollection()
        self.viewModel.checkAssetMediaType()
        switch self.phAssetMediaType {
        case .image:
            self.viewModel.requestImage(size: CGSize(width: self.view.frame.width, height: self.view.frame.height)) { image, error in
                guard let image = image else { return }
                self.imageScreenView.image = image
            }
        case .video:
            self.viewModel.requestVideo { video, error in
                guard let video = video else { return }
                self.avPlayer.replaceCurrentItem(with: video)
                let avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
                avPlayerLayer.frame = self.movieScreenView.frame
                avPlayerLayer.videoGravity = .resizeAspect
                self.avPlayerLayer = avPlayerLayer
                guard let avPlayerLayer = self.avPlayerLayer else { return }
                self.movieScreenView.layer.addSublayer(avPlayerLayer)
                self.avPlayer.play()
            }
        default:
            self.viewModel.requestImage(size: CGSize(width: self.view.frame.width, height: self.view.frame.height)) { image, error in
                guard let image = image else { return }
                self.imageScreenView.image = image
            }
        }
    }
    
}

// MARK: - AddSubviews and Layout

extension AssetScreenViewController {

    private func addSubviews() {
        if let phAssetMediaType = self.phAssetMediaType {
            switch phAssetMediaType {
            case .image:
                self.view.addSubview(self.imageScreenView)
            case .video:
                self.view.addSubview(self.movieScreenView)
            default:
                self.view.addSubview(self.imageScreenView)
            }
        }
        self.view.addSubview(self.movieActionButton)
        self.view.addSubview(self.showEditViewButton)
    }
    
    private func configureLayout() {
        guard let phAssetMediaType = self.phAssetMediaType else { return }
        switch phAssetMediaType {
        case .image:
            self.imageScreenView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        case .video:
            self.movieScreenView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        default:
            self.imageScreenView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
        self.movieActionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        self.showEditViewButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.view.snp.top).offset(120)
        }
    }
    
}

// MARK: - Button

extension AssetScreenViewController {

    private func configureMovieActionButtion() {
        self.movieActionButton.addTarget(self, action: #selector(self.movieActionButtonAction), for: .touchUpInside)
        self.movieActionButton.setTitleColor(.white, for: .normal)
        if self.isPlayingMovie {
            self.movieActionButton.setTitle("Pause", for: .normal)
        } else {
            self.movieActionButton.setTitle("Start", for: .normal)
        }
    }
    
    @objc func movieActionButtonAction() {
        
    }
    
    private func configureShowEditViewButton() {
        self.showEditViewButton.addTarget(self, action: #selector(self.showEditViewButtonAction), for: .touchUpInside)
        self.showEditViewButton.setTitleColor(.white, for: .normal)
        self.showEditViewButton.setTitle("Edit", for: .normal)
    }
    
    @objc func showEditViewButtonAction() {
        self.viewModel.didAddOverlay { asset in
            if let asset = asset {
                
            }
        }
    }
    
}

extension AssetScreenViewController {
    
    private func configureView() {
        self.view.backgroundColor = .white
    }
    
}
