//
//  DiseaseModel.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 22/7/26.
//

import Foundation
import UIKit


// Model đại diện cho chi tiết của từng loại bệnh/trạng thái
struct DiseaseDetail: Codable {
    let typeOfDiseaseLbl: String  // Đây là biến bị lỗi lúc đầu của bạn
    let symptoms: [String]
    let causes: [String]
    let prevention: [String]
    let treatment: [String]
    let notes: String

    // Map chính xác các key tiếng Việt có dấu và khoảng trắng từ JSON sang Swift
    enum CodingKeys: String, CodingKey {
        case typeOfDiseaseLbl = "Tên bệnh"
        case symptoms = "Triệu chứng"
        case causes = "Nguyên nhân"
        case prevention = "Cách phòng ngừa"
        case treatment = "Điều trị"
        case notes = "Ghi chú"
    }
}

// Vì JSON của bạn là một Object có các key như "chay_la", "dom_la"...
// Nên kiểu dữ liệu tổng sẽ là một Dictionary (Từ điển) như sau:
typealias DiseaseInfo = [String: DiseaseDetail]

