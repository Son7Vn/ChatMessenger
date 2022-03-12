//
//  ChatLogView.swift
//  ChatMessenger
//
//  Created by SonGoku on 10/03/2022.
//

import SwiftUI
import SDWebImageSwiftUI

class ChatLogViewMode: ObservableObject {
    @Published var texMessenger = ""
    @Published var chatUser: ChatUser?
    @Published var errMessenger = ""
    
    init(chatUser:ChatUser?) {
        self.chatUser = chatUser
        
        fetchChatMessenger()
    }
    
    @Published var count = 0
    func handleSend() {
        
        guard let fromId = FirebaseMess.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        guard let chatUserdata = chatUser else {return}
        
        let clvdata = ChatMessenger(id: nil, text: self.texMessenger, fromId: fromId, toId: toId, email: chatUserdata.email, timestamp: Date())
        
        let refFromId = FirebaseMess.shared.firestore.collection(FirebaseConstant.messenger)
            .document(fromId)
            .collection(toId)
            .document()
        
        try? refFromId.setData(from: clvdata) { err in
            if let err = err {
                self.errMessenger = "Failed to upload data\(err)"
                print(self.errMessenger)
                return
            }
            
            self.errMessenger = "Successfully upload textMessenger"
            print(self.errMessenger)
            
        }
        
        let refToId = FirebaseMess.shared.firestore.collection(FirebaseConstant.messenger)
            .document(toId)
            .collection(fromId)
            .document()
        
        try? refToId.setData(from: clvdata) { err in
            if let err = err {
                self.errMessenger = "Failed to upload data\(err)"
                print(self.errMessenger)
                return
            }
            
            self.storeRecentMessenger()
            
            self.texMessenger = ""
            
            self.errMessenger = "Successfully upload textMessenger from toID"
            print(self.errMessenger)
            
        }
        
    }
    
    @Published var allMessenger = [ChatMessenger]()
    private func fetchChatMessenger() {
        guard let fromId = FirebaseMess.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        
        FirebaseMess.shared.firestore.collection(FirebaseConstant.messenger)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstant.timestamp)
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    self.errMessenger = "Failed to get textMessenger: \(err)"
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ snapshot in
                    if snapshot.type == .added {
                        //check type cua data neu type add moi dc duyet vao
                        do {
                            if let snapshotdata = try snapshot.document.data(as: ChatMessenger.self) {
                                //decode tu firestore/ phai cho vao if de check ca nil snapshotdata
                                self.allMessenger.append(snapshotdata)
                                
                            }
                        } catch {
                            print("Failed to fetch data: \(error)")
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func storeRecentMessenger() {
        guard let fromId = FirebaseMess.shared.auth.currentUser?.uid else {return}
        guard let chatUserdata = chatUser else {return}
        guard let toId = self.chatUser?.uid else {return}
        
        let dataRecent = RecentMessenger(id: nil, text: self.texMessenger, fromId: fromId, toId: toId, email: chatUserdata.email, profileImageURL: chatUserdata.imageProfileURL, timestamp: Date())
        
        let refSending = FirebaseMess.shared.firestore.collection(FirebaseConstant.recent_messenger)
            .document(fromId)
            .collection(FirebaseConstant.messenger)
            .document(toId)
        
        try? refSending.setData(from: dataRecent) { error in
            if let error = error {
                self.errMessenger = "Failed to store recent messenger: \(error)"
                return
            }
            self.errMessenger = "stored recent messenger is success!"
            print(self.errMessenger)
        }
        let refRecipient = FirebaseMess.shared.firestore.collection(FirebaseConstant.recent_messenger)
            .document(toId)
            .collection(FirebaseConstant.messenger)
            .document(fromId)
        
        guard let currentUser = FirebaseMess.shared.auth.currentUser else {return}
    
        
        let dataRecentRecipient = RecentMessenger(id: nil, text: self.texMessenger, fromId: fromId, toId: toId, email: currentUser.email ?? "", profileImageURL: chatUserdata.imageProfileURL, timestamp: Date())
        
        try? refRecipient.setData(from: dataRecentRecipient) { error in
            if let error = error {
                self.errMessenger = "Failed to store recent messenger fr Recipient: \(error)"
                return
            }
            self.errMessenger = "stored recent messenger is success fr Recipient!"
            print(self.errMessenger)
        }
    }
}

struct ChatLogView: View {

    let chatUser: ChatUser?
    @ObservedObject var clv : ChatLogViewMode

    init(chatUser:ChatUser?) {
        self.chatUser = chatUser
        self.clv = .init(chatUser: chatUser)
        // custom init de put chatUser len ChatLogViewMode
    }

    var body: some View {
        ZStack {
            messagesView
            VStack(spacing: 0) {
                Spacer()
                chatBottomBar
                    .background(Color.white.ignoresSafeArea())
            }
        }
        .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
    }
    private var messagesView: some View {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack {
                        ForEach(clv.allMessenger) { am in
                            ViewMessenger(am:am)
                        }
                        HStack{ Spacer() }
                        .frame(height: 50)
                        .id("DownHere")
                    }
                    .onReceive(clv.$count) { _ in
                                withAnimation(.easeOut(duration: 0.5)) {
                                    scrollViewProxy.scrollTo("DownHere", anchor: .bottom)
                    }
                }
            }
        }
            .background(Color(.init(white: 0.95, alpha: 1)))
}
    
    private var chatBottomBar: some View {
            HStack(spacing: 16) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(Color(.darkGray))
                ZStack {
                    DescriptionPlaceholder()
                    TextEditor(text: $clv.texMessenger)
                        .opacity(clv.texMessenger.isEmpty ? 0.5 : 1)
                }
                .frame(height: 40)
                Button {
                    clv.handleSend()
                           } label: {
                               Text("Send")
                                   .foregroundColor(.white)
                           }
                           .padding(.horizontal)
                           .padding(.vertical, 6)
                           .background(Color.blue)
                           .cornerRadius(5)
                       }
                       .padding(.horizontal)
                       .padding(.vertical, 7)
                   }
}

struct ViewMessenger: View {
    let am: ChatMessenger
    var body: some View {
        VStack {
            if am.fromId == FirebaseMess.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(am.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    
                    HStack {
                        Text(am.text)
                            .foregroundColor(Color(.label))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
//            ChatLogView(chatUser: .init(data: ["uid":"qs2EsgGTtKbICJbtZuPH2vgatnj1","email": "sonphan2@gmail.com"]))
            MainMessengerView()
        }
        
        
    }
}
