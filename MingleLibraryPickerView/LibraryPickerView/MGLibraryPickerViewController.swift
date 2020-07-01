//
//  MGLibraryPickerViewController.swift
//  MingleLibraryPickerView
//
//  Created by Ha Ho on 6/30/20.
//  Copyright © 2020 Ha Ho. All rights reserved.
//

import UIKit
import CoreMedia
import Photos
import MobileCoreServices

@objc public protocol MGLibraryPickerViewDelegate: class {
    var sendPhotoEnabled: Bool { get }
    func didClickUploadButton(assets: [PHAsset])
    @objc optional var sendVideoEnabled: Bool { get }
    @objc optional func didClosePickerView()
    @objc optional func didCameraTakePhoto(image: UIImage)
    @objc optional func didCameraTakeVideo(url: URL)
}

class MLPMediaAlbum: Equatable {
    let name: String
    let referenceAlbum: PHAssetCollection
    var photos: [Any]
    
    init(name: String, referenceAlbum: PHAssetCollection, photos: [PHAsset]) {
        self.name = name
        self.referenceAlbum = referenceAlbum
        self.photos = photos
    }
    
    static func == (lhs: MLPMediaAlbum, rhs: MLPMediaAlbum) -> Bool {
        return lhs.name == rhs.name &&
            lhs.referenceAlbum == rhs.referenceAlbum &&
            lhs.photos.count == rhs.photos.count
    }
}

class MGLibraryPickerViewController: UIViewController {

    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleImageView: UIImageView!
    
    public weak var delegate: MGLibraryPickerViewDelegate?
    public var maxVideoDuration: Double = 20
    public var maximumSelectionsAllowed = 1
    public var takePhotoEnable: Bool = true
    public var cancelButtonTitle: String = "Cancel"
    public var uploadButtonTitle: String = "Upload"
    public var cancelButtonColor: UIColor = UIColor(red: 74/255.0, green: 74/255.0, blue: 74/255.0, alpha: 1.0)
    public var uploadButtonColor: UIColor = UIColor(red: 254/255.0, green: 59/255.0, blue: 47/255.0, alpha: 1.0)
    
    private let cellSpace: CGFloat = 4
    private let numberOfItemsInRow = 3
    private let swipeValue: CGFloat = 60
    private var cellWidth: CGFloat {
        return (UIScreen.main.bounds.size.width - cellSpace * CGFloat(numberOfItemsInRow + 1)) / CGFloat(numberOfItemsInRow)
    }

    private struct CameraItem {
        var title: String = ""
    }
    private var finishFetchingAlbums = false
    private var albums: [MLPMediaAlbum] = []
    private weak var selectedAlbum: MLPMediaAlbum?
    private weak var albumsPickerView: MGAlbumsPickerView?
    private var isDown = true
    private weak var albumsPickerViewTopConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupData()
    }
    
    private func setupUI() {
        setupNavigationView()
        setupGestures()
        setupMediaCollectionView()
    }
    
     private func setupNavigationView() {
        cancelButton.setTitle(cancelButtonTitle, for: .normal)
        cancelButton.setTitleColor(cancelButtonColor, for: .normal)
        uploadButton.setTitle(uploadButtonTitle, for: .normal)
        uploadButton.setTitleColor(uploadButtonColor, for: .normal)
        titleLabel.textColor = cancelButtonColor
     }

    private func setupGestures() {
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleViewDidTapped)))
        titleView.isUserInteractionEnabled = true
    }

    private func setupMediaCollectionView() {
        mediaCollectionView.register(UINib(nibName: "MLPImageCell", bundle: Bundle(for: type(of: self))),
                                     forCellWithReuseIdentifier: "ImageCell")
        mediaCollectionView.register(UINib(nibName: "MLPCameraCollectionViewCell", bundle: Bundle(for: type(of: self))),
                                     forCellWithReuseIdentifier: "CameraCell")
        mediaCollectionView.allowsMultipleSelection = maximumSelectionsAllowed != 1
    }

    private func setupData() {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .notDetermined, .restricted, .denied:
                print("Not determined yet")
            case .authorized:
                self.albums = self.fetchAlbums()
                self.fetchAndDisplayPhotos()
                DispatchQueue.global(qos: .default).async {
                    self.fetchAlbumsInfo()
                }
            @unknown default:
                break
            }
        }
    }

    private func getSelectedMedia() -> [PHAsset] {
        guard let album = selectedAlbum, let selectedIndexPath = self.mediaCollectionView.indexPathsForSelectedItems else { return [] }
        var selectedMedia: [PHAsset] = []
        for index in selectedIndexPath {
            if let selectedAsset = album.photos[index.row] as? PHAsset {
                selectedMedia.append(selectedAsset)
            }
        }
        return selectedMedia
    }
    
    

    // MARK: - IBAction
    @IBAction func didClickCancelButton(_ sender: Any) {
        self.delegate?.didClosePickerView?()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didClickUploadButton(_ sender: Any) {
        let selectedMedia = getSelectedMedia()
        guard selectedMedia.count > 0 else { return }
        self.delegate?.didClickUploadButton(assets: selectedMedia)
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - NavigationView
extension MGLibraryPickerViewController {
    private func toggleArrowDirection() {
        UIView.animate(withDuration: 0.3) {
            self.titleImageView.transform = self.titleImageView.transform.rotated(by: self.isDown ? .pi : -.pi * 3)
            self.isDown.toggle()
        }
    }
    
    @objc private func titleViewDidTapped() {
         guard finishFetchingAlbums else { return }
         
         if albumsPickerView != nil {
             dismissAlbumsPickerView(animated: true, completion: nil)
         } else {
             self.toggleArrowDirection()
             setupAlbumsPickerView()
             toggleAlbumsPickerView(isHidden: true, animated: false, completion: nil)
             toggleAlbumsPickerView(isHidden: false, animated: true, completion: nil)
         }
     }
}

// MARK: - MediaPickerView
extension MGLibraryPickerViewController {
    private var mediaTypes: [PHAssetMediaType] {
        var medias: [PHAssetMediaType] = []
        if delegate?.sendPhotoEnabled == true {
            medias.append(.image)
        }
        if delegate?.sendVideoEnabled == true {
            medias.append(.video)
        }
        
        return medias
    }
        
    private func fetchAlbums() -> [MLPMediaAlbum] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "endDate", ascending: false)]
        
        var excludedSubtypes: [PHAssetCollectionSubtype] = [
            .smartAlbumPanoramas, .smartAlbumTimelapses, .smartAlbumSlomoVideos
        ]
        if #available(iOS 10.3, *) {
            excludedSubtypes.append(.smartAlbumLivePhotos)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
        
        let userAlbums: [MLPMediaAlbum] = [smartAlbums].reduce(into: []) { (albums, object) in
            for index in 0..<object.count {
                let album = object.object(at: index)
                let inputBarAlbum = MLPMediaAlbum(name: album.localizedTitle ?? "", referenceAlbum: album, photos: [])
                if album.assetCollectionSubtype == .smartAlbumUserLibrary {
                    albums.insert(inputBarAlbum, at: 0)
                } else if !excludedSubtypes.contains(album.assetCollectionSubtype) {
                    albums.append(inputBarAlbum)
                }
            }
        }
        
        return userAlbums
    }
    
    private func fetchAndDisplayPhotos() {
        guard let album = albums.first else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.fetchPhotos(album: album)
            
            DispatchQueue.main.async {
                self.displayPhotos(album: album)
            }
        }
    }
    
    private func displayPhotos(album: MLPMediaAlbum) {
        selectedAlbum = album
        self.titleLabel.text = album.name
        if takePhotoEnable, selectedAlbum?.photos.firstIndex(where: { ($0 is CameraItem) }) == nil {
            selectedAlbum?.photos.append(CameraItem())
        }
        mediaCollectionView.reloadData()
    }
    
    @discardableResult
    private func fetchPhotos(album: MLPMediaAlbum) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType IN %@ AND duration <= %d", mediaTypes.map { $0.rawValue }, maxVideoDuration)
        
        let userPhotos = PHAsset.fetchAssets(in: album.referenceAlbum, options: fetchOptions)
        var photos: [PHAsset] = []
        for index in 0..<userPhotos.count {
            let photo = userPhotos.object(at: index)
            
            if checkValidPhotoSubtypes(photo.mediaSubtypes) {
                photos.append(userPhotos.object(at: index))
            }
        }
        album.photos = photos
        
        return photos
    }
    
    private func checkValidPhotoSubtypes(_ subtypes: PHAssetMediaSubtype) -> Bool {
        let invalidSubtypes: [PHAssetMediaSubtype] = [.photoLive, .videoTimelapse, .videoHighFrameRate]
        for invalidType in invalidSubtypes {
            if subtypes.contains(invalidType) {
                return false
            }
        }
        return true
    }
    
    private func fetchAlbumsInfo() {
        finishFetchingAlbums = false
        let albumsWithoutSelectedAlbum = albums.dropFirst()
        for album in albumsWithoutSelectedAlbum {
            fetchPhotos(album: album)
        }
        albums = albums.filter { $0.photos.count > 0 }
        finishFetchingAlbums = true
    }
}

// MARK :- AlbumPickerView
extension MGLibraryPickerViewController {
    private func setupAlbumsPickerView() {
        guard let selectedAlbum = selectedAlbum else { return }
        
        let albumsPickerView = MGAlbumsPickerView()
        albumsPickerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(albumsPickerView)
        
        let topConstraint = albumsPickerView.topAnchor.constraint(equalTo: mediaCollectionView.topAnchor)
        NSLayoutConstraint.activate([
            albumsPickerView.leadingAnchor.constraint(equalTo: mediaCollectionView.leadingAnchor),
            albumsPickerView.trailingAnchor.constraint(equalTo: mediaCollectionView.trailingAnchor),
            topConstraint,
            albumsPickerView.bottomAnchor.constraint(equalTo: mediaCollectionView.bottomAnchor)
        ])
        albumsPickerViewTopConstraint = topConstraint
        self.albumsPickerView = albumsPickerView
        
        albumsPickerView.setup(album: selectedAlbum, albums: albums, delegate: self)
    }
    
    private func dismissAlbumsPickerView(animated: Bool, completion: (() -> Void)?) {
        self.toggleArrowDirection()
        toggleAlbumsPickerView(isHidden: true, animated: animated) {
            self.albumsPickerView?.removeFromSuperview()
            completion?()
        }
    }
    
    private func toggleAlbumsPickerView(isHidden: Bool, animated: Bool, completion: (() -> Void)?) {
        let animations = {
            self.albumsPickerViewTopConstraint?.constant = isHidden ? self.mediaCollectionView.frame.size.height : 0
            self.view.layoutIfNeeded()
        }
        
        if !animated {
            animations()
            completion?()
            return
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: animations, completion: { (finished) in
            guard finished else { return }
            completion?()
        })
    }
}

// MARK: - CameraView
extension MGLibraryPickerViewController {
    func didSelectCamera() {
        var mediaTypes: [String] = []
        if delegate?.sendVideoEnabled == true {
            mediaTypes.append(String(kUTTypeMovie))
        }
        if delegate?.sendPhotoEnabled == true {
            mediaTypes.append(String(kUTTypeImage))
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.mediaTypes = mediaTypes
        imagePickerController.videoQuality = .typeIFrame960x540
        imagePickerController.videoMaximumDuration = TimeInterval(maxVideoDuration)
        imagePickerController.modalPresentationStyle = .fullScreen
        self.present(imagePickerController, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource
extension MGLibraryPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let photoNumber = selectedAlbum?.photos.count else { return 0 }
        return photoNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0, self.takePhotoEnable {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath) as? MLPCameraCollectionViewCell
                else {
                    return UICollectionViewCell()
            }
            return cell
        }
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? MLPImageCell,
            let album = selectedAlbum
            else { return UICollectionViewCell() }
        if let asset = album.photos[indexPath.row] as? PHAsset {
            cell.setupAsset(asset)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MGLibraryPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if collectionView.allowsMultipleSelection {
            if indexPath.row == 0, self.takePhotoEnable {
                return true
            }
            guard let selectedPhotoCount = collectionView.indexPathsForSelectedItems?.count else { return true }
            return selectedPhotoCount < maximumSelectionsAllowed
        } else {
            return true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0, self.takePhotoEnable {
            self.didSelectCamera()
            mediaCollectionView.deselectItem(at: indexPath, animated: true)
        } else {
//            guard let album = selectedAlbum else { return }
//            let asset = album.photos[indexPath.row - 1]
//            let selectedIndexPath = mediaCollectionView.indexPathsForSelectedItems
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MGLibraryPickerViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height: cellWidth)
    }
}

// MARK: - MGAlbumsPickerViewDelegate
extension MGLibraryPickerViewController: MGAlbumsPickerViewDelegate {
    func albumsPickerDidSelect(album: MLPMediaAlbum) {
        dismissAlbumsPickerView(animated: true, completion: nil)
        displayPhotos(album: album)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MGLibraryPickerViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let type: AnyObject = info[UIImagePickerController.InfoKey.mediaType] as? NSString {
            if type.isEqual(kUTTypeImage as String) {
                if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    DispatchQueue.main.async {
                        self.delegate?.didCameraTakePhoto?(image: image)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            } else if type.isEqual(kUTTypeVideo as String) || type.isEqual(kUTTypeMovie as NSString as String) {
                if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                    DispatchQueue.main.async {
                        self.delegate?.didCameraTakeVideo?(url: videoURL)
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
