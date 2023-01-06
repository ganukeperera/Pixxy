//
//  AlbumListViewModel.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation
import Combine

enum ErrorType {
    case APIError
}

class AlbumListViewModel: ObservableObject {
    
    @Published private(set) var isAlbumsLoading = false
    @Published private(set) var reloadAlbumList = false
    @Published private(set) var showErroMessage = false
    private var albumService: DataFetchable
    private var cancellables = Set<AnyCancellable>()
    private var albumViewModelDictionary = [Int: [AlbumViewModel]]()
    private var userList = [UserDTO]()
    private var errorType: ErrorType?
    private(set) var errorMessage: String? {
        didSet{
            showErroMessage = true
        }
    }
    
    init(service: DataFetchable = AlbumService()) {
        self.albumService = service
    }
    
    var numberOfSections: Int {
        if userList.isEmpty{
            return 1
        }
        return userList.count
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        if userList.isEmpty{
            var allAlbums = [AlbumViewModel]()
            for albums in albumViewModelDictionary.values {
                allAlbums += albums
            }
            return allAlbums.count
        }
        return userList.count
    }
    
    func sectionName(at section: Int) -> String{
        if userList.isEmpty , section >= userList.count {
            return ""
        }
        return userList[section].name
    }
    
    func getAlbumViewModel(forSection section: Int, forRow row: Int) -> AlbumViewModel? {
        if userList.isEmpty {
            var allAlbums = [AlbumViewModel]()
            for albums in albumViewModelDictionary.values {
                allAlbums += albums
            }
            return allAlbums[row]
        }
        return albumViewModelDictionary[userList[section].id]?[row]
    }
    
    var isRetryAllowed: Bool{
        
        switch errorType {
        case .APIError:
            return true
        default:
            return false
        }
    }
    
    func retryAction() {
        
        switch errorType {
        case .APIError:
            fetchAlbums()
        default:
            break
        }
    }
    
    func fetchAlbums() {
        isAlbumsLoading = true
        let albumEndopoint = AlbumEndpoint.fetchAllAlbums
        let userEndopoint = AlbumEndpoint.fetchAllUsers
        var albumList: [AlbumDTO]?
        var userList: [UserDTO]?
        let albumDipatchGroup = DispatchGroup()
        albumDipatchGroup.enter()
        self.albumService.fetch(endpoint: albumEndopoint, type: [AlbumDTO].self)
            .sink { completion in
                switch completion{
                case .failure(_):
                    break
                case .finished:
                    break
                }
            } receiveValue: { albums in
                albumList = albums
                albumDipatchGroup.leave()
            }.store(in: &cancellables)
        
        albumDipatchGroup.enter()
        self.albumService.fetch(endpoint: userEndopoint, type: [UserDTO].self)
            .sink { completion in
                switch completion{
                case .failure(_):
                    break
                case .finished:
                    break
                }
            } receiveValue: { users in
                userList = users
                albumDipatchGroup.leave()
            }.store(in: &cancellables)
        
        //set highest priority as user cannot continue until this is done∫
        albumDipatchGroup.notify(queue: .global(qos: .userInitiated)){
            
            self.isAlbumsLoading = false
            guard let albumList = albumList else{
                self.errorType = .APIError
                self.errorMessage = NSLocalizedString("AlbumListVC.Error.AlbumAPI", comment: "Album API erro")
                return
            }
            var userDictionary = [Int: String]()
            if let userList = userList {
                self.userList = userList
                userDictionary = userList.reduce(into: [Int: String]()) {
                    print($1)
                    $0[$1.id] = $1.name
                }
            }
            
            let viewModels = albumList.reduce(into: [Int: [AlbumViewModel]]()) {
                let album = AlbumViewModel(albumID: $1.id, titleText: $1.title, nameText: (userDictionary[$1.userId] ?? ""))
                if var albums = $0[$1.userId] {
                    albums.append(album)
                    $0[$1.userId] = albums
                }
                else {
                    $0[$1.userId] = [album]
                }
            }
            
            self.albumViewModelDictionary = viewModels
            self.reloadAlbumList = true
        }
    }
}

struct AlbumViewModel {
    let albumID: Int
    let titleText: String
    let nameText: String
}
