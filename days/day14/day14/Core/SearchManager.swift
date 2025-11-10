//
//  SearchManager.swift
//  day14
//
//  검색 및 필터링 로직 관리
//

import Foundation

/// 검색 및 필터 관리자
@Observable
class SearchManager {
    /// 검색어
    var searchText: String = ""
    
    /// 선택된 카테고리
    var selectedCategory: ImageSizeCategory = .all
    
    /// 북마크된 이미지 ID 목록
    private(set) var bookmarkedImageIDs: Set<String> = []
    
    /// 좋아요 누른 이미지 ID 목록
    private(set) var likedImageIDs: Set<String> = []
    
    /// UserDefaults 키
    private let bookmarksKey = "bookmarked_images"
    private let likesKey = "liked_images"
    
    init() {
        loadBookmarks()
        loadLikes()
    }
    
    /// 이미지 필터링
    func filterImages(_ images: [ImageModel]) -> [ImageModel] {
        var filtered = images
        
        // 카테고리 필터
        if selectedCategory != .all {
            filtered = filtered.filter { $0.sizeCategory == selectedCategory }
        }
        
        // 검색어 필터
        if !searchText.isEmpty {
            filtered = filtered.filter { image in
                image.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    /// 북마크 토글
    func toggleBookmark(for imageID: String) {
        if bookmarkedImageIDs.contains(imageID) {
            bookmarkedImageIDs.remove(imageID)
        } else {
            bookmarkedImageIDs.insert(imageID)
        }
        saveBookmarks()
    }
    
    /// 북마크 여부 확인
    func isBookmarked(_ imageID: String) -> Bool {
        return bookmarkedImageIDs.contains(imageID)
    }
    
    /// 좋아요 토글
    func toggleLike(for imageID: String) {
        if likedImageIDs.contains(imageID) {
            likedImageIDs.remove(imageID)
        } else {
            likedImageIDs.insert(imageID)
        }
        saveLikes()
    }
    
    /// 좋아요 여부 확인
    func isLiked(_ imageID: String) -> Bool {
        return likedImageIDs.contains(imageID)
    }
    
    /// 북마크 저장
    private func saveBookmarks() {
        let array = Array(bookmarkedImageIDs)
        UserDefaults.standard.set(array, forKey: bookmarksKey)
    }
    
    /// 북마크 로드
    private func loadBookmarks() {
        if let array = UserDefaults.standard.array(forKey: bookmarksKey) as? [String] {
            bookmarkedImageIDs = Set(array)
        }
    }
    
    /// 좋아요 저장
    private func saveLikes() {
        let array = Array(likedImageIDs)
        UserDefaults.standard.set(array, forKey: likesKey)
    }
    
    /// 좋아요 로드
    private func loadLikes() {
        if let array = UserDefaults.standard.array(forKey: likesKey) as? [String] {
            likedImageIDs = Set(array)
        }
    }
    
    /// 검색 초기화
    func resetSearch() {
        searchText = ""
        selectedCategory = .all
    }
}

