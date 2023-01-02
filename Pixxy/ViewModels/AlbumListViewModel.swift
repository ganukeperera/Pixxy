//
//  AlbumListViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation
import Combine

class AlbumListViewModel {
    @Published var isAlbumsLoading = false
    @Published var reloadAlbumList = false
    private var albumService: DataFetchable
    private var cancellables = Set<AnyCancellable>()
    private var albumViewModels = [AlbumViewModel]() {
        didSet {
            reloadAlbumList = true
        }
    }
    
    init(service: DataFetchable = AlbumService()) {
        self.albumService = service
    }
    
    var numberOfAlbums: Int {
        albumViewModels.count
    }
    
    func getAlbumViewModel(at index: Int) -> AlbumViewModel? {
        guard index < albumViewModels.count else {
            return nil
        }
        return albumViewModels[index]
    }
    
    func fetchAlbums() {
        isAlbumsLoading = true
        let albumEndopoint = AlbumEndpoint.fetchAllAlbums
        let userEndopoint = AlbumEndpoint.fetchAllUsers
        
        Publishers.Zip(
            self.albumService.fetchData(endpoint: albumEndopoint, type: [AlbumDTO].self),
            self.albumService.fetchData(endpoint: userEndopoint, type: [UserDTO].self)
        ).sink(receiveCompletion: { print($0) },
               receiveValue: { [weak self] albumList, users in
            
            let myDict = users.reduce(into: [Int: String]()) {
                print($1)
                $0[$1.id] = $1.name
            }
            let albums = albumList.map { album in
                return Album(albumId: album.id, albumTitle: album.title, owner: (myDict[album.userId] ?? ""))
            }
            self?.isAlbumsLoading = false
            self?.processAlbums(albums: albums)
        }).store(in: &cancellables)
    }
    
    private func processAlbums(albums: [Album]) {
        var viewModels = [AlbumViewModel]()
        for album in albums {
            let albumVm = AlbumViewModel(albumID:album.albumId, titleText: album.albumTitle, nameText: album.owner)
            viewModels.append(albumVm)
        }
        albumViewModels = viewModels
    }
}

struct AlbumViewModel {
    let albumID: Int
    let titleText: String
    let nameText: String
}
