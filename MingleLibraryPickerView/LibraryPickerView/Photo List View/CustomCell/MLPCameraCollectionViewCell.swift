//
//  CameraCollectionViewCell.swift
//  MGInputBarView
//
//  Created by HoangHa on 11/15/19.
//  Copyright © 2019 Mingle. All rights reserved.
//

import UIKit

class MLPCameraCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cameraIcon: UIImageView!
    
    override var isHighlighted: Bool {
        willSet {
            alpha = newValue ? 0.5 : 1
        }
    }
}
