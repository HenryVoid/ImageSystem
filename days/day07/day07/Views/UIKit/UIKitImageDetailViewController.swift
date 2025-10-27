//
//  UIKitImageDetailViewController.swift
//  day07
//
//  UIKit 기반 이미지 상세보기 (UIScrollView + 줌)
//

import UIKit
import SwiftUI

/// UIKit 이미지 상세 뷰 컨트롤러
class UIKitImageDetailViewController: UIViewController {
    
    private let imageName: String
    private let format: String
    
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var metadata: ImageMetadata?
    
    private var showMetadata = false
    private var metadataView: UIView?
    
    init(imageName: String, format: String) {
        self.imageName = imageName
        self.format = format
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = imageName
        view.backgroundColor = .black
        
        setupScrollView()
        setupImageView()
        setupToolbar()
        loadImage()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        // 더블탭 제스처
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
    }
    
    private func setupToolbar() {
        // Info 버튼
        let infoButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleMetadata)
        )
        
        // 리셋 버튼
        let resetButton = UIBarButtonItem(
            title: "리셋",
            style: .plain,
            target: self,
            action: #selector(resetZoom)
        )
        
        navigationItem.rightBarButtonItems = [infoButton, resetButton]
    }
    
    private func loadImage() {
        let signpost = Signpost.imageLoad(label: imageName)
        signpost.begin()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let image = ImageLoader.shared.loadUIImage(named: self.imageName)
            let metadata = ImageLoader.shared.extractMetadata(named: self.imageName)
            
            DispatchQueue.main.async {
                signpost.end()
                
                self.imageView.image = image
                self.metadata = metadata
                
                if let img = image {
                    // 이미지 크기에 맞게 프레임 설정
                    let imageSize = img.size
                    self.imageView.frame = CGRect(origin: .zero, size: imageSize)
                    self.scrollView.contentSize = imageSize
                    
                    // 중앙 정렬
                    self.centerImage()
                    
                    PerformanceLogger.log("UIKit 이미지 로드 완료: \(self.imageName) (\(Int(imageSize.width))x\(Int(imageSize.height)))", category: "loading")
                }
            }
        }
    }
    
    private func centerImage() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        // 수평 중앙 정렬
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        // 수직 중앙 정렬
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let touchPoint = gesture.location(in: imageView)
            let newZoomScale = scrollView.maximumZoomScale / 2
            let size = scrollView.bounds.size
            let width = size.width / newZoomScale
            let height = size.height / newZoomScale
            let x = touchPoint.x - (width / 2)
            let y = touchPoint.y - (height / 2)
            let rectToZoom = CGRect(x: x, y: y, width: width, height: height)
            scrollView.zoom(to: rectToZoom, animated: true)
        }
    }
    
    @objc private func resetZoom() {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
    
    @objc private func toggleMetadata() {
        showMetadata.toggle()
        
        if showMetadata {
            showMetadataView()
        } else {
            hideMetadataView()
        }
    }
    
    private func showMetadataView() {
        guard let metadata = metadata else { return }
        
        // 메타데이터 뷰 생성
        let container = UIView()
        container.backgroundColor = .systemBackground.withAlphaComponent(0.95)
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        
        // 타이틀
        let titleLabel = UILabel()
        titleLabel.text = "메타데이터"
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        stackView.addArrangedSubview(titleLabel)
        
        // 구분선
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(divider)
        
        // 메타데이터 항목들
        addMetadataRow(to: stackView, label: "포맷", value: metadata.format.rawValue)
        addMetadataRow(to: stackView, label: "크기", value: "\(Int(metadata.size.width)) × \(Int(metadata.size.height)) px")
        
        if let fileSize = metadata.fileSize {
            addMetadataRow(to: stackView, label: "파일 크기", value: ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
        }
        
        addMetadataRow(to: stackView, label: "알파 채널", value: metadata.hasAlpha ? "있음" : "없음")
        
        container.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        metadataView = container
    }
    
    private func hideMetadataView() {
        metadataView?.removeFromSuperview()
        metadataView = nil
    }
    
    private func addMetadataRow(to stackView: UIStackView, label: String, value: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 12)
        labelView.textColor = .secondaryLabel
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = .systemFont(ofSize: 12, weight: .bold)
        valueView.textAlignment = .right
        
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(valueView)
        
        stackView.addArrangedSubview(row)
    }
}

// MARK: - UIScrollViewDelegate

extension UIKitImageDetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}

// MARK: - SwiftUI Wrapper

struct UIKitImageDetailView: UIViewControllerRepresentable {
    let imageName: String
    let format: String
    
    func makeUIViewController(context: Context) -> UIKitImageDetailViewController {
        return UIKitImageDetailViewController(imageName: imageName, format: format)
    }
    
    func updateUIViewController(_ uiViewController: UIKitImageDetailViewController, context: Context) {
        // 업데이트 필요 시
    }
}

