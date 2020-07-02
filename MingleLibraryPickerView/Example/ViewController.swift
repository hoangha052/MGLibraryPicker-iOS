//
//  ViewController.swift
//  MingleLibraryPickerView
//
//  Created by Ha Ho on 6/30/20.
//  Copyright © 2020 Ha Ho. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var buttonClick: UIButton!
    private let cellSpace: CGFloat = 4
    private let numberOfItemsInRow = 3
    private let swipeValue: CGFloat = 60
    private var cellWidth: CGFloat {
        return (UIScreen.main.bounds.size.width - cellSpace * 2)
    }
    private var dataSources: [PHAsset] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageCollectionView.register(UINib(nibName: "ImageCell", bundle: Bundle(for: type(of: self))),
                                     forCellWithReuseIdentifier: "ImageCollectionCell")

    }


    @IBAction func didClickButton(_ sender: Any) {
        let pickerViewController = MGLibraryPickerViewController()
        pickerViewController.delegate = self
        pickerViewController.maximumSelectionsAllowed = 1
        pickerViewController.takePhotoEnable = true
        self.present(pickerViewController, animated: true, completion: nil)
    }
}

extension ViewController: MGLibraryPickerViewDelegate {
    func didClickUploadButton(assets: [PHAsset]) {
        dataSources = assets
        imageCollectionView.reloadData()
    }
    
    func didCameraTakePhoto(image: UIImage) {
        imageView.image = image
    }
    
    var sendPhotoEnabled: Bool {
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionCell", for: indexPath) as? ImageCell
            else { return UICollectionViewCell() }
        let asset = dataSources[indexPath.row]
        cell.setupAsset(asset)
        return cell
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
