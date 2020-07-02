//
//  imageCell.swift
//  MGInputBar
//
//  Created by Ha Ho on 6/30/20.
//  Copyright © 2020 Mingle. All rights reserved.
//

import UIKit
import Photos

class ImageCell: UICollectionViewCell {

    @IBOutlet private weak var imvIcon: UIImageView!
    @IBOutlet private weak var durationView: UIView!
    @IBOutlet private weak var durationLabel: UILabel!
    
    @IBOutlet weak var selectedImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        durationView.layer.cornerRadius = durationLabel.frame.size.height / 2
        durationView.isHidden = true
    }
    
    override func prepareForReuse() {
        durationView.isHidden = true
        imvIcon.image = nil
        imvIcon.backgroundColor = .clear
        selectedImageView.isHidden = true
    }
    
    override var isHighlighted: Bool {
        willSet {
            alpha = newValue ? 0.5 : 1
        }
    }
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = !isSelected
        }
    }
    
    func loadActionImage(image: UIImage?) {
        imvIcon.image = image
    }
    
    func loadImage(image: UIImage?) {
        imvIcon.image = image
    }
    
    func setupAsset(_ asset: PHAsset) {
        imvIcon.contentMode = .scaleAspectFill
        imvIcon.backgroundColor = .lightGray
        DispatchQueue.global(qos: .default).async {
            PHAsset.getImageFromAsset(asset: asset, size: CGSize(width: 200, height: 200)) { (image) in
                DispatchQueue.main.async {
                    self.imvIcon.image = image
                }
            }
        }
        
        switch asset.mediaType {
        case .video:
            durationView.isHidden = false
            
            let duration: Int = lround(asset.duration)
            let min = duration / 60
            let second = duration % 60
            durationLabel.text = String(format: "%02d:%02d", min, second)
        default:
            durationView.isHidden = true
        }
    }
}
