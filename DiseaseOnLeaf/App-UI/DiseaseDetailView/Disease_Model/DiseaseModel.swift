//
//  DiseaseModel.swift
//  DiseaseOnLeaf
//
//  Created by Minh on 22/7/26.
//

import Foundation
import UIKit

struct DiseaseDetail: Codable {
    let nameOfDisease: String
    let symptoms: [String]
    let causes: [String]
    let prevention: [String]
    let treatment: [String]
    let notes: String
    var caseList = DiseaseDetail.CodingKeys.allCases
    
    
    enum CodingKeys: String, CodingKey, CaseIterable {
         case nameOfDisease = "Tên bệnh"
         case symptoms = "Triệu chứng"
         case causes = "Nguyên nhân"
         case prevention = "Cách phòng ngừa"
         case treatment = "Điều trị"
         case notes = "Ghi chú"
     }
    
     func valuesArray(for key: CodingKeys) -> [String] {
         switch key {
         case .nameOfDisease:
             return [nameOfDisease]
         case .notes:
             return [notes]
         case .symptoms:
             return symptoms
         case .causes:
             return causes
         case .prevention:
             return prevention
         case .treatment:
             return treatment
         }
     }
    
    func iconConfig(for key: CodingKeys) -> (systemName: String, color: UIColor) {
            switch key {
            case .nameOfDisease:
                return ("exclamationmark.triangle.fill", .systemOrange) // Icon cảnh báo (Màu cam)
            case .symptoms:
                return ("eye.fill", .systemBlue)                        // Icon con mắt theo dõi (Màu xanh dương)
            case .causes:
                return ("questionmark.circle.fill", .systemRed)          // Icon dấu hỏi tìm nguyên nhân (Màu đỏ)
            case .prevention:
                return ("shield.fill", .systemTeal)                      // Icon cái khiên phòng vệ (Màu xanh teal)
            case .treatment:
                return ("cross.case.fill", .systemGreen)                 // Icon hộp cứu thương (Màu xanh lá)
            case .notes:
                return ("doc.plaintext.fill", .systemGray)               // Icon tờ ghi chú (Màu xám)
            }
        }
}

typealias DiseaseInfo = [String: DiseaseDetail]
