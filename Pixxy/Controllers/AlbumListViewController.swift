//
//  ViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/1/23.
//

import UIKit
import Combine

class AlbumListViewController: UIViewController {

    //MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var cancellables = Set<AnyCancellable>()
    var albumListViewModel: AlbumListViewModel!
    private var photoCollectionViewModelForSelectedItem: PhotoCollectionViewModel?
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    //MARK: - Layout Related
    private func setupView() {
        title = NSLocalizedString("AlbumListVC.NavCTRL.Title", comment: "Album")
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    //MARK: - ViewModel Bindings
    private func setupViewModel() {
        
        albumListViewModel.$isAlbumsLoading
            .receive(on: RunLoop.main)
            .sink{ [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.isHidden = false
                    self?.activityIndicator.startAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.tableView.alpha = 0.0
                    })
                }else {
                    self?.activityIndicator.isHidden = true
                    self?.activityIndicator.stopAnimating()
                    UIView.animate(withDuration: 0.2, animations: {
                        self?.tableView.alpha = 1.0
                    })
                }
            }.store(in: &cancellables)
        
        albumListViewModel.$reloadAlbumList
            .receive(on: RunLoop.main)
            .sink{ [weak self] reloadTable in
                if reloadTable {
                    self?.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        albumListViewModel.$showErroMessage
            .receive(on: RunLoop.main)
            .sink {[weak self] showMessage in
                if showMessage {
                    self?.showAlertMessage()
                }
            }
            .store(in: &cancellables)

        
        albumListViewModel.fetchAlbums()
    }
    
    //MARK: - UIStoryboardSegue Handling
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.SegueIdentifier.toPhotoCollectionVC
            {
                if let destinationVC = segue.destination as? PhotoCollectionViewController {
                    destinationVC.photoCollectionViewModel = photoCollectionViewModelForSelectedItem
                }
            }
    }
    
    //MARK: - Utility Methods
    private func showAlertMessage() {
        if let alertMessage = albumListViewModel.errorMessage {
            let alert = UIAlertController(title: NSLocalizedString("Alert.Title.Error", comment: "error"), message: alertMessage, preferredStyle: .alert)
           
            if albumListViewModel.isRetryAllowed {
                let alertAction = UIAlertAction(title: NSLocalizedString("Alert.Action.Retry", comment: "Retry"), style: .default) { [weak self] action in
                    self?.albumListViewModel.retryAction()
                }
                alert.addAction(alertAction)
            }
            let alertAction = UIAlertAction(title: NSLocalizedString("Alert.Action.Ok", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(alertAction)
            present(alert, animated: true)
        }
    }
    
    //This method developed to support UI testing to run without network access
    private func getAlbumService() -> DataFetchable{
        var webService: DataFetchable!
    #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MockService") {
            webService = MockAlbumService()
        }else {
            
            webService = AlbumService()
        }
    #else
        webService = AlbumService()
    #endif
        return webService
    }
}

//MARK: - UITableViewDataSource
extension AlbumListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return albumListViewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.CellReuseId.albumCellId, for: indexPath) as? AlbumListTableViewCell else {
            fatalError("AlbumListTableViewCell is not found")
        }
        cell.albumViewModel = albumListViewModel.getAlbumViewModel(forSection: indexPath.section, forRow: indexPath.row)
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(named: "PixxyNavBarTint")
        cell.selectedBackgroundView = bgColorView
        cell.titleLabel.highlightedTextColor = .white
        cell.accessibilityIdentifier = "Cell_\(indexPath.section)_\(indexPath.row)" //For UITesting
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        albumListViewModel.numberOfRowsInSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        albumListViewModel.sectionName(at: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: Constant.Font.mainFontBold, size: 18.0)
        header.textLabel?.textColor = UIColor(named: "PixxyTableCellHeaderTitle")
    }
}

//MARK: - UITableViewDelegate
extension AlbumListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedViewModel = albumListViewModel.getAlbumViewModel(forSection: indexPath.section, forRow: indexPath.row) else {
            fatalError("Cannot load the album view model for the selected cell in AlbumListViewController")
        }
        photoCollectionViewModelForSelectedItem = PhotoCollectionViewModel(albumID: selectedViewModel.albumID, albumTitle: selectedViewModel.titleText,photosService: self.getAlbumService())
        performSegue(withIdentifier: Constant.SegueIdentifier.toPhotoCollectionVC, sender: self)
    }
}

//MARK: - Custom Album Table View Cell
class AlbumListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    var albumViewModel: AlbumViewModel? {
        didSet{
            titleLabel.text = albumViewModel?.titleText.capitalized
        }
    }
}

