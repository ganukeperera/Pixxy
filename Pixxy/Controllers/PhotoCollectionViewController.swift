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
    private var photoDetailViewModelForSelectedCell: PhotoDetailViewModel?
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
        cell.setup()
        return cell
    }
    
    //MARK: - Collection View Delegate method
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedPhotoViewModel = photoCollectionViewModel?.getPhotoViewModel(at: indexPath.row) else {
            //TODO: what to do
            return
        }
        photoDetailViewModelForSelectedCell = PhotoDetailViewModel(photoURL: selectedPhotoViewModel.url)
        performSegue(withIdentifier: Constant.SegueIdentifier.toPhotoDetailVC, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.SegueIdentifier.toPhotoDetailVC
            {
                if let destinationVC = segue.destination as? PhotoDetailViewController {
                    destinationVC.photoDetailViewMode = photoDetailViewModelForSelectedCell
                }
            }
    }
}

class PhotoCollectionViewCell: UICollectionViewCell{
    
    @IBOutlet weak var thumbinailImage: UIImageView!
    var photoViewModel: PhotoViewModel?
    var cancellable: AnyCancellable?
    
    func setup() {
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        let placeholderImage = UIImage(named: "placeholderImage")
        thumbinailImage.image = placeholderImage
    }
    
    private func setupViewModel() {
        guard let photoViewModel = photoViewModel else {
            return
        }
        cancellable = photoViewModel.$imageData
            .sink {[weak self] completion in
                //TODO: kk
                switch completion {
                case .failure:
                    DispatchQueue.main.async {
                        let brokenImage = UIImage(named: "brokenImage")
                        self?.thumbinailImage.image = brokenImage
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
                    self?.thumbinailImage.image = image
                }
            }
        photoViewModel.fetchPhotoData()

    }
}
