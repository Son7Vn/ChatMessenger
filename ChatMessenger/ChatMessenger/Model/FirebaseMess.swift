//
//  FirebaseMess.swift
//  ChatMessenger
//
//  Created by SonGoku on 08/03/2022.
//

import Foundation
import Firebase

class FirebaseMess: NSObject {
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    static let shared = FirebaseMess()
    
    override init() {
        FirebaseApp.configure()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()
        
        super.init()
    }
}
