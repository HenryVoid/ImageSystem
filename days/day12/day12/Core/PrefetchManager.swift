//
//  PrefetchManager.swift
//  day12
//
//  이미지 프리패칭 관리자
//

import UIKit
import Foundation

/// 프리패칭 관리자
@MainActor
class PrefetchManager: ObservableObject {
    @Published private(set) var prefetchedIndices: Set<Int> = []
    @Published private(set) var isActive: Bool = true
    
    private var prefetchTasks: [Int: Task<Void, Never>] = [:]
    private let cache = ImageCacheManager.shared
    
    // MARK: - Configuration
    
    /// 프리패칭 활성화/비활성화
    func setActive(_ active: Bool) {
        isActive = active
        if !active {
            cancelAllPrefetches()
        }
    }
    
    // MARK: - Prefetch Operations
    
    /// 여러 인덱스에 대한 이미지 프리패치
    /// - Parameters:
    ///   - indices: 프리패치할 인덱스 배열
    ///   - urlProvider: 인덱스를 URL로 변환하는 클로저
    func prefetch(indices: [Int], urlProvider: @escaping (Int) -> URL) {
        guard isActive else { return }
        
        for index in indices {
            // 이미 프리패치 중이면 스킵
            guard prefetchTasks[index] == nil else { continue }
            
            // 이미 프리패치 완료되었으면 스킵
            guard !prefetchedIndices.contains(index) else { continue }
            
            // 새로운 프리패치 Task 생성
            let task = Task {
                await prefetchImage(index: index, url: urlProvider(index))
            }
            
            prefetchTasks[index] = task
        }
    }
    
    /// 특정 인덱스들의 프리패치 취소
    /// - Parameter indices: 취소할 인덱스 배열
    func cancelPrefetch(indices: [Int]) {
        for index in indices {
            prefetchTasks[index]?.cancel()
            prefetchTasks.removeValue(forKey: index)
        }
    }
    
    /// 모든 프리패치 취소
    func cancelAllPrefetches() {
        for task in prefetchTasks.values {
            task.cancel()
        }
        prefetchTasks.removeAll()
    }
    
    /// 프리패치 상태 리셋
    func reset() {
        cancelAllPrefetches()
        prefetchedIndices.removeAll()
    }
    
    // MARK: - Private
    
    private func prefetchImage(index: Int, url: URL) async {
        // 이미 캐시에 있는지 확인
        if await cache.image(for: url) != nil {
            await MainActor.run {
                prefetchedIndices.insert(index)
            }
            cleanupTask(for: index)
            return
        }
        
        do {
            // 낮은 우선순위로 백그라운드에서 다운로드
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Task가 취소되었는지 확인
            try Task.checkCancellation()
            
            // 백그라운드에서 이미지 디코딩
            if let image = await decodeImage(data) {
                // 캐시에 저장
                await cache.setImage(image, for: url)
                
                // 프리패치 완료 표시
                await MainActor.run {
                    prefetchedIndices.insert(index)
                }
            }
        } catch is CancellationError {
            // 취소된 경우 - 정상 동작
        } catch {
            // 에러는 조용히 무시 (메인 로드 시 재시도될 것)
            print("Prefetch failed for index \(index): \(error.localizedDescription)")
        }
        
        cleanupTask(for: index)
    }
    
    private func decodeImage(_ data: Data) async -> UIImage? {
        await Task.detached(priority: .utility) {
            UIImage(data: data)
        }.value
    }
    
    private func cleanupTask(for index: Int) {
        Task { @MainActor in
            prefetchTasks.removeValue(forKey: index)
        }
    }
}

// MARK: - Extensions

extension PrefetchManager {
    /// 프리패치 통계
    var statistics: String {
        """
        Prefetch Statistics:
        - Prefetched: \(prefetchedIndices.count)
        - In Progress: \(prefetchTasks.count)
        - Active: \(isActive ? "Yes" : "No")
        """
    }
    
    /// 특정 인덱스가 프리패치되었는지 확인
    func isPrefetched(_ index: Int) -> Bool {
        prefetchedIndices.contains(index)
    }
    
    /// 프리패치 진행 중인 인덱스 개수
    var inProgressCount: Int {
        prefetchTasks.count
    }
}


