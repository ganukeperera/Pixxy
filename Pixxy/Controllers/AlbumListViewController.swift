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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupViewModel()
    }
    
    private func setupView() {
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
        
        albumListViewModel.fetchAlbums()
    }
}

extension AlbumListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.CellReuseId.albumCellId, for: indexPath) as? AlbumListTableViewCell else {
            fatalError("Cell is Missing")
        }
        cell.albumViewModel = albumListViewModel.getAlbumViewModel(at: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumListViewModel.numberOfAlbums
    }
}

extension AlbumListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

class AlbumListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var albumViewModel: AlbumViewModel? {
        didSet{
            nameLabel.text = albumViewModel?.nameText
            titleLabel.text = albumViewModel?.titleText
        }
    }
    
}

