//
//  PhotoDetailViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/5/23.
//

import UIKit
import Combine

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var photoImage: UIImageView!
    var photoDetailViewMode: PhotoDetailViewModel?
    var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }

    private func setupView() {
        let placeholderImage = UIImage(named: "placeholderImage")
        photoImage.image = placeholderImage
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
                        self?.photoImage.image = brokenImage
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
                    self?.photoImage.image = image
                }
            }
        photoDetailViewMode.fetchPhotoData()
    }
}
