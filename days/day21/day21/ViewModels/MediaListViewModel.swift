import Foundation
import Photos
import Combine

@MainActor
class MediaListViewModel: ObservableObject {
    @Published var assets: [MediaAsset] = []
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    
    private let service = PhotoLibraryService.shared
    
    func requestPermissionAndLoadAssets() async {
        let status = await service.checkAuthorizationStatus()
        self.permissionStatus = status
        
        if status == .authorized || status == .limited {
            loadAssets()
        }
    }
    
    func loadAssets() {
        isLoading = true
        // Fetch는 동기적으로 동작하므로, UI 블로킹 방지를 위해 Task detached 혹은 백그라운드 큐 고려 가능
        // 하지만 fetchAssets 자체는 메타데이터만 가져오므로 매우 빠름.
        // 여기서는 간단히 처리
        let fetchedAssets = service.fetchMediaAssets()
        self.assets = fetchedAssets
        self.isLoading = false
    }
}

