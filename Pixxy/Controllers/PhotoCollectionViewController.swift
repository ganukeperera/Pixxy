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
    
    //MARK: - Properties
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var cancellables = Set<AnyCancellable>()
    private var photoDetailViewModelForSelectedCell: PhotoDetailViewModel?
    var photoCollectionViewModel: PhotoCollectionViewModel?
    private var selecteIndex: IndexPath?
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    //MARK: - Layout Related
    private func setupView() {
        self.clearsSelectionOnViewWillAppear = false
        navigationItem.largeTitleDisplayMode = .never
        title = photoCollectionViewModel?.albumTitle.capitalized ?? ""
    }
    
    //MARK: - ViewModel Bindings
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
        
        photoCollectionViewModel.$showErroMessage
            .receive(on: RunLoop.main)
            .sink {[weak self] showMessage in
                if showMessage {
                    self?.showAlertMessage()
                }
            }
            .store(in: &cancellables)
        
        photoCollectionViewModel.fetchPhotos()
    }
    
    //MARK: - Utility Methods
    private func showAlertMessage() {
        guard let photoCollectionViewModel = photoCollectionViewModel else {
            return
        }
        if let alertMessage = photoCollectionViewModel.errorMessage {
            let alert = UIAlertController(title: NSLocalizedString("Alert.Title.Error", comment: "error"), message: alertMessage, preferredStyle: .alert)
            if photoCollectionViewModel.isRetryAllowed {
                let alertAction = UIAlertAction(title: NSLocalizedString("Alert.Action.Retry", comment: "Retry"), style: .default) { action in
                    photoCollectionViewModel.retryAction()
                }
                alert.addAction(alertAction)
            }
            let alertAction = UIAlertAction(title: NSLocalizedString("Alert.Action.Ok", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(alertAction)
            present(alert, animated: true)
        }
    }
    
    //This method developed to support UI testing to run without network access
    private func getPhotoService() -> ResourceLoader {
        var photoService: ResourceLoader!
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MockService") {
            photoService = MockPhotoService(photoType: .originalImage)
        }else {
            
            photoService = PhotoService()
        }
#else
        photoService = PhotoService()
#endif
        return photoService
    }
    
    //MARK: - UIStoryboardSegue Handling
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
    
    //MARK: - UICollectionViewDataSource Methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoCollectionViewModel?.numberOfPhotos ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PhotoCollectionViewCell else {
            fatalError("PhotoCollectionViewCell is not found")
        }
        cell.photoViewModel = photoCollectionViewModel?.getPhotoViewModel(at: indexPath.row)
        cell.setup()
        cell.accessibilityIdentifier = "PhotoCell_\(indexPath.section)_\(indexPath.row)" //For UITesting
        return cell
    }
    
    //MARK: - UIViewDelegate methods
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedPhotoViewModel = photoCollectionViewModel?.getPhotoViewModel(at: indexPath.row) else {
            assertionFailure("Selected item not found in PhotoCollectinVC")
            return
        }
        selecteIndex = indexPath
        photoDetailViewModelForSelectedCell = PhotoDetailViewModel(photoURL: selectedPhotoViewModel.url, photoTitle: selectedPhotoViewModel.title, photoService: self.getPhotoService())
        performSegue(withIdentifier: Constant.SegueIdentifier.toPhotoDetailVC, sender: self)
    }
}

//MARK: - UICollectionViewDelegateFlowLayout Extenstion
//This extention was created to fix the number of collection view cells for row when running in different devices
//Number of cell for row can be configured in Constants.swift class
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

//MARK: - ZoomingViewController extension
//This extension developed to make PhotoCollectionViewController conform to ZoomingViewController which is required get a zooming effect when viewing 600x600 by clicking on thumbinail image
extension PhotoCollectionViewController: ZoomingViewController {
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        if let indexPath = selecteIndex, let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
            return cell.thumbinailImageView
        }
        return nil
    }
}

//MARK: - Custom UICollectionViewCell
class PhotoCollectionViewCell: UICollectionViewCell{
    
    //MARK: - Properties
    @IBOutlet weak var thumbinailImageView: UIImageView!
    var photoViewModel: PhotoViewModel?
    var cancellables = Set<AnyCancellable>()
    
    //MARK: - View Life Cycle
    func setup() {
        setupView()
        setupViewModel()
    }
    
    //MARK: - Layout Related
    private func setupView() {
        let placeholderImage = UIImage(named: "placeholderImage")
        thumbinailImageView.image = placeholderImage
    }
    
    //Remove all cancellables befor reusing the cell
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }
    
    //MARK: - ViewModel Bindings
    private func setupViewModel() {
        guard let photoViewModel = photoViewModel else {
            return
        }
        photoViewModel.$imageData
            .sink { [weak self] data in
                DispatchQueue.main.async {
                    guard let data = data, let image = UIImage(data: data) else{
                        if let _ = data {
                            //Received data cannot be converted to a image. So showing a broken image
                            let placeholderImage = UIImage(named: "brokenImage")
                            self?.thumbinailImageView.image = placeholderImage
                        }
                        return
                    }
                    self?.thumbinailImageView.image = image
                }
            }.store(in: &cancellables)
        
        photoViewModel.$imageDownloadFailed
            .sink { [weak self] downloadFailed in
                if downloadFailed {
                    DispatchQueue.main.async {
                        let placeholderImage = UIImage(named: "brokenImage")
                        self?.thumbinailImageView.image = placeholderImage
                    }
                }
            }.store(in: &cancellables)
        
        photoViewModel.fetchPhotoData()
    }
}
