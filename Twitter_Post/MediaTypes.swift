//
//  MediaTypes.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/23/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation

//MediaTypes
public enum MediaTypes: String {
    case CameraRoll = "Camera Roll"
    case Selfies =  "Selfies"
    case Favourites = "Favourites"
    case Videos = "Videos"
    
    static let allValues = [CameraRoll, Selfies, Favourites, Videos]
}

