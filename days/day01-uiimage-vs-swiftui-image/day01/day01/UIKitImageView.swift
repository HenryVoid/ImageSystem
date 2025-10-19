//
//  UIKitImageView.swift
//  day01
//
//  Created by 송형욱 on 10/19/25.
//

import SwiftUI
import UIKit

struct UIKitImageView: UIViewRepresentable {
  func makeUIView(context: Context) -> some UIView {
    let uIImageView = UIImageView(image: UIImage(named: "sample"))
    uIImageView.contentMode = .scaleAspectFit
    return uIImageView
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct InteropDemo: View {
  var body: some View {
    VStack(spacing: 12) {
      Text("UIKit UIImageView in SwiftUI")
        .font(.headline)
      UIKitImageView()
        .frame(height: 120)
        .border(.gray.opacity(0.3))
    }
    .padding()
  }
}

#Preview {
  InteropDemo()
}
