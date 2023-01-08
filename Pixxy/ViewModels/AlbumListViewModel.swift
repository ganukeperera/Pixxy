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
    case ItemNotFound
    case none
}

class AlbumListViewModel: ObservableObject {
    
    @Published private(set) var isAlbumsLoading = false //Will Remove Activity Indicator
    @Published private(set) var reloadAlbumList = false //Will reload the Table View
    @Published private(set) var showErroMessage = false
    private var albumService: DataFetchable
    private var cancellables = Set<AnyCancellable>()
    private var albumViewModelDictionary = [Int: [AlbumViewModel]]()
    private var userList = [User]()
    private var errorType: ErrorType?
    private var errorOccurred = false
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
        self.isAlbumsLoading = true
        self.errorOccurred = false
        self.errorType = ErrorType.none
        let albumEndopoint = AlbumEndpoint.fetchAllAlbums
        let userEndopoint = AlbumEndpoint.fetchAllUsers
        var albumList: [Album]?
        var userList: [User]?
        let albumDipatchGroup = DispatchGroup()
        albumDipatchGroup.enter()
        self.albumService.fetch(endpoint: albumEndopoint, type: [Album].self)
            .sink {[weak self] completion in
                if case let .failure(error) = completion {
                    //Application will not be able to if Album endpoint throws an error. Appliation will show a error message
                    switch error {
                    case let networkError as NetworkError:
                        self?.errorMessage = networkError.localizedDescription
                    default:
                        self?.errorMessage = NSLocalizedString("AlbumListVC.Error.AlbumAPI", comment: "Album API erro")
                    }
                    self?.errorType = .APIError
                }
                albumDipatchGroup.leave()
            } receiveValue: { albums in
                albumList = albums
            }.store(in: &cancellables)
        
        albumDipatchGroup.enter()
        self.albumService.fetch(endpoint: userEndopoint, type: [User].self)
            .sink { completion in
                if case let .failure(error) = completion {
                    //Will ignore this error as app will proceed without showing user endpoint related data
                    print("User endpoint throws an error. Application will proceed without aborting. Error: \(error.localizedDescription)")
                    
                }
                albumDipatchGroup.leave()
            } receiveValue: { users in
                userList = users
            }.store(in: &cancellables)
        
        //Set highest priority as user cannot continue until app completed processing all albums
        albumDipatchGroup.notify(queue: .global(qos: .userInitiated)){
            self.isAlbumsLoading = false
            if self.errorOccurred {
                return
            }
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
