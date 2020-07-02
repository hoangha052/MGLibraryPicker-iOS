//
//  LibraryPickerViewExtention.swift
//  MingleLibraryPickerView
//
//  Created by Ha Ho on 6/30/20.
//  Copyright © 2020 Ha Ho. All rights reserved.
//

import UIKit
import Photos

extension PHAsset {
    public static func getImageFromAsset(asset: PHAsset, size: CGSize? = nil, callback: @escaping (_ result:UIImage) -> Void) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.isSynchronous = true
        let imageManager = PHCachingImageManager()
        let targetSize = size ?? PHImageManagerMaximumSize
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let image = image {
                imageManager.startCachingImages(for: [asset], targetSize: targetSize, contentMode: .aspectFill, options: requestOptions)
                callback(image)
            }
        }
    }
}

extension URL {
    public static func thumbnailOfVideo(_ url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url, options: nil)
        let generate = AVAssetImageGenerator(asset: asset)
        generate.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 1, timescale: 2)
        var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
        let imageRef: CGImage!
        do {
            imageRef = try generate.copyCGImage(at: time, actualTime: &actualTime)
        } catch {
            return nil
        }
        return UIImage(cgImage: imageRef)
    }
}
