//
//  snapshot.swift
//  day01
//
//  Created by 송형욱 on 10/19/25.
//

import SwiftUI
import UIKit

extension View {
  func snapshot(width: CGFloat, height: CGFloat) -> UIImage {
    let controller = UIHostingController(rootView: self)
    let view = controller.view
    let target = CGSize(width: width, height: height)
    view?.bounds = CGRect(origin: .zero, size: target)
    view?.backgroundColor = .clear
    
    let renderer = UIGraphicsImageRenderer(size: target)
    return renderer.image { _ in
      view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
    }
  }
}

// 사용 예시 (디버그용)
struct SnapshotTestView: View {
  var body: some View {
    let img = Image("sample")
      .font(.system(size: 80))
      .foregroundStyle(.yellow)
      .snapshot(width: 500, height: 300) // UIImage 생성
    
    return VStack {
      Text("Snapshot → UIImage")
      Image(uiImage: img).resizable()
        .scaledToFit()
        .frame(height: 120)
    }
  }
}

#Preview {
  SnapshotTestView()
}
