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
    let profileImageURL: String
    let timestamp: Date
}
