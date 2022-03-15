//
//  ContentView.swift
//  ChatMessenger
//
//  Created by SonGoku on 08/03/2022.
//

import SwiftUI
import Firebase


struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessenger = ""
    
    @State private var isShowImage = false
    @State private var image: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack {
                    
                    Picker(selection: $isLoginMode, label: Text("ok")) {
                        Text("Login").tag(true)
                        Text("Create User").tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            isShowImage.toggle()
                        } label: {
                            VStack {
                                if let image = image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color(.label))
                                        .padding()
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 2))
                        }
                    }
                    
                    Group {
                        TextField("Email",text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password",text: $password)
                    }.padding(12)
                        .background(Color.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Login" : "Create User")
                                .foregroundColor(.white)
                                .padding(10)
                                .font(.system(size: 18,weight: .semibold))
                                
                            Spacer()
                        }.background(Color.blue)
                    }
                    
                    Text(errorMessenger)
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Login" : "Create User")
            .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
            .fullScreenCover(isPresented: $isShowImage, onDismiss: nil) {
                ImagePicker(image: $image)
            }
        }
    }
    
    private func handleAction() {
        if isLoginMode {
            loginFunc()
        } else {
            if image == nil {
                self.errorMessenger = "You must select your avatar!"
            } else {
                
                createUserFunc()
            }
        }
    }
    
    private func loginFunc() {
        
        FirebaseMess.shared.auth.signIn(withEmail: email, password: password) { result , err in
            if let err = err {
                self.errorMessenger = "Failed to login: \(err)"
                return
            }
            self.errorMessenger = "Succesfully to login with uid: \(result?.user.uid ?? "")"
            self.didCompleteLoginProcess()
        }
        
    }
    
    private func createUserFunc() {
        
        FirebaseMess.shared.auth.createUser(withEmail: email, password: password) { result , err in
            if let err = err {
                self.errorMessenger = "Failed to create user: \(err)"
                return
            }
            
            self.errorMessenger = "Succesfully to create user with uid: \(result?.user.uid ?? "")"
            self.password = ""
            persitImageToStorage()
        }
        
    }
    
    private func persitImageToStorage() {
        guard let uid = FirebaseMess.shared.auth.currentUser?.uid else {return}
        guard let imagedata = self.image?.jpegData(compressionQuality: 0.5) else {return}
        
        let ref = FirebaseMess.shared.storage.reference(withPath: uid)
        
        ref.putData(imagedata, metadata: nil) { metadata , err in
            if let err = err {
                self.errorMessenger = "Failed to upload image: \(err)"
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    self.errorMessenger = "Failed to download URLImage: \(err)"
                    return
                }
                self.errorMessenger = "Your URLImage: \(url?.absoluteString ?? "")"
                print(errorMessenger)
                guard let url = url else {return}
                storageUserInformation(imageProfileURL: url)
            }
        }
    }
    
    private func storageUserInformation(imageProfileURL: URL) {
        guard let uid = FirebaseMess.shared.auth.currentUser?.uid else {return}
        

        let data = ["uid": uid,"email":email,"imageProfileURL": imageProfileURL.absoluteString] as [String : Any]

        FirebaseMess.shared.firestore.collection("user")
            .document(uid)
            .setData(data) { err in
                if let err = err {
                    self.errorMessenger = "failed to storage user information: \(err)"
                    print(errorMessenger)
                    return
                }
                self.didCompleteLoginProcess()
                print("Storage Success")
            }
        
    }
    
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessengerView()
    }
}
