import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    enum FocusField{
        case username, email, password, passwordRepeat
    }
    
    @FocusState private var focusField: FocusField?
    
    @StateObject var viewModel = SignUpViewModel()
    
    @State var button = false
    
    @State private var showInvalidUsernameMessage = false
    @State private var showInvalidEmailMessage = false
    @State private var showInvalidPasswordMessage = false
    @State private var showInvalidRepeatMessage = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                nameField
                
                emailField
                
                passwordField
                
                repeatPasswordField
                
                buttonField
            }.navigationDestination(isPresented: $button){
                Text("Successfully logged in")
            }
            .onSubmit {
                if focusField == .username {
                    focusField = .email
                }else if focusField == .email {
                    focusField = .password
                }else if focusField == .password {
                    focusField = .passwordRepeat
                }else {
                    focusField = nil
                }
                    
            }
            .padding()
        }
    }
    
    private var nameField: some View {
        VStack{
            TextField("Username", text: $viewModel.userName)
                .focused($focusField, equals: .username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    if !viewModel.isValidName {
                        showInvalidUsernameMessage = true
                    } else {
                        showInvalidUsernameMessage = false
                    }
                }

                if showInvalidUsernameMessage{
                    Text("Invalid username")
                        .foregroundColor(.red)
                        .background(Color.pink.opacity(0.3).frame(width: 300, height: 60).cornerRadius(6.0))
                        .padding()
            }
        }
    }
    
    private var emailField: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $viewModel.userEmail)
                .focused($focusField, equals: .email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit() {
                    if !viewModel.isValidEmail{
                        showInvalidEmailMessage = true
                    } else{
                        showInvalidEmailMessage = false
                    }
                }
            if showInvalidEmailMessage{
                Text("Invalid email")
                    .foregroundColor(.red)
                    .background(Color.pink.opacity(0.3).frame(width: 300, height: 60).cornerRadius(6.0))
                    .padding()
            }
        }
    }

    private var passwordField: some View {
        VStack(spacing: 12) {
            SecureField("Password", text: $viewModel.userPassword)
                .focused($focusField, equals: .password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    if !viewModel.isValidPass{
                        showInvalidPasswordMessage = true
                    } else{
                        showInvalidPasswordMessage = false
                    }
                }
            if showInvalidPasswordMessage{
                Text("The password must contain a combination of uppercase and lowercase letter, number and a special character")
                    .foregroundColor(.red)
                    .background(Color.pink.opacity(0.3).frame(width: 360, height: 80).cornerRadius(6.0))
                    .padding()
            }
        }
    }
    
    private var repeatPasswordField: some View {
        VStack(spacing: 12) {
            SecureField("Repeat password", text: $viewModel.userRepeatedPassword)
                .focused($focusField, equals: .passwordRepeat)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit() {
                    if !viewModel.isValidRepeat{
                        showInvalidRepeatMessage = true
                    } else{
                        showInvalidRepeatMessage = false
                    }
                }
                .on
            if  showInvalidEmailMessage{
                Text("Passwords don't match")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private var buttonField: some View {
            Button("Sign In") {
                button = true
            }
            .padding()
            .foregroundColor(.white)
            .background(viewModel.isFormValid ? Color.blue : Color.gray)
            .cornerRadius(4.0)
            .disabled(!viewModel.isFormValid)
    }
}

final class SignUpViewModel: ObservableObject {
    @Published var userName = ""
    @Published var userEmail = ""
    @Published var userPassword = ""
    @Published var userRepeatedPassword = ""
    
    @Published var isValidName = false
    @Published var isValidEmail = false
    @Published var isValidPass = false
    @Published var isValidRepeat = false
    
    @Published var isFormValid = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        isSignUpFormValid
            .receive(on: RunLoop.main)
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
        isUserNameValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValidName, on: self)
            .store(in: &cancellables)
        isUserEmailValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValidEmail, on: self)
            .store(in: &cancellables)
        isPasswordValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValidPass, on: self)
            .store(in: &cancellables)
        passwordMatchesPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.isValidRepeat, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - Setup validations
private extension SignUpViewModel {
    
  var isUserNameValidPublisher: AnyPublisher<Bool, Never> {
    $userName
      .map { name in
          return name.count >= 5
      }
      .eraseToAnyPublisher()
  }
  
  var isUserEmailValidPublisher: AnyPublisher<Bool, Never> {
    $userEmail
      .map { email in
          let emailPredicate = NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
          return emailPredicate.evaluate(with: email)
      }
      .eraseToAnyPublisher()
  }
  
  var isPasswordValidPublisher: AnyPublisher<Bool, Never> {
    $userPassword
      .map { password in
          let regex = try! NSRegularExpression(pattern: "^(?=.*[A-Z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$", options: [])
          return regex.firstMatch(in: password, options: [], range: NSRange(location: 0, length: password.utf16.count)) != nil
      }
      .eraseToAnyPublisher()
  }
  
  var passwordMatchesPublisher: AnyPublisher<Bool, Never> {
    Publishers.CombineLatest($userPassword, $userRepeatedPassword)
      .map { password, repeated in
          return password == repeated
      }
      .eraseToAnyPublisher()
  }
  
    var isSignUpFormValid: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest4(isUserNameValidPublisher, isUserEmailValidPublisher, isPasswordValidPublisher, passwordMatchesPublisher)
            .map { a, b, c, d in
                return a && b && c && d
            }
            .eraseToAnyPublisher()
    }
}

#Preview {
//    SignUpView(viewModel: SignUpViewModel())
    ContentView()
}
