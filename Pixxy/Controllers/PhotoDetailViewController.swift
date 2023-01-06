//
//  PhotoDetailViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import UIKit
import Combine

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var photoImageView: UIImageView!
    var photoDetailViewMode: PhotoDetailViewModel?
    var placeHolderImage: UIImage?
    var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }

    private func setupView() {
        
        let placeholderImage = placeHolderImage ?? UIImage(named: "placeholderImage")
        photoImageView.image = placeholderImage
    }
    
    private func setupViewModel() {
        guard let photoDetailViewMode = photoDetailViewMode else {
            return
        }
        cancellable = photoDetailViewMode.$imageData
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
            }
        photoDetailViewMode.fetchPhotoData()
    }
}

extension PhotoDetailViewController: ZoomingViewController {
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        return photoImageView
    }
}
