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
import SDWebImageWebPCoder

class AssetScreenViewController: UIViewController {

    private var viewModel: AssetScreenViewModel!
    
    // MARK: - Views
    private let imageScreenView = UIImageView()
    private let movieScreenView = UIView()
    private let presentTrimViewButton = UIButton()
    private let imageOverlayButton = UIButton()
    private let letterboxButton = UIButton()
    private let applyTemplateButton = UIButton()
    private let tempImageView = UIImageView()
    
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
        self.configurePresentTrimViewButtion()
        self.configureImageOverlayButton()
        self.configureLetterboxButton()
        self.configureApplyTemplateButton()
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
    
    private func showLetterboxSuccessAlert() {
        
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
        self.view.addSubview(self.presentTrimViewButton)
        self.view.addSubview(self.imageOverlayButton)
        self.view.addSubview(self.letterboxButton)
        self.view.addSubview(self.applyTemplateButton)
        self.view.addSubview(self.tempImageView)
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
        self.presentTrimViewButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        
        self.imageOverlayButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.view.snp.top).offset(120)
        }
        self.letterboxButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.presentTrimViewButton.snp.bottom).offset(-40)
        }
        self.applyTemplateButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.imageOverlayButton.snp.bottom).offset(20)
        }
        self.tempImageView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.bottom.equalTo(self.applyTemplateButton.snp.bottom)
        }
    }
    
}

// MARK: - Button

extension AssetScreenViewController {

    private func configurePresentTrimViewButtion() {
        self.presentTrimViewButton.addTarget(self, action: #selector(self.presentTrimViewButtonAction), for: .touchUpInside)
        self.presentTrimViewButton.setTitleColor(.systemPink , for: .normal)
        self.presentTrimViewButton.setTitle("Trim", for: .normal)
    }
    
    @objc func presentTrimViewButtonAction() {
        self.viewModel.didPressShowTrimViewButton()
    }
    
    private func configureImageOverlayButton() {
        self.imageOverlayButton.addTarget(self, action: #selector(self.imageOverlayButtonAction), for: .touchUpInside)
        self.imageOverlayButton.setTitleColor(.systemPink, for: .normal)
        self.imageOverlayButton.setTitle("Image Overlay", for: .normal)
    }
    
    @objc func imageOverlayButtonAction() {
        self.viewModel.didAddOverlay(of: UIImage(named: "overlay")) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.showOverlaySuccessAlert()
            case .failure(let error):
                self.showErrorAlert()
            }
        }
    }
    
    private func configureLetterboxButton() {
        self.letterboxButton.addTarget(self, action: #selector(self.letterboxButtonAction), for: .touchUpInside)
        self.letterboxButton.setTitleColor(.systemPink, for: .normal)
        self.letterboxButton.setTitle("Letterbox", for: .normal)
    }
    
    @objc func letterboxButtonAction() {
        self.viewModel.didApplyLetterBox { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.showLetterboxSuccessAlert()
            case .failure(let error):
                self.showErrorAlert()
            }
        }
    }
    
    private func configureApplyTemplateButton() {
        self.applyTemplateButton.addTarget(self, action: #selector(self.applyTemplateButtonAction), for: .touchUpInside)
        self.applyTemplateButton.setTitle("Template", for: .normal)
    }
    
    @objc func applyTemplateButtonAction() {
        let webPCoder = SDImageWebPCoder.shared
        SDImageCodersManager.shared.addCoder(webPCoder)
        let webPUrl: URL? = URL(string: "https://kr.bandisoft.com/honeycam/help/file_format/sample.webp")
        tempImageView.sd_setImage(with: webPUrl)
    }
    
}

extension AssetScreenViewController {
    
    private func configureView() {
        self.view.backgroundColor = .white
    }
    
}
