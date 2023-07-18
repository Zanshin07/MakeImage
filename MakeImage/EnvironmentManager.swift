//
//  EnvironmentManager.swift
//  MakeImage
//
//  Created by cmStudent on 2023/07/03.
//

import Foundation

// deepLに関する部分は消したい　（使わないから）
//enum EnvironmentCategory {
//    case deepL
//    case openAI
//
//    var categoryString: String {
//        switch self {
//        case .deepL:
//            return "DeepL"
//        case .openAI:
//            return "OpenAI"
//        }
//    }
//}

final class EnvironmentManager {
    
    static let shared = EnvironmentManager()
    
    private let values: [String : Any]?
    
    private init() {
        guard let filePath = Bundle.main.path(forResource: "Environment", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: filePath),
              let categories = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String : Any]
        else {
            self.values = nil
            return
        }
        
        self.values = categories["OpenAI"] as? [String : Any]
    }
    
//    private func category(forKey key: EnvironmentCategory) -> [String : Any]? {
//        guard let categories = categories else {
//            return nil
//        }
//
//        return categories[key.categoryString] as? [String : Any]
//    }
    
    func value(forKey key: String) -> Any? {
        
        //guard let keys = category(forKey: group) else { return nil }
        
        return values?[key]
    }
}

