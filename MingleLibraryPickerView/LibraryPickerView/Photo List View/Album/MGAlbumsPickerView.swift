//
//  MGAlbumsPickerView.swift
//  MGInputBarView
//
//  Created by Tung Tran on 11/23/19.
//  Copyright © 2019 Mingle. All rights reserved.
//

import UIKit

protocol MGAlbumsPickerViewDelegate: class {
    func albumsPickerDidSelect(album: MLPMediaAlbum)
}

final class MGAlbumsPickerView: UIView {
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Properties
    private let cellID = "MGAlbumCell"
    private var albums: [MLPMediaAlbum] = []
    private weak var delegate: MGAlbumsPickerViewDelegate?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}

// MARK: - Public
extension MGAlbumsPickerView {
    func setup(album: MLPMediaAlbum, albums: [MLPMediaAlbum], delegate: MGAlbumsPickerViewDelegate) {
        self.delegate = delegate
        self.albums = albums
        
        tableView.reloadData()
        if let index = albums.firstIndex(of: album) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }
}

// MARK: - Private
extension MGAlbumsPickerView {
    private func setup() {
        guard let view = UINib(nibName: "MGAlbumsPickerView", bundle: Bundle(for: Self.self))
            .instantiate(withOwner: self, options: nil).first as? UIView
        else { return }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        setupUI()
    }
    
    private func setupUI() {
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "MGAlbumCell", bundle: Bundle(for: Self.self)), forCellReuseIdentifier: cellID)
    }
}

// MARK: - UITableViewDataSource
extension MGAlbumsPickerView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
            as? MGAlbumCell
        else { return UITableViewCell() }
        
        cell.setup(album: albums[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MGAlbumsPickerView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = tableView.indexPathForSelectedRow?.row else { return }
        delegate?.albumsPickerDidSelect(album: albums[row])
    }
}
