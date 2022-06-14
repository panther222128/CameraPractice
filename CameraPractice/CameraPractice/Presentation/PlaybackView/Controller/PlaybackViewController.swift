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
    private let movieActionButton = UIButton()
    private let showEditViewButton = UIButton()
    
    private var isPlayingMovie = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        self.view.addSubview(self.movieActionButton)
        self.view.addSubview(self.showEditViewButton)
    }
    
    private func configureLayout() {
        self.movieActionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
    }
    
}

// MARK: - Button

extension PlaybackViewController {

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
        
    }
    
}
