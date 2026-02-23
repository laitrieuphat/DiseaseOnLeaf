//
//  LoginViewModel.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 23/2/26.
//

import Foundation

class LoginViewModel {
    
    // MARK: - Properties
    // Binding closures: Dùng để thông báo cho ViewController khi dữ liệu thay đổi
    var onLoadingStatusChanged: ((Bool) -> Void)?
    var onLoginResult: ((Bool, String?) -> Void)?
    
    // MARK: - Mock API Call
    func login(username: String?, password: String?) {
        // 1. Kiểm tra dữ liệu đầu vào (Validation)
        guard let user = username, !user.isEmpty,
              let pass = password, !pass.isEmpty else {
            self.onLoginResult?(false, "Vui lòng nhập đầy đủ thông tin.")
            return
        }
        
        // 2. Bắt đầu trạng thái Loading
        self.onLoadingStatusChanged?(true)
        
        // 3. Giả lập gọi API (Mock Network Request)
        // Delay 2 giây để giống thực tế
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Giả lập logic kiểm tra tài khoản
            let isSuccess = (user == "admin" && pass == "123456")
            
            // 4. Trả kết quả về Main Thread để cập nhật UI
            DispatchQueue.main.async {
                self.onLoadingStatusChanged?(false)
                
                if isSuccess {
                    self.onLoginResult?(true, nil)
                } else {
                    self.onLoginResult?(false, "Tài khoản hoặc mật khẩu không chính xác.")
                }
            }
        }
    }
}
