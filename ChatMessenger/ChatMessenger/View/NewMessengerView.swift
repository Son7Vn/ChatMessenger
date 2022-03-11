//
//  NewMessengerView.swift
//  ChatMessenger
//
//  Created by SonGoku on 10/03/2022.
//

import SwiftUI
import SDWebImageSwiftUI

class NewMessengerViewMode: ObservableObject {
    @Published var errMessenger = ""
    @Published var allChatUser = [ChatUser]()
    init() {
        
        fetchAllUser()
    }
    
    private func fetchAllUser() {
        
        FirebaseMess.shared.firestore.collection("user")
            .getDocuments { querrySnapshot, err in
                if let err = err {
                    self.errMessenger = "Failed to fetch all user: \(err)"
                    return
                }
                querrySnapshot?.documents.forEach({ snapshot in
                    let data = snapshot.data()
                    self.allChatUser.append(.init(data: data))
                })
            }
                
    }
    
}

struct NewMessengerView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var nm = NewMessengerViewMode()
    let didSelectNewMessenger: (ChatUser) -> ()
    
    var body: some View {
        
        NavigationView {
            ScrollView {
            
                ForEach(nm.allChatUser) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewMessenger(user)
                    } label: {
                        HStack(spacing: 10) {
                            WebImage(url: URL(string: user.imageProfileURL))
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .frame(width: 50, height: 50)
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(.label),lineWidth: 2))
                            
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                                
                        }.padding(.horizontal)
                    }
                    Divider()
                    .padding(.vertical, 10)
                    
                }
            }.navigationTitle("New Messenger")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }

                    }
                }
        }
    }
}

struct NewMessengerView_Previews: PreviewProvider {
    static var previews: some View {
//        NewMessengerView()
        MainMessengerView()
    }
}
