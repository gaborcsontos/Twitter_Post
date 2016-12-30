//
//  FilteredImageBuilder.swift
//  Loutude
//
//  Created by Gabor Csontos on 10/8/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation
import UIKit
import CoreImage


final class FilteredImageBuilder {
    
    private enum PhotoFilters: String {
        
        // Use static constants to avoid typos throughout application
        case None = "CIColorControls"
        case Mono = "CIPhotoEffectMono"
        case Tonal = "CIPhotoEffectTonal"
        case Noir = "CIPhotoEffectNoir"
        case Fade = "CIPhotoEffectFade"
        case Chrome = "CIPhotoEffectChrome"
        case Process = "CIPhotoEffectProcess"
        case Transfer = "CIPhotoEffectTransfer"
        case Instant = "CIPhotoEffectInstant"
    }
    
    
    // Responsible for holding available filters for application
    private struct PhotoFilter {
        
        // Use static constants to avoid typos throughout application
        static let None = "CIColorControls"
        static let Mono = "CIPhotoEffectMono"
        static let Tonal = "CIPhotoEffectTonal"
        static let Noir = "CIPhotoEffectNoir"
        static let Fade = "CIPhotoEffectFade"
        static let Chrome = "CIPhotoEffectChrome"
        static let Process = "CIPhotoEffectProcess"
        static let Transfer = "CIPhotoEffectTransfer"
        static let Instant = "CIPhotoEffectInstant"

    
        static func defaultFilters() -> [CIFilter] {
            //here if we want to change some color, saturation etc
            let none = CIFilter(name: PhotoFilter.None)!
            let mono = CIFilter(name: PhotoFilter.Mono)!
            let tonal = CIFilter(name: PhotoFilter.Tonal)!
            let noir = CIFilter(name: PhotoFilter.Noir)!
            let fade = CIFilter(name: PhotoFilter.Fade)!
            let chrome = CIFilter(name: PhotoFilter.Chrome)!
            let process = CIFilter(name: PhotoFilter.Process)!
            let transfer = CIFilter(name: PhotoFilter.Transfer)!
            let instant = CIFilter(name: PhotoFilter.Instant)!
            
            return [none,mono,tonal,noir,fade,chrome,process,transfer,instant]
        }
        
    }
   

    let context = CIContext(eaglContext: EAGLContext(api: .openGLES2)!)
   
    private let image: UIImage

    
    init(image: UIImage) {
        self.image = image
    }
    

    
    
    // Apply default filters to images
    func imagesWithDefaultFilters() -> [(UIImage, String, CIFilter)] {
        return image(withFilters: PhotoFilter.defaultFilters())

    }
    
    // Apply filters on images
    func image(withFilters filters: [CIFilter]) -> [(UIImage,String,CIFilter)] {
        return filters.map { image(image: self.image, withFilter: $0) }
    }
    


    // Create cgImages
    func image(image: UIImage, withFilter filter: CIFilter) -> (UIImage, String, CIFilter) {
        // Use nil-colescing operator incase .ciImage returns nil
        let inputImage = image.ciImage ?? CIImage(image: image)!
        
        let filterName = String(describing: PhotoFilters(rawValue: filter.name)!)
        
        filter.setDefaults()
        // Use KVC to set input image for filter
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        let exposureOutput = filter.value(forKey: kCIOutputImageKey) as! CIImage
        let output = context.createCGImage(exposureOutput, from: exposureOutput.extent)
        return (UIImage(cgImage: output!), filterName, filter)

    }
}
