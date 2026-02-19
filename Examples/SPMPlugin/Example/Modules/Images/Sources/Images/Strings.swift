//
//  Strings.swift
//  Images
//
//  Created by Sergey Balalaev on 19.02.2026.
//

import SwiftUI

extension String {
    var image: Image {
        Image(self)
    }

    var uiImage: UIImage {
        UIImage(imageLiteralResourceName: self)
    }
}
