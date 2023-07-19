//
//  InputView.swift
//  MakeImage
//
//  Created by cmStudent on 2023/07/03.
//

import SwiftUI
import Combine

struct OpenAIGenerateImageRequest: Encodable {
    var prompt: String
    var n: Int = 1
    var size: String = "1024x1024"
    var responseFormat: String = "b64_json"
    
    enum CodingKeys: String, CodingKey {
        case responseFormat = "response_format"
        case prompt, n, size
    }
}

struct OpenAIGenerateImageResponse: Decodable {
    let created: Int
    let data: [Datum]
    
    struct Datum: Codable {
        let url: String?
        let b64JSON: String?
        
        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
            case url
        }
    }
}

/// OpenAI APIにリクエストを行う際のエラー
enum OpenAIRequestError: Error {
    /// リクエスト実行時のレスポンスエラー
    case responseError(URLError.Code)
    /// URLが解析出来ない際のエラー
    case urlError
    /// APIKey等の設定が取得できない際のエラー
    case configurationError
    /// エンコードエラー
    case encodeError
}

struct URLRequestService {
    
    func generate(prompt: String) -> AnyPublisher<OpenAIGenerateImageResponse, Error> {
        
        guard let apikey = EnvironmentManager.shared.value(forKey: "APIKey") as? String,
              let urlString = EnvironmentManager.shared.value(forKey: "URL") as? String,
              let endpoint = EnvironmentManager.shared.value(forKey: "GenerateImageEndpoint") as? String
        else {
            return Fail(error: OpenAIRequestError.configurationError)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: urlString + endpoint) else {
            return Fail(error: OpenAIRequestError.urlError)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(apikey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        
        let requestParameter = OpenAIGenerateImageRequest(prompt: prompt)
        guard let requestJSON = try? JSONEncoder().encode(requestParameter) else {
            return Fail(error: OpenAIRequestError.encodeError)
                .eraseToAnyPublisher()
        }
        
        request.httpBody = requestJSON
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<400 ~= httpResponse.statusCode else {
                    throw OpenAIRequestError.responseError(.badServerResponse)
                }
                return data
            }
            .decode(type: OpenAIGenerateImageResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

class GenerateImageViewModel: ObservableObject {

    @Published var imageB64: (Data, Data) = (Data(), Data())
    @Published var canRun = true
    @Published var errorMessage = ""
    
    private let urlRequestService = URLRequestService()
    
    private var cancellables = Set<AnyCancellable>()
    
    func generate(_ prompt1: String, _ prompt2: String) {
        canRun = false
        var canRunTemp1 = false
        var canRunTemp2 = false
        urlRequestService.generate(prompt: prompt1)
            .sink { completion in
                switch completion {
                case .finished:
                    canRunTemp1 = true
                    if canRunTemp1, canRunTemp2 {
                        self.canRun = true
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print(error.localizedDescription)
                    canRunTemp1 = true
                    if canRunTemp1, canRunTemp2 {
                        self.canRun = true
                    }
                }
            } receiveValue: { openAIImage in
                print(openAIImage.created)
                guard let json = openAIImage.data.first?.b64JSON,
                      let data = Data(base64Encoded: json) else {
                          return
                      }
                self.imageB64.0 = data
                
            }
            .store(in: &cancellables)
        urlRequestService.generate(prompt: prompt2)
            .sink { completion in
                switch completion {
                case .finished:
                    canRunTemp2 = true
                    if canRunTemp1, canRunTemp2 {
                        self.canRun = true
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print(error.localizedDescription)
                    canRunTemp2 = true
                    if canRunTemp1, canRunTemp2 {
                        self.canRun = true
                    }
                }
            } receiveValue: { openAIImage in
                print(openAIImage.created)
                guard let json = openAIImage.data.first?.b64JSON,
                      let data = Data(base64Encoded: json) else {
                          return
                      }
                self.imageB64.1 = data
                
            }
            .store(in: &cancellables)
        
    }
    
}

// View
struct InputView: View {
    @StateObject var viewModel = GenerateImageViewModel()

    // 生成画像のプロンプトになる要素
    var inputText: [String] =
        ["food", "ramen", "beaf", "curry","cycling","ship","boat","sushi","cycling","ship","boat","car","baseball pitcher","dunk shoot","spike","soccer","cascade","tower","street","temple","cat","rabbit","bird","dog"]
    
    var inputText2: [String] =
        ["food", "ramen", "beaf", "curry","cycling","ship","boat","sushi","cycling","ship","boat","car","baseball pitcher","dunk shoot","spike","soccer","cascade","tower","street","temple","cat","rabbit","bird","dog"]
    
        var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Group {
                Image(uiImage: UIImage(data: viewModel.imageB64.0) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                Text("+")
                    .font(.title)
                
                Image(uiImage: UIImage(data: viewModel.imageB64.1) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            Button{
                //1ボタンで　データを２個出力して２枚の画像を出す
                viewModel.generate(inputText.randomElement()!, inputText2.randomElement()!)
                
            } label: {
                
                Text("生成")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.pink)
                    .padding()
            }
            .disabled(!viewModel.canRun)
            .opacity(viewModel.canRun ? 1 : 0.3)
        }
    }
}

struct InputView_Previews: PreviewProvider {
    static var previews: some View {
        InputView()
    }
}
