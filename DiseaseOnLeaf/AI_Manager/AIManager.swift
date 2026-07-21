//
//  AIManager.swift
//  DiseaseOnLeaf
//
//  Created by Lai Minh on 20/7/26.
//

import Foundation
import Foundation

// 1. Định nghĩa các mô hình AI, tên file label và icon hệ thống
enum AIModel: String, CaseIterable {
    case b0Aug = "efficientnet_b0_aug"
    case b0Durian = "efficientnetb0_durian"
    
    // Tên file labels tương ứng cho từng mô hình
    var labelsFileName: String {
        switch self {
        case .b0Aug:    return "labels"
        case .b0Durian: return "labels_durain"
        }
    }
    
    // Icon hiển thị tương ứng trong Menu
    var systemImageName: String {
        switch self {
        case .b0Aug:    return "hare.fill"
        case .b0Durian: return "tortoise.fill"
        }
    }
}

// 2. Singleton Manager quản lý trạng thái toàn cục
final class AIManager {
    static let shared = AIManager()
    private init() {}
    
    // Tên thông báo phát đi khi đổi mô hình
    static let modelChangedNotification = Notification.Name("AIModelChangedNotification")
    
    // Biến toàn cục lưu mô hình hiện tại (Mặc định chọn mẫu đầu tiên)
    var currentModel: AIModel = .b0Aug {
        didSet {
            // Phát thông báo toàn ứng dụng mỗi khi biến này bị thay đổi
            NotificationCenter.default.post(name: AIManager.modelChangedNotification, object: nil)
        }
    }
}
