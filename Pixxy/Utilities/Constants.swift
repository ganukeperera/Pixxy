//
//  Constants.swift
//  Pixxy
//
//  Created by Ganuke Perera on 1/2/23.
//

import Foundation

struct Constant {
    struct CellReuseId {
        static let albumCellId = "albumCellIdentifier"
        static let photoCollectionCellID = "photoCollectionCellIdentifier"
    }
    
    struct SegueIdentifier {
        static let toPhotoCollectionVC = "showPhotoCollection"
        static let toPhotoDetailVC = "showPhotoDetailView"
    }
    
    struct Network {
        static let requestTimeOut = 30.0
    }
    
    struct AppConfig {
        static let diskImageCacheSize = 500*1024*1024 //500MB
    }
    
    struct ViewConfig {
        static let numberofPhotosForRow = 3
    }
    
    struct Font {
        static let mainFont = "Helvetica"
        static let mainFontBold = "Helvetica-Bold"
    }
}
