//
//  LoginViewController.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 23/2/26.
//

import Foundation
import UIKit

class LoginViewController: UIViewController {
    private let viewModel = LoginViewModel()
    // MARK: - UI Components
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white // Màu của vòng xoay
        indicator.hidesWhenStopped = true // Tự động ẩn khi dừng
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Đăng Nhập"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username"
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0)) // Thêm lề trái
        tf.leftView = padding
        tf.leftViewMode = .always
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Đăng Nhập", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupBindings()
    }
    
    // MARK: - Setup Layout
    private func setupUI() {
        view.backgroundColor = .backgroundHome
        view.addSubview(titleLabel)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        loginButton.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Username
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 15),
            passwordTextField.leadingAnchor.constraint(equalTo: usernameTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: usernameTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: usernameTextField.heightAnchor),
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: usernameTextField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: usernameTextField.trailingAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            
            //
            // Căn giữa indicator vào trong loginButton
            loadingIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
    }
    
    private func setupBindings() {
        // Lắng nghe trạng thái loading để hiện/ẩn Indicator
        viewModel.onLoadingStatusChanged = { [weak self] isLoading in
            if isLoading {
                // Khi đang load: hiện vòng xoay, ẩn chữ trên nút, khóa tương tác
                self?.loadingIndicator.startAnimating()
                self?.loginButton.setTitle("", for: .normal)
                self?.loginButton.isEnabled = false
            } else {
                // Khi load xong: dừng vòng xoay, hiện lại chữ, mở tương tác
                self?.loadingIndicator.stopAnimating()
                self?.loginButton.setTitle("Đăng Nhập", for: .normal)
                self?.loginButton.isEnabled = true
            }
        }
        
        // Lắng nghe kết quả login
        viewModel.onLoginResult = { [weak self] success, errorMessage in
            if success {
                print("Chuyển sang màn hình Home")
                self?.navigateToHome()
            } else {
                print("Lỗi: \(errorMessage ?? "")")
                // Hiển thị UIAlertController thông báo lỗi
                self?.showAlert(title: "Thông báo", message: errorMessage ?? "Đăng nhập thất bại.")
            }
        }
    }
    
    private func navigateToHome() {
        let homeVC = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeVC)
        
        // Tạo hiệu ứng chuyển cảnh mượt mà
        guard let window = self.view.window else { return }
        window.rootViewController = navigationController
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    @objc private func handleLogin() {
        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        print("Đang đăng nhập với: \(username)")
        // Gọi hàm login từ ViewModel
        viewModel.login(username: usernameTextField.text, password: passwordTextField.text)
    }
}

extension LoginViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Nút xác nhận
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.usernameTextField.becomeFirstResponder() // Tự động bật bàn phím cho ô Username
        }
        
        alert.addAction(okAction)
        
        // Hiển thị Alert
        self.present(alert, animated: true, completion: nil)
    }
}
