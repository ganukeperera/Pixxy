//
//  PhotoDetailViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import UIKit
import Combine

class PhotoDetailViewController: UIViewController {
    
    //MARK: - Properties
    @IBOutlet weak var photoImageView: UIImageView!
    var photoDetailViewMode: PhotoDetailViewModel?
    var placeHolderImage: UIImage?
    var cancellables = Set<AnyCancellable>()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }

    //MARK: - Layout Related
    private func setupView() {
        
        let placeholderImage = placeHolderImage ?? UIImage(named: "placeholderImage")
        photoImageView.image = placeholderImage
        title = photoDetailViewMode?.photoTitle ?? ""
    }
    
    //MARK: - ViewModel Bindings
    private func setupViewModel() {
        guard let photoDetailViewMode = photoDetailViewMode else {
            return
        }
        photoDetailViewMode.$imageData
            .sink {[weak self] completion in
                //TODO: kk
                switch completion {
                case .failure:
                    DispatchQueue.main.async {
                        let brokenImage = UIImage(named: "brokenImage")
                        self?.photoImageView.image = brokenImage
                    }
                    break
                case .finished:
                    break
                }
                
            } receiveValue: {[weak self] data in
                DispatchQueue.main.async {
                    guard let data = data, let image = UIImage(data: data) else{
                        return
                    }
                    self?.photoImageView.image = image
                }
            }.store(in: &cancellables)
        
        photoDetailViewMode.$imageDownloadFailed
            .sink { [weak self] downloadFailed in
                if downloadFailed {
                    DispatchQueue.main.async {
                        let brokenImage = UIImage(named: "brokenImageLarge")
                        self?.photoImageView.image = brokenImage
                    }
                }
            }.store(in: &cancellables)
        
        photoDetailViewMode.fetchPhotoData()
    }
}

//MARK: - ZoomingViewController extension
//This extension developed to make PhotoDetailViewController conform to ZoomingViewController which is required get a zooming effect when viewing 600x600 image by clicking on thumbinail image
extension PhotoDetailViewController: ZoomingViewController {
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        return photoImageView
    }
}
