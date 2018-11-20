//
//  IGTextugeMaker.swift
//  ImageGradient
//
//  Created by Aleksandr Borodulin on 20/11/2018.
//

import UIKit

class IGTextugeMaker: UIView {

    class func createTexture(image: UIImage, device: MTLDevice) -> MTLTexture? {
        if let imageRef = image.cgImage {
            let width = imageRef.width
            let height = imageRef.height
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let rawData = calloc(height * width * 4, MemoryLayout<UInt8>.size)
            
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            
            let options = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            
            let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: options)
            
            context?.draw(imageRef, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            
            let textureDescription = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: true)
            let texture = device.makeTexture(descriptor: textureDescription)
            
            let region = MTLRegionMake2D(0, 0, width, height)
            
            texture?.replace(region: region, mipmapLevel: 0, slice: 0, withBytes: rawData!, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerRow * height)
            
            free(rawData)
            
            return texture
        }
        
        return nil
    }
}
