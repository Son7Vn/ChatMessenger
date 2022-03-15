//
//  RecentMessenger.swift
//  ChatMessenger
//
//  Created by SonGoku on 11/03/2022.
//

import Foundation
import FirebaseFirestoreSwift
import Firebase

struct RecentMessenger: Codable,Identifiable {
    @DocumentID var id: String?
    
    let text: String
    let fromId: String
    let toId: String
    let email: String
    let imageProfileURL: String
    let timestamp: Date
    
    var username: String {
        email.components(separatedBy: "@") .first ?? email
    }
    
    var timeSendMessenger: String {
        let formater = RelativeDateTimeFormatter()
        formater.unitsStyle = .abbreviated
        return formater.localizedString(for: timestamp, relativeTo: Date())
    }
    
}
