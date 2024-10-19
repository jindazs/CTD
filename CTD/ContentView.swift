import SwiftUI
import WebKit

class WebViewModel: ObservableObject {
    @Published var webView: CustomWebView?
    private var initialURL: URL?
    
    init(url: URL) {
        self.webView = CustomWebView()
        self.initialURL = url
        loadInitialPage()
    }
    
    private func loadInitialPage() {
        if let initialURL = initialURL {
            let request = URLRequest(url: initialURL)
            webView?.load(request)
        }
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func resetToInitialPage() {
        loadInitialPage() // 初期ページを再度読み込む
    }
    
    func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        webView?.load(request)
    }
}

struct ContentView: View {
    @State private var projectName: String = UserDefaults.standard.string(forKey: "ProjectName") ?? ""
    @State private var showSettings: Bool = false
    @State private var selectedTab = 1 // 初期タブをメインに設定
    @State private var currentDate = "" // 日付を保持するState
    
    @StateObject private var mainWebViewModel = WebViewModel(url: URL(string: "https://scrapbox.io/\(UserDefaults.standard.string(forKey: "ProjectName") ?? "")")!)
    @StateObject private var todoWebViewModel = WebViewModel(url: URL(string: "https://scrapbox.io/\(UserDefaults.standard.string(forKey: "ProjectName") ?? "")/ToDo")!)
    @StateObject private var dateWebViewModel = WebViewModel(url: URL(string: "https://scrapbox.io/\(UserDefaults.standard.string(forKey: "ProjectName") ?? "")")!) // 後で日付を設定
    
    var body: some View {
        ZStack {
            // 各WebViewを事前に生成してキャッシュする
            if selectedTab == 0 {
                WebViewWrapper(webViewModel: todoWebViewModel)
                    .ignoresSafeArea(edges: .all)
            } else if selectedTab == 1 {
                WebViewWrapper(webViewModel: mainWebViewModel)
                    .ignoresSafeArea(edges: .all)
            } else if selectedTab == 2 {
                WebViewWrapper(webViewModel: dateWebViewModel)
                    .ignoresSafeArea(edges: .all)
            }
            
            VStack {
                Spacer()

                // アイコンを含むボトムバー
                HStack {
                    Button(action: {
                        selectedTab = 0
                    }) {
                        Image(systemName: "list.bullet")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .padding()
                            .background(Circle().fill(selectedTab == 0 ? Color.gray.opacity(0.2) : Color.clear))
                    }
                    .onTapGesture(count: 2) {
                        todoWebViewModel.resetToInitialPage() // ダブルタップで初期ページにリセット
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTab = 1
                    }) {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .padding()
                            .background(Circle().fill(selectedTab == 1 ? Color.gray.opacity(0.2) : Color.clear))
                    }
                    .onTapGesture(count: 2) {
                        mainWebViewModel.resetToInitialPage() // ダブルタップで初期ページにリセット
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTab = 2
                    }) {
                        Image(systemName: "calendar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .padding()
                            .background(Circle().fill(selectedTab == 2 ? Color.gray.opacity(0.2) : Color.clear))
                    }
                    .onTapGesture(count: 2) {
                        // onAppearで実行した処理を再実行する
                        let dateUrl = URL(string: "https://scrapbox.io/\(projectName)/\(currentDate)")!
                        dateWebViewModel.loadURL(dateUrl) // 日付に基づくURLを再度ロード
                    }
                }
                .padding([.leading, .trailing], 40)
                .padding(.bottom, 0)
                .background(Color.white)
            }
        }
        .onAppear {
            projectName = UserDefaults.standard.string(forKey: "ProjectName") ?? ""
            currentDate = getCurrentDate() // アプリ起動時に現在の日付を取得
            let dateUrl = URL(string: "https://scrapbox.io/\(projectName)/\(currentDate)")!
            dateWebViewModel.loadURL(dateUrl) // 日付URLをロード
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(projectName: $projectName)
        }
    }
    
    func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }
}

class CustomWebView: WKWebView {
    override var inputAccessoryView: UIView? {
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))
        accessoryView.backgroundColor = UIColor.systemGray5
        
        let buttonStack = UIStackView(frame: accessoryView.bounds)
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        
        let dateButton = UIButton(type: .system)
        dateButton.setTitle("Today", for: .normal)
        dateButton.addTarget(self, action: #selector(insertDate), for: .touchUpInside)
        
        let dismissButton = UIButton(type: .system)
        dismissButton.setTitle("Done", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(dateButton)
        buttonStack.addArrangedSubview(dismissButton)
        
        accessoryView.addSubview(buttonStack)
        
        return accessoryView
    }
    
    @objc func insertDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M月d日"
        let dateString = "#\(dateFormatter.string(from: Date()))"
        
        let script = "document.execCommand('insertText', false, '\(dateString)');"
        self.evaluateJavaScript(script, completionHandler: nil)
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
    }
}

struct WebViewWrapper: UIViewRepresentable {
    @ObservedObject var webViewModel: WebViewModel
    
    func makeUIView(context: Context) -> CustomWebView {
        return webViewModel.webView ?? CustomWebView()
    }
    
    func updateUIView(_ webView: CustomWebView, context: Context) {
        // キャッシュされたWebViewをそのまま使用するので、ここでは何もしません
    }
}

struct SettingsView: View {
    @Binding var projectName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("プロジェクト名")) {
                    TextField("プロジェクト名", text: $projectName)
                }
            }
            .navigationBarItems(trailing: Button("保存") {
                UserDefaults.standard.set(projectName, forKey: "ProjectName")
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// プレビュー用のコードを追加
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
