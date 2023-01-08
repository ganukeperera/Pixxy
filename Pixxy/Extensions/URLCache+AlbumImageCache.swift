//
//  URLCache+AlbumImageCache.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/4/23.
//

import Foundation

extension URLCache {
    
    static func configSharedCache(directory: String? = Bundle.main.bundleIdentifier, memory: Int = 0, disk: Int = 0) {
        
        URLCache.shared = {
            return URLCache(memoryCapacity: memory, diskCapacity: disk)
        }()
    }
}
