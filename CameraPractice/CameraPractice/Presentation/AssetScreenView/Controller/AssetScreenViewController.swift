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
    private let showTrimViewButton = UIButton()
    private let showEditViewButton = UIButton()
    private let metaboxButton = UIButton()
    
    // MARK: - Media
    private let moviePlayer = AVPlayer()
    private var moviePlayerLayer: AVPlayerLayer?
    private var assetMediaType: PHAssetMediaType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind()
        self.requestAsset()
        self.addSubviews()
        self.configureLayout()
        self.configureView()
        self.configureShowTrimViewButtion()
        self.configureShowEditViewButton()
        self.configureMetaboxButton()
    }
    
    static func create(with viewModel: AssetScreenViewModel) -> AssetScreenViewController {
        let viewController = AssetScreenViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func bind() {
        self.viewModel.assetMediaType.bind { [weak self] assetMediaType in
            guard let self = self else { return }
            self.assetMediaType = assetMediaType
        }
    }
    
    private func showOverlaySuccessAlert() {
        
    }
    
    private func showErrorAlert() {
        
    }
    
}

// MARK: - Request asset

extension AssetScreenViewController {
    
    private func requestAsset() {
        self.viewModel.fetchAssetCollection()
        self.viewModel.checkAssetMediaType()
        switch self.assetMediaType {
        case .image:
            self.viewModel.requestImage(size: CGSize(width: self.view.frame.width, height: self.view.frame.height)) { [weak self] image, error in
                guard let self = self else { return }
                guard let image = image else { return }
                self.imageScreenView.image = image
            }
        case .video:
            self.viewModel.requestVideo { [weak self] video, error in
                guard let self = self else { return }
                guard let video = video else { return }
                self.moviePlayer.replaceCurrentItem(with: video)
                let playerLayer = AVPlayerLayer(player: self.moviePlayer)
                playerLayer.frame = self.movieScreenView.frame
                playerLayer.videoGravity = .resizeAspect
                self.moviePlayerLayer = playerLayer
                guard let playerLayer = self.moviePlayerLayer else { return }
                self.movieScreenView.layer.addSublayer(playerLayer)
                self.moviePlayer.play()
            }
        default:
            self.viewModel.requestImage(size: CGSize(width: self.view.frame.width, height: self.view.frame.height)) { [weak self] image, error in
                guard let self = self else { return }
                guard let image = image else { return }
                self.imageScreenView.image = image
            }
        }
    }
    
}

// MARK: - AddSubviews and Layout

extension AssetScreenViewController {

    private func addSubviews() {
        if let assetMediaType = self.assetMediaType {
            switch assetMediaType {
            case .image:
                self.view.addSubview(self.imageScreenView)
            case .video:
                self.view.addSubview(self.movieScreenView)
            default:
                self.view.addSubview(self.imageScreenView)
            }
        }
        self.view.addSubview(self.showTrimViewButton)
        self.view.addSubview(self.showEditViewButton)
        self.view.addSubview(self.metaboxButton)
    }
    
    private func configureLayout() {
        guard let assetMediaType = self.assetMediaType else { return }
        switch assetMediaType {
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
        self.showTrimViewButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        
        self.showEditViewButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.view.snp.top).offset(120)
        }
        self.metaboxButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.showTrimViewButton.snp.bottom).offset(-20)
        }
    }
    
}

// MARK: - Button

extension AssetScreenViewController {

    private func configureShowTrimViewButtion() {
        self.showTrimViewButton.addTarget(self, action: #selector(self.showTrimViewAction), for: .touchUpInside)
        self.showTrimViewButton.setTitleColor(.systemPink , for: .normal)
        self.showTrimViewButton.setTitle("Trim", for: .normal)
    }
    
    @objc func showTrimViewAction() {
        self.viewModel.didPressShowTrimViewButton()
    }
    
    private func configureShowEditViewButton() {
        self.showEditViewButton.addTarget(self, action: #selector(self.showEditViewButtonAction), for: .touchUpInside)
        self.showEditViewButton.setTitleColor(.systemPink, for: .normal)
        self.showEditViewButton.setTitle("Image Overlay", for: .normal)
    }
    
    @objc func showEditViewButtonAction() {
        self.viewModel.didAddOverlay(of: UIImage(named: "overlay")) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.viewModel.didSaveMovie(url: url)
                self.showOverlaySuccessAlert()
            case .failure(let error):
                self.showErrorAlert()
            }
        }
    }
    
    private func configureMetaboxButton() {
        self.metaboxButton.addTarget(self, action: #selector(self.metaboxButtonAction), for: .touchUpInside)
        self.metaboxButton.setTitleColor(.systemPink, for: .normal)
        self.metaboxButton.setTitle("Metabox", for: .normal)
    }
    
    @objc func metaboxButtonAction() {

    }
    
}

extension AssetScreenViewController {
    
    private func configureView() {
        self.view.backgroundColor = .white
    }
    
}
