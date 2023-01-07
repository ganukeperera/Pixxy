//
//  ViewController.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/1/23.
//

import UIKit
import Combine

class AlbumListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private var cancellables = Set<AnyCancellable>()
    lazy var albumListViewModel: AlbumListViewModel = {
        return AlbumListViewModel()
    }()
    private var photoCollectionViewModelForSelectedItem: PhotoCollectionViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
        title = NSLocalizedString("AlbumListVC.NavCTRL.Title", comment: "Album")
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constant.SegueIdentifier.toPhotoCollectionVC
            {
                if let destinationVC = segue.destination as? PhotoCollectionViewController {
                    destinationVC.photoCollectionViewModel = photoCollectionViewModelForSelectedItem
                }
            }
    }
    
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
}

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
        header.textLabel?.font = UIFont(name: Constant.Font.mainFontBold, size: 20.0)
        header.textLabel?.textColor = UIColor(named: "PixxyTableCellHeaderTitle")
    }
}

extension AlbumListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedViewModel = albumListViewModel.getAlbumViewModel(forSection: indexPath.section, forRow: indexPath.row) else {
            fatalError("Cannot load the album view model for the selected cell in AlbumListViewController")
        }
        photoCollectionViewModelForSelectedItem = PhotoCollectionViewModel(albumID: selectedViewModel.albumID, albumTitle: selectedViewModel.titleText)
        performSegue(withIdentifier: Constant.SegueIdentifier.toPhotoCollectionVC, sender: self)
    }
}

class AlbumListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    var albumViewModel: AlbumViewModel? {
        didSet{
            titleLabel.text = albumViewModel?.titleText.capitalized
        }
    }
}

