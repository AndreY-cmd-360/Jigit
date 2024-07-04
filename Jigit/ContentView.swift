import SwiftUI
import Foundation
import Combine

struct ContentView: View {
    @State var validationMessages: [FocusField?: String] = [:]
    @FocusState var focusState: FocusField?
    @StateObject var viewModel = SignUpViewModel()
    @State var button = false
    
    var body: some View{
        NavigationStack{
            formField(title: "Username", text: $viewModel.userName, FocusState: $focusState, focusField: .username, validationMessage: validationMessages[focusState], isValid: viewModel.isValidName, isSecure: false)
            
            formField(title: "Email", text: $viewModel.userEmail, FocusState: $focusState, focusField: .email, validationMessage: validationMessages[focusState], isValid: viewModel.isValidEmail, isSecure: false)
            
            formField(title: "Password", text: $viewModel.userPassword, FocusState: $focusState, focusField: .password, validationMessage: validationMessages[focusState], isValid: viewModel.isValidPass, isSecure: false)
            
            formField(title: "Repeat password", text: $viewModel.userRepeatedPassword, FocusState: $focusState, focusField: .passwordRepeat, validationMessage: validationMessages[focusState], isValid: viewModel.isValidRepeat, isSecure: false)
            
            buttonField
        }
            .onSubmit {
                if focusState == .username {
                        focusState = .email
                        }else if focusState == .email {
                            focusState = .password
                        }else if focusState == .password {
                            focusState = .passwordRepeat
                        }else {
                            focusState = nil
                        }
                                    
                }
            .navigationDestination(isPresented: $button, destination: {
                Text("Successfully sighned in")
            })
            }
    
    private func formField(
        title: String,
        text: Binding<String>,
        FocusState: FocusState<FocusField?>.Binding,
        focusField: FocusField,
        validationMessage: String?,
        isValid: Bool,
        isSecure: Bool
    ) -> some View{
        
        NavigationStack{
            VStack(spacing: 12){
                if isSecure{
                    SecureField(title, text: text)
                        .focused(FocusState, equals: focusField)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onSubmit {
                            if !isValid{
                                validationMessages[focusField] = "Invalid \(title.lowercased())"
                            } else{
                                validationMessages[focusField] = nil
                            }
                        }
                    
                } else{
                    TextField(title, text: text)
                        .focused(FocusState, equals: focusField)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onSubmit {
                            if !isValid{
                                validationMessages[focusField] = "Invalid \(title.lowercased())"
                            } else{
                                validationMessages[focusField] = nil
                            }
                        }
                }
                if let message = validationMessage {
                    let words = message.split { !$0.isLetter && !$0.isNumber }

                    
                    if words.contains(where: { $0.caseInsensitiveCompare(title) == .orderedSame }){
                        Text(message)
                            .foregroundColor(.red)
                            .background(Color.pink.opacity(0.3).frame(height: 60).cornerRadius(6.0))
                            .padding()
                    }
                }
            }
        }
    }
    
    private var buttonField: some View{
        Button("Sign In"){
            button = true
        }
            .padding()
            .foregroundColor(.white)
            .background(viewModel.isFormValid ? Color.blue : Color.gray)
            .cornerRadius(4.0)
            .disabled(!viewModel.isFormValid)
    }
}

enum FocusField {
    case username, email, password, passwordRepeat
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
                let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
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
        Publishers.CombineLatest4(
            isUserNameValidPublisher,
            isUserEmailValidPublisher,
            isPasswordValidPublisher,
            passwordMatchesPublisher
        )
        .map { a, b, c, d in
            return a && b && c && d
        }
        .eraseToAnyPublisher()
    }
}

#Preview {
    ContentView()
}
