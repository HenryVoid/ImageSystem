import SwiftUI
import UIKit

struct ZoomableImageView: UIViewRepresentable {
    var image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // 초기 리사이징 대응
        
        // 태그를 설정하여 delegate에서 찾기 쉽게 함
        imageView.tag = 999
        
        scrollView.addSubview(imageView)
        
        // 더블 탭 제스처
        let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // 이미지가 변경되었을 때 업데이트 로직이 필요할 수 있음.
        // 간단한 구현을 위해 여기서는 생략하거나, 뷰를 재생성하도록 유도.
        // 만약 이미지가 바뀐다면 imageView.image = image 처리 필요.
        if let imageView = uiView.viewWithTag(999) as? UIImageView {
            imageView.image = image
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageView
        
        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(999)
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            
            if scrollView.zoomScale > 1 {
                scrollView.setZoomScale(1, animated: true)
            } else {
                let point = gesture.location(in: scrollView.viewWithTag(999))
                let scrollSize = scrollView.frame.size
                let size = CGSize(width: scrollSize.width / 3, height: scrollSize.height / 3)
                let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
                scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            }
        }
    }
}

