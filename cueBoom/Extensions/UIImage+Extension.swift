//
//  UIImage+Extension.swift
//  cueBoom
//
//  Created by Angel Dev on 2/17/22.
//  Copyright © 2022 Shahin Firouzbakht. All rights reserved.
//


import UIKit
import CoreGraphics
import Accelerate

extension UIImage {

    func fixOrientation() -> UIImage {
        if (imageOrientation == .up) { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func scale(to newSize: CGSize) -> UIImage? {
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)

        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
    
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage

        let size = self.size
        let aspectRatio =  size.width/size.height

        switch contentMode {
            case .scaleAspectFit:
                if aspectRatio > 1 {                            // Landscape image
                    width = dimension
                    height = dimension / aspectRatio
                } else {                                        // Portrait image
                    height = dimension
                    width = dimension * aspectRatio
                }

        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }

        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
                newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }

        return newImage
    }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func getFileSizeInfo(allowedUnits: ByteCountFormatter.Units = .useMB, countStyle: ByteCountFormatter.CountStyle = .memory, compressionQuality: CGFloat = 1.0) -> String? {
        // https://developer.apple.com/documentation/foundation/bytecountformatter
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.countStyle = countStyle
        return getSizeInfo(formatter: formatter, compressionQuality: compressionQuality)
    }

    func getSizeInfo(formatter: ByteCountFormatter, compressionQuality: CGFloat = 1.0) -> String? {
        guard let imageData = jpegData(compressionQuality: compressionQuality) else { return nil }
        return formatter.string(fromByteCount: Int64(imageData.count))
    }
    
    
    /////////////
    public func resize(to newSize: CGSize, with resizeFramework: ResizeFramework = .coreGraphics) -> UIImage? {
        switch resizeFramework {
            case .uikit: return resizeWithUIKit(to: newSize)
            case .coreGraphics: return resizeWithCoreGraphics(to: newSize)
            case .coreImage: return resizeWithCoreImage(to: newSize)
            case .imageIO: return resizeWithImageIO(to: newSize)
            case .accelerate: return resizeWithAccelerate(to: newSize)
        }
    }
    
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    ////////////
    public enum ResizeFramework {
        case uikit, coreImage, coreGraphics, imageIO, accelerate
    }
    
    // MARK: - UIKit

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    private func resizeWithUIKit(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - CoreImage

    /// Resize CI image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
    private func resizeWithCoreImage(to newSize: CGSize) -> UIImage? {
        guard let cgImage = cgImage, let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let scale = (Double)(newSize.width) / (Double)(ciImage.extent.size.width)

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value:scale), forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        guard let outputImage = filter.value(forKey: kCIOutputImageKey) as? CIImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: resultCGImage)
    }

    // MARK: - CoreGraphics

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    private func resizeWithCoreGraphics(to newSize: CGSize) -> UIImage? {
        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return nil }

        let width = Int(newSize.width)
        let height = Int(newSize.height)
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let bitmapInfo = cgImage.bitmapInfo

        guard let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow, space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        context.interpolationQuality = .high
        let rect = CGRect(origin: CGPoint.zero, size: newSize)
        context.draw(cgImage, in: rect)

        return context.makeImage().flatMap { UIImage(cgImage: $0) }
    }

    // MARK: - ImageIO

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    private func resizeWithImageIO(to newSize: CGSize) -> UIImage? {
        var resultImage = self

        guard let data = jpegData(compressionQuality: 1.0) else { return resultImage }
        let imageCFData = NSData(data: data) as CFData
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(newSize.width, newSize.height)
            ] as CFDictionary
        guard   let source = CGImageSourceCreateWithData(imageCFData, nil),
                let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return resultImage }
        resultImage = UIImage(cgImage: imageReference)

        return resultImage
    }

    // MARK: - Accelerate

    /// Resize image from given size.
    ///
    /// - Parameter newSize: Size of the image output.
    /// - Returns: Resized image.
    private func resizeWithAccelerate(to newSize: CGSize) -> UIImage? {
        var resultImage = self

        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return nil }

        // create a source buffer
        var format = vImage_CGImageFormat(bitsPerComponent: numericCast(cgImage.bitsPerComponent),
                                          bitsPerPixel: numericCast(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passUnretained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .absoluteColorimetric)
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.data.deallocate()
        }

        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return resultImage }

        // create a destination buffer
        let destWidth = Int(newSize.width)
        let destHeight = Int(newSize.height)
        let bytesPerPixel = cgImage.bitsPerPixel
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)

        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return resultImage }

        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return resultImage }

        // create a UIImage
        if let scaledImage = destCGImage.flatMap({ UIImage(cgImage: $0) }) {
            resultImage = scaledImage
        }

        return resultImage
    }
}
