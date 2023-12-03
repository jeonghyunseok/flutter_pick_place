import UIKit
import Social
import MobileCoreServices
import CoreLocation
import SwiftSoup

class ShareViewController: SLComposeServiceViewController {

    var sharedImage: UIImage?
    var sharedText: String?
    var sharedURL: URL?
    var sharedLocation: CLLocation?
    var sharedMetaTag: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let content = extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in content.attachments! {
                let itemProvider = attachment

                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    // Image
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil, completionHandler: { (img, error) in
                        if let img = img as? UIImage {
                            self.sharedImage = img
                        }
                    })
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                    // Text
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil, completionHandler: { (text, error) in
                        if let text = text as? String {
                            self.sharedText = text
                        }
                    })
                } else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    // URL
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil, completionHandler: { (url, error) in
                        if let url = url as? URL {
                            self.sharedURL = url
                            print("swiftSoup")
                            // Download and parse HTML to get meta tags
                            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                                if let data = data, let html = String(data: data, encoding: .utf8) {
                                    do {
                                        let doc = try SwiftSoup.parse(html)
                                        if let metaTag = try doc.select("meta[name=description]").first() {
                                            self.sharedMetaTag = try metaTag.attr("content")
                                        }
                                    } catch {
                                        print("Failed to parse HTML: \(error)")
                                    }
                                }
                            }
                            task.resume()
                        }
                    })
                }

            }
        }
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        debugPrint("didSelectPost")

        self.extensionContext!.completeRequest(returningItems: [], completionHandler: { _ in
            // Open your app here
            var components = URLComponents(string: "ShareMedia://")

            var queryItems = [URLQueryItem]()
            if let sharedText = self.sharedText {
                queryItems.append(URLQueryItem(name: "text", value: sharedText))
            }
            if let sharedURL = self.sharedURL {
                queryItems.append(URLQueryItem(name: "url", value: sharedURL.absoluteString))
            }
            if let sharedMetaTag = self.sharedMetaTag {
                queryItems.append(URLQueryItem(name: "metatag", value: sharedMetaTag))
            }

            components?.queryItems = queryItems

            print("ShareMedia: Pars: \(components?.string ?? "")")

            if let url = components?.url {
                let selectorOpenURL = sel_registerName("openURL:")
                var responder: UIResponder? = self
                while responder != nil {
                    if responder!.responds(to: selectorOpenURL) {
                        responder!.perform(selectorOpenURL, with: url)
                        break
                    }
                    responder = responder!.next
                }
            }
        })

    }


}
