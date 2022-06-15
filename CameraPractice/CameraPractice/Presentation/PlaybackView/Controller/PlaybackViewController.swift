//
//  PlaybackViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import AVFoundation
import SnapKit

class PlaybackViewController: UIViewController {

    private var viewModel: PlaybackViewModel!
    
    private let mediaScreenView = MediaScreenView()
    private let imageScreenView = UIImageView()
    private let movieActionButton = UIButton()
    private let showEditViewButton = UIButton()
    
    private var isPlayingMovie = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        self.addSubviews()
        self.configureLayout()
        self.configureMovieActionButtion()
        self.configureShowEditViewButton()
    }
    
    static func create(with viewModel: PlaybackViewModel) -> PlaybackViewController {
        let viewController = PlaybackViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
}

// MARK: - AddSubviews and Layout

extension PlaybackViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.mediaScreenView)
        self.view.addSubview(self.movieActionButton)
        self.view.addSubview(self.showEditViewButton)
    }
    
    private func configureLayout() {
        self.mediaScreenView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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

extension PlaybackViewController {

    private func configureMovieActionButtion() {
        self.movieActionButton.addTarget(self, action: #selector(self.movieActionButtonAction), for: .touchUpInside)
        self.movieActionButton.setTitleColor(.black, for: .normal)
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
        self.showEditViewButton.setTitleColor(.black, for: .normal)
        self.showEditViewButton.setTitle("Edit", for: .normal)
    }
    
    @objc func showEditViewButtonAction() {
        
    }
    
}

extension PlaybackViewController {
    
    private func configureView() {
        self.view.backgroundColor = .white
    }
    
}
