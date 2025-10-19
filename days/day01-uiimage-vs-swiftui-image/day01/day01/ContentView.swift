//
//  ContentView.swift
//  day01
//
//  Created by 송형욱 on 10/19/25.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack(spacing: 16) {
      Text("Asset vs SF Symbol vs UIImage")
        .font(.headline)
      
      // 1) Asset
      Image("sample")
        .resizable()
        .scaledToFit()
        .frame(height: 120)
      
      // 2) SF Symbol
      Image(systemName: "heart.fill")
        .font(.system(size: 48))
        .foregroundStyle(.pink)
      
      // 3) UIImage 재활용
      let ui = UIImage(named: "sample")!
      Image(uiImage: ui)
        .resizable()
        .scaledToFit()
        .frame(height: 120)
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
