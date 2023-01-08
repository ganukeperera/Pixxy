//
//  SceneDelegate.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/1/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
        var albumListViewModel: AlbumListViewModel!
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-MockService") {
            
            var mockService: MockAlbumService!
            if ProcessInfo.processInfo.arguments.contains("-FailUsers") {
                
                mockService = MockAlbumService(servicesToBeFailed: ["Users"])
            }else if ProcessInfo.processInfo.arguments.contains("-FailAlbums") {
                
                mockService = MockAlbumService(servicesToBeFailed: ["Albums"])
            }else {
                
                mockService = MockAlbumService()
            }
            albumListViewModel = AlbumListViewModel(service: mockService)
        }else {
            
            albumListViewModel = AlbumListViewModel()
        }
#else
        albumListViewModel = AlbumListViewModel()
#endif
        
        guard let navCTRL = self.window?.rootViewController as? UINavigationController else {
            fatalError()
        }
        let albumListVC = navCTRL.topViewController as! AlbumListViewController
        albumListVC.albumListViewModel = albumListViewModel
    }
    
}

