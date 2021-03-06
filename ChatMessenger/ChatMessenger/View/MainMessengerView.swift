//
//  MainMessengerView.swift
//  ChatMessenger
//
//  Created by SonGoku on 08/03/2022.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

class MainMessViewMode: ObservableObject {
    @Published var chatUser : ChatUser?
    @Published var errMessenger = ""
    
    init() {
        
        DispatchQueue.main.async {
            self.isCurrentUserLogOut = FirebaseMess.shared.auth.currentUser?.uid == nil
            //gan gtri cho bien logout de show ra LoginView
        }
        fetchChatUser()
        fetchRecentMessenger()
    }
    
    func fetchChatUser() {
        guard let uid = FirebaseMess.shared.auth.currentUser?.uid else {return}
        
        print(errMessenger)
        FirebaseMess.shared.firestore.collection("user")
            .document(uid)
            .getDocument { querySnapshot, err in
                if let err = err {
                    self.errMessenger = "Failed to fetch data: \(err)"
                    print(self.errMessenger)
                    return
                }
                guard let data = querySnapshot?.data() else {return}
                //decode firestore
                self.chatUser = .init(data: data)
                FirebaseMess.shared.currentUser = self.chatUser
            }
    }
    
    @Published var isCurrentUserLogOut = false
    
    func signOut() {
        isCurrentUserLogOut.toggle()
        
        try? FirebaseMess.shared.auth.signOut()
    }
    
    @Published var recentMessenger = [RecentMessenger]()
    private var firestoreListener : ListenerRegistration?
    
    func fetchRecentMessenger(){
        guard let uid = FirebaseMess.shared.auth.currentUser?.uid else {return}
        
        firestoreListener?.remove()
        self.recentMessenger.removeAll()
        //clear data khi logout
        firestoreListener = FirebaseMess.shared.firestore.collection(FirebaseConstant.recent_messenger)
            .document(uid)
            .collection(FirebaseConstant.messenger)
            .order(by: FirebaseConstant.timestamp)
            .addSnapshotListener { querySnapshot, err in
                if let err = err {
                    self.errMessenger = "Failed to fetch recent_messenger: \(err)"
                    return
            }
                querySnapshot?.documentChanges.forEach({ snapshot in
                    let docId = snapshot.document.documentID
                    if let index = self.recentMessenger.firstIndex(where: { rmes in
                        return rmes.id == docId
                        // vi tri index trong array cua messenger cu
                    }) {
                        self.recentMessenger.remove(at: index)
                        //remove array o vi tri cu~
                    }
                    do {
                        if let datarecent = try snapshot.document.data(as: RecentMessenger.self) {
                            
                            self.recentMessenger.insert(datarecent, at: 0)
                            //add messenger moi vao vi tri dau tien
                        }
                        
                    } catch {
                        print("Error to fetchRecentMess: \(error)")
                    }
                })
            }
    }
}

struct MainMessengerView: View {
    
    @State var shouldShowLogoutOptions = false
    @State var isAddNewMessenger = false
    @State var isShowChatLogView = false
    
    
    @ObservedObject private var vm = MainMessViewMode()
    
    private var chatLogViewModel = ChatLogViewMode(chatUser: nil)
    //creat a referance to control a ViewModel(ChatLogViewModel) what we fetched & when we fetched for where which user clicking on
    
    var body: some View {
        NavigationView {
            VStack {
                navigatorCustom
                messengerView
                
                NavigationLink("", isActive: $isShowChatLogView) {
                    ChatLogView(clv: chatLogViewModel)
                    // khoi tao ChatLogView voi chatUser = nil
                }

            }
            .overlay(newMessengerButton,alignment: .bottom)
            .navigationBarHidden(true)
            
        }
    }
    
    private var navigatorCustom: some View {
        HStack {
            WebImage(url: URL(string: vm.chatUser?.imageProfileURL ?? ""))
                .resizable()
                .scaledToFill()
                .clipped()
                .frame(width: 45, height: 45)
                .cornerRadius(45)
                .overlay(RoundedRectangle(cornerRadius: 40).stroke(Color.black, lineWidth: 1))
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 3) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(Color.green)
                        .frame(width: 15, height: 15)
                    Text("online")
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                shouldShowLogoutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 25))
                    
            }
        }.padding()
            .actionSheet(isPresented: $shouldShowLogoutOptions) {
                .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [ .destructive(Text("Sign Out"), action: {
                    vm.signOut()
                    
                    
                }), . cancel()
                ])
            }
            .fullScreenCover(isPresented: $vm.isCurrentUserLogOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    vm.isCurrentUserLogOut = false
                    self.vm.fetchChatUser()
                    self.vm.fetchRecentMessenger()
                    //nap lai du lieu array khi login
                })
            }
    }
    
    
    @State var searchText = ""
    @State var isSearching = false
    private var messengerView: some View {
        ScrollView {
            SearchBar(searchText: $searchText, isSearching: $isSearching)
            
            ForEach((vm.recentMessenger).filter({ "\($0)".contains(self.searchText) || searchText.isEmpty
            })) { rmes in
                VStack {
                    Button {
                        let uid = FirebaseMess.shared.auth.currentUser?.uid == rmes.fromId ? rmes.toId : rmes.fromId
                        // check xem la messenger di hay den de lay dc du'ng uid can thiet
                        self.chatUser = .init(data: [FirebaseConstant.email: rmes.email, FirebaseConstant.imageProfileURL: rmes.imageProfileURL, FirebaseConstant.uid: uid])
                        
                        //gan gtri cho chatUser
                        self.chatLogViewModel.chatUser = self.chatUser
                        //truyen data vao chatUser trong ChatLogViewMode
                        self.chatLogViewModel.fetchChatMessenger()
                        // goi lai ham fetch data
                        self.isShowChatLogView.toggle()
                        //chuyen trang thai
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: rmes.imageProfileURL))
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .frame(width: 60, height: 60)
                                .cornerRadius(60)
                                .overlay(RoundedRectangle(cornerRadius: 60).stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 2)
                            VStack(alignment: .leading) {
                                Text(rmes.username)
                                    .foregroundColor(Color(.label))
                                Text(rmes.text)
                                    .foregroundColor(Color(.lightGray))
                            }
                            Spacer()
                            
                            Text (rmes.timeSendMessenger)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }
        }
    }
    
    @State var chatUser: ChatUser?
    private var newMessengerButton: some View {
        Button {
            isAddNewMessenger.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Messenger")
                Spacer()
            }.foregroundColor(.white)
                .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $isAddNewMessenger, onDismiss: nil) {
            NewMessengerView(didSelectNewMessenger: { userdata in
                self.isShowChatLogView.toggle()
                self.chatUser = userdata
                self.chatLogViewModel.chatUser = userdata
                self.chatLogViewModel.fetchChatMessenger()
                // goi lai fetchChatMessenger thi moi thuc hien ham fetch du lieu
            })
        }
    }
}
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var body: some View {
        HStack {
            HStack {
                TextField("Search",text: $searchText)
                    .autocapitalization(.none)
                    .padding(.leading, 26)
                
            }.padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)
                .onTapGesture(perform: {
                    isSearching = true
                })
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Spacer()
                        if isSearching {
                            Button {
                                self.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                    }.padding(.horizontal, 28)
                        .foregroundColor(.gray)
                )
            
            if isSearching {
                Button {
                    isSearching.toggle()
                    self.searchText = ""
                    
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                } label: {
                    Text("Cancel")
                        .padding(.trailing)
                        .padding(.leading, 0)
                }
                .transition(.move(edge: .trailing))
                .animation(.spring())
                
            }
        }
    }
}

struct MainMessengerView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessengerView ()
    }
}


