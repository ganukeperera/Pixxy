//
//  PhotoCollectionViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/3/23.
//

import UIKit
import Combine

private let reuseIdentifier = Constant.CellReuseId.photoCollectionCellID

class PhotoCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var cancellables = Set<AnyCancellable>()
    var photoCollectionViewModel: PhotoCollectionViewModel?
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        self.clearsSelectionOnViewWillAppear = false
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    private func setupViewModel() {
        guard let photoCollectionViewModel = photoCollectionViewModel else {
            fatalError("photo collection view model is not set in PhotoCollectionViewController")
        }

        photoCollectionViewModel.$isPhotosLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.isHidden = false
                    self?.activityIndicator.startAnimating()
                    
                }else {
                    self?.activityIndicator.isHidden = true
                    self?.activityIndicator.stopAnimating()
                    
                }
            }.store(in: &cancellables)
        
        photoCollectionViewModel.$reloadPhotoCollection
            .receive(on: RunLoop.main)
            .sink { [weak self] reloadCollection in
                if reloadCollection {
                    self?.collectionView.reloadData()
                }
            }.store(in: &cancellables)
        
        photoCollectionViewModel.fetchPhotos()
    }
    
    
    //MARK: - Collection View DataSource Methods
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return photoCollectionViewModel?.numberOfPhotos ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("PhotoCollectionViewCell is not found")
        }
        cell.photoViewModel = photoCollectionViewModel?.getPhotoViewModel(at: indexPath.row)
        return cell
    }
}

class PhotoCollectionViewCell: UICollectionViewCell{
    
    @IBOutlet weak var thumbinailImage: UIImageView!
    var photoViewModel: PhotoViewModel? {
        didSet{
            guard let url = photoViewModel?.thumbnailUrl else {
                thumbinailImage.image = UIImage(named: "brokenImage")
                return
            }
            let placehoderImage = UIImage(named: "placeholderImage")
            thumbinailImage.loadImageFrom(url, placehoderImage)
        }
    }
}
