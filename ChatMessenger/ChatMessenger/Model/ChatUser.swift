//
//  ChatUser.swift
//  ChatMessenger
//
//  Created by SonGoku on 08/03/2022.
//

import Foundation
import Firebase

struct ChatUser: Identifiable {
    
    var id : String {uid}
    
    var email,uid,imageProfileURL : String
    
    init(data: [String:Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.imageProfileURL = data["imageProfileURL"] as? String ?? ""
    }
    
}
