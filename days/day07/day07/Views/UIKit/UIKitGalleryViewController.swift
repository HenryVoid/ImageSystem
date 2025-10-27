//
//  UIKitGalleryViewController.swift
//  day07
//
//  UIKit 기반 갤러리 (UICollectionView)
//

import UIKit
import SwiftUI

/// UIKit 갤러리 뷰 컨트롤러
class UIKitGalleryViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private let items = ImageItem.samples
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "UIKit 갤러리"
        view.backgroundColor = .systemBackground
        
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        // FlowLayout 설정 (3열 그리드)
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 10
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns + 1)
        let itemWidth = (view.bounds.width - totalSpacing) / columns
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + 30)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ThumbnailCollectionCell.self, forCellWithReuseIdentifier: "ThumbnailCell")
        
        view.addSubview(collectionView)
    }
}

// MARK: - UICollectionViewDataSource

extension UIKitGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath) as! ThumbnailCollectionCell
        let item = items[indexPath.item]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension UIKitGalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        let detailVC = UIKitImageDetailViewController(imageName: item.name, format: item.format)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - 썸네일 셀

class ThumbnailCollectionCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let formatBadge = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 이미지 뷰
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        contentView.addSubview(imageView)
        
        // 포맷 뱃지
        formatBadge.font = .systemFont(ofSize: 10, weight: .bold)
        formatBadge.textColor = .white
        formatBadge.textAlignment = .center
        formatBadge.layer.cornerRadius = 4
        formatBadge.clipsToBounds = true
        contentView.addSubview(formatBadge)
        
        // 이름 레이블
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textAlignment = .center
        nameLabel.textColor = .label
        contentView.addSubview(nameLabel)
        
        // 레이아웃
        imageView.translatesAutoresizingMaskIntoConstraints = false
        formatBadge.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            formatBadge.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 6),
            formatBadge.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 6),
            formatBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            formatBadge.heightAnchor.constraint(equalToConstant: 18),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with item: ImageItem) {
        nameLabel.text = item.name
        formatBadge.text = item.format
        formatBadge.backgroundColor = formatColor(item.format)
        
        // 썸네일 로드
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let thumbnail = ImageCache.shared.getThumbnailOrCreate(forKey: item.name, maxSize: 200)
            
            DispatchQueue.main.async {
                self?.imageView.image = thumbnail
            }
        }
    }
    
    private func formatColor(_ format: String) -> UIColor {
        switch format {
        case "JPEG": return .systemOrange
        case "PNG": return .systemBlue
        case "WebP": return .systemGreen
        default: return .systemGray
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

// MARK: - SwiftUI Wrapper

struct UIKitGalleryView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let galleryVC = UIKitGalleryViewController()
        let navController = UINavigationController(rootViewController: galleryVC)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // 업데이트 필요 시
    }
}

