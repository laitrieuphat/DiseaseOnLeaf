//
//  DiseaseDetailViewController.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 22/7/26.
//

import UIKit


class DiseaseDetailViewController: UIViewController {
    var imageView:UIImage? = nil
    var valueTypeOfDiseaseCurrent:DiseaseDetail? = nil
    var caseList = DiseaseDetail.CodingKeys.allCases
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(.backgroundHome)
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    
    init(_ keyDisease:String, _ image:UIImage) {
        super.init(nibName: nil, bundle: nil)
        let jsonDataDic: DiseaseInfo  = Bundle.main.decode([String: DiseaseDetail].self, from: "disease_infor.json")
        self.valueTypeOfDiseaseCurrent = jsonDataDic[keyDisease]
        self.imageView = image
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
    }
    
    private func setupNavigationBar() {
        title = "Chi tiết bệnh lá"
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
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
        tableView.estimatedRowHeight = 10
        
        // Thiết lập Header ImageView
        setupHeaderView()
    }
    
    private func setupHeaderView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 250))
        let imageView = UIImageView(frame: CGRect(x: 9, y: 0, width: view.frame.width, height: 220))
        imageView.image = self.imageView
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        headerView.addSubview(imageView)
        tableView.tableHeaderView = headerView
    }
}

// MARK: - UITableView DataSource & Delegate
extension DiseaseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return caseList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItemInforTableViewCell.identifier, for: indexPath) as? ItemInforTableViewCell,
              let valueTypeOfDiseaseCurrent = valueTypeOfDiseaseCurrent else {
            return UITableViewCell()
        }
        
        let currentField = DiseaseDetail.CodingKeys.allCases[indexPath.row]
        cell.configure(with: valueTypeOfDiseaseCurrent, currentField:currentField )
        return cell
    }
}
