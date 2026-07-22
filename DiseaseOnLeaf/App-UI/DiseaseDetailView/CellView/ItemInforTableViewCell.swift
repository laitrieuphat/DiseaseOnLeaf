//
//  ItemInforTableViewCell.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 22/7/26.
//

import UIKit


class ItemInforTableViewCell: UITableViewCell {
    static let identifier = "ItemInforTableViewCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(detailsStackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            detailsStackView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 12),
            detailsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            detailsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            detailsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with item: DiseaseDetail, currentField: DiseaseDetail.CodingKeys) {
        let config = item.iconConfig(for: currentField)
        
        
        titleLabel.text = currentField.rawValue
        iconImageView.image = UIImage(systemName: config.systemName)
        iconImageView.tintColor = config.color
        
        // Xóa các item cũ trong stack view (để tránh lỗi khi tái sử dụng cell)
        detailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Lấy mảng dữ liệu chuẩn kiểu [String] tương ứng với từng thuộc tính
        let detailsList = item.valuesArray(for: currentField)
        
        // Thêm các gạch đầu dòng mới vào StackView một cách an toàn
        for detail in detailsList {
            let label = UILabel()
            label.text = "• \(detail)"
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .darkGray
            label.numberOfLines = 0
            detailsStackView.addArrangedSubview(label)
        }
    }

}
