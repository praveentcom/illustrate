import Foundation

func getFeedbackLink() -> URL {
    let subject = "Illustrate application feedback"
    let body = "Hey team,\n\nI have some feedback about the application.\n\n[Add your feedback and relevant information that could help]\n\nThanks,\n[Your name]"

    let urlString = "mailto:support@illustrate.so?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

    guard let url = URL(string: urlString) else {
        print("Failed to create URL from string")
        return URL(string: "https://support.illustrate.so")!
    }

    return url
}
