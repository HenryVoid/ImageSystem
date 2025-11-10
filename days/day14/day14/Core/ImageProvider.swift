//
//  ImageProvider.swift
//  day14
//
//  Picsum Photos API에서 이미지 목록을 가져오는 Provider
//

import Foundation

/// 이미지 제공자
@Observable
class ImageProvider {
    /// 전체 이미지 목록
    private(set) var allImages: [ImageModel] = []
    
    /// 로딩 상태
    private(set) var isLoading = false
    
    /// 에러 메시지
    private(set) var errorMessage: String?
    
    /// 현재 페이지
    private var currentPage = 1
    
    /// 페이지당 아이템 수
    private let itemsPerPage = 30
    
    /// API Base URL
    private let baseURL = "https://picsum.photos/v2/list"
    
    init() {
        // 초기 로드
        Task {
            await loadInitialImages()
        }
    }
    
    /// 초기 이미지 로드 (200개)
    func loadInitialImages() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 페이지 1-7 로드 (약 200개)
            var images: [ImageModel] = []
            
            for page in 1...7 {
                let pageImages = try await fetchImages(page: page, limit: itemsPerPage)
                images.append(contentsOf: pageImages)
            }
            
            await MainActor.run {
                self.allImages = images
                self.currentPage = 7
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "이미지 로드 실패: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 추가 이미지 로드 (무한 스크롤용)
    func loadMoreImages() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            let nextPage = currentPage + 1
            let newImages = try await fetchImages(page: nextPage, limit: itemsPerPage)
            
            await MainActor.run {
                self.allImages.append(contentsOf: newImages)
                self.currentPage = nextPage
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "추가 이미지 로드 실패: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// 이미지 새로고침
    func refresh() async {
        allImages = []
        currentPage = 1
        await loadInitialImages()
    }
    
    /// Picsum API에서 이미지 가져오기
    private func fetchImages(page: Int, limit: Int) async throws -> [ImageModel] {
        guard let url = URL(string: "\(baseURL)?page=\(page)&limit=\(limit)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let picsumPhotos = try JSONDecoder().decode([PicsumPhoto].self, from: data)
        return picsumPhotos.map { ImageModel.from(picsumPhoto: $0) }
    }
    
    /// 특정 이미지 가져오기
    func getImage(by id: String) -> ImageModel? {
        return allImages.first { $0.id == id }
    }
}

