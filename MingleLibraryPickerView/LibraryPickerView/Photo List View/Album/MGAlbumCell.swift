//
//  MGAlbumCell.swift
//  MGInputBarView
//
//  Created by Tung Tran on 11/23/19.
//  Copyright © 2019 Mingle. All rights reserved.
//

import UIKit
import Photos

final class MGAlbumCell: UITableViewCell {
    // MARK: - Outlets
    @IBOutlet private weak var albumImageView: UIImageView!
    @IBOutlet private weak var albumNameLabel: UILabel!
    @IBOutlet private weak var albumNumPhotoLabel: UILabel!
}

// MARK: - Override
extension MGAlbumCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
    
    override func prepareForReuse() {
        albumImageView.image = nil
    }
}

// MARK: - Public
extension MGAlbumCell {
    func setup(album: MLPMediaAlbum) {
        albumNameLabel.text = album.name
        albumNumPhotoLabel.text = "\(album.photos.count)"
        
        guard let asset = album.photos.first as? PHAsset else { return }
        DispatchQueue.global(qos: .default).async {
            PHAsset.getImageFromAsset(asset: asset, size: CGSize(width: 200, height: 200)) { (image) in
                DispatchQueue.main.async {
                    self.albumImageView.image = image
                }
            }
        }
    }
}
