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
    private var selecteIndex: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        self.clearsSelectionOnViewWillAppear = false
        navigationItem.largeTitleDisplayMode = .never
        title = photoCollectionViewModel?.albumTitle.capitalized ?? ""
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.SegueIdentifier.toPhotoDetailVC
            {
                if let destinationVC = segue.destination as? PhotoDetailViewController {
                    if let indexPath = selecteIndex, let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
                        destinationVC.placeHolderImage = cell.thumbinailImageView.image
                    }
                    destinationVC.photoDetailViewMode = photoDetailViewModelForSelectedCell
                }
            }
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
        selecteIndex = indexPath
        photoDetailViewModelForSelectedCell = PhotoDetailViewModel(photoURL: selectedPhotoViewModel.url, photoTitle: selectedPhotoViewModel.title)
        performSegue(withIdentifier: Constant.SegueIdentifier.toPhotoDetailVC, sender: self)
    }
}

extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let noOfCellsInRow = Constant.ViewConfig.numberofPhotosForRow
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        return CGSize(width: size, height: size)
    }
}

extension PhotoCollectionViewController: ZoomingViewController {
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        if let indexPath = selecteIndex, let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
            return cell.thumbinailImageView
        }
        return nil
    }
}

class PhotoCollectionViewCell: UICollectionViewCell{
    
    @IBOutlet weak var thumbinailImageView: UIImageView!
    var photoViewModel: PhotoViewModel?
    var cancellable: AnyCancellable?
    
    func setup() {
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        let placeholderImage = UIImage(named: "placeholderImage")
        thumbinailImageView.image = placeholderImage
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
                        self?.thumbinailImageView.image = brokenImage
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
                    self?.thumbinailImageView.image = image
                }
            }
        photoViewModel.fetchPhotoData()
    }
}
