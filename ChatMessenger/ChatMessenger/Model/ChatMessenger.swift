//
//  ChatMessenger.swift
//  ChatMessenger
//
//  Created by SonGoku on 10/03/2022.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct ChatMessenger: Codable,Identifiable {
    @DocumentID var id : String?
    
    let text: String
    let fromId: String
    let toId: String
    let email: String
    let timestamp: Date
}
