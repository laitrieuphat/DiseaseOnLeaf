//
//  DiseaseDetailViewController.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 22/7/26.
//

import UIKit

import UIKit



struct DiseaseSection {
    let title: String
    let iconName: String // Tên icon (có thể dùng SF Symbols)
    let iconColor: UIColor
    let details: [String]
}

class DiseaseDetailViewController: UIViewController {
    var typeOfDiseaseCurrent: String? = nil
    var jsonDataDic: DiseaseInfo = DiseaseInfo() // Khởi tạo với Dictionary rỗng để tránh nil
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(white: 0.96, alpha: 1.0) // Màu nền xám nhạt giống hình
        tv.separatorStyle = .none // Ẩn gạch ngang mặc định
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    
    // Dữ liệu mẫu (mock data) trích xuất từ thiết kế của bạn
    private let sections: [DiseaseSection] = [
        DiseaseSection(title: "Triệu chứng", iconName: "list.bullet.rectangle.portrait", iconColor: .systemGreen, details: [
            "Đốm nâu đen trên lá",
            "Lá rụng sớm"
        ]),
        DiseaseSection(title: "Nguyên nhân", iconName: "asterisk.circle.fill", iconColor: .systemGreen, details: [
            "Nấm hoặc vi khuẩn"
        ]),
        DiseaseSection(title: "Cách phòng ngừa", iconName: "shield.fill", iconColor: .systemGreen, details: [
            "Vệ sinh vườn cây, loại bỏ lá bệnh",
            "Phun thuốc bảo vệ thực vật định kỳ"
        ])
    ]
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        
        jsonDataDic = Bundle.main.decode([String: DiseaseDetail].self.self, from: "disease_infor.json")
        
        jsonDataDic.forEach { key, value in
            
            if let key = typeOfDiseaseCurrent {
                if key == key {
                    print("Matched Key: \(key)")
                    print("Type of Disease Label: \(value.typeOfDiseaseLbl)")
                    print("Symptoms: \(value.symptoms)")
                    print("Causes: \(value.causes)")
                    print("Prevention: \(value.prevention)")
                    print("Treatment: \(value.treatment)")
                    print("Notes: \(value.notes)")
                    
                }
                
                
                
                
                
            }
            
            
        }
        
        
    }
    
    
    
    
    
    
    private func setupNavigationBar() {
        title = "Đốm lá"
        view.backgroundColor = .white
        
        // Đổi màu Navigation Bar thành màu xanh lá
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0) // Chỉnh mã màu xanh cho khớp
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white // Màu của nút Back
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItemInforTableViewCell.self, forCellReuseIdentifier: ItemInforTableViewCell.identifier)
        
        // Thiết lập tự động tính toán chiều cao cho cell
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        
        // Thiết lập Header ImageView
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 220))
        let imageView = UIImageView(frame: headerView.bounds)
        imageView.image = UIImage(named: "icon_mamxanh")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Tùy chọn: Bo tròn góc dưới của ảnh nếu muốn
        imageView.layer.cornerRadius = 16
        imageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        headerView.addSubview(imageView)
        tableView.tableHeaderView = headerView
    }
}

// MARK: - UITableView DataSource & Delegate
extension DiseaseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItemInforTableViewCell.identifier, for: indexPath) as? ItemInforTableViewCell else {
            return UITableViewCell()
        }
        
        let sectionData = sections[indexPath.row]
        cell.configure(with: sectionData)
        return cell
    }
}
