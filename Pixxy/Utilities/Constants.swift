//
//  Constants.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation

struct Constant {
    
    //MARK: - Cell Reuse IDs
    struct CellReuseId {
        static let albumCellId = "albumCellIdentifier"
        static let photoCollectionCellID = "photoCollectionCellIdentifier"
    }
    
    //MARK: - Segue Identifiers
    struct SegueIdentifier {
        static let toPhotoCollectionVC = "showPhotoCollection"
        static let toPhotoDetailVC = "showPhotoDetailView"
    }
    
    //MARK: - Network settings
    struct Network {
        static let requestTimeOut = 30.0
    }
    
    //MARK: - Application level configs
    struct AppConfig {
        static let diskImageCacheSize = 500*1024*1024 //500MB
        static let inMemoryImageCacheSize = 20*1024*1024 //20MB
    }
    
    //MARK: - View configs
    struct ViewConfig {
        static let numberofPhotosForRow = 3
    }
    
    //MARK: - Applicatiion fonts
    struct Font {
        static let mainFont = "Helvetica"
        static let mainFontBold = "Helvetica-Bold"
    }
}
