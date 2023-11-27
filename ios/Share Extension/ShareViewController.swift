import UIKit
import Social
import MobileCoreServices
import CoreLocation

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
                            // MetaTag
                            // Here you can use a library like SwiftSoup to parse the HTML and get the meta tags.
                        }
                    })
                }
            }
        }
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        debugPrint("didSelectPost")

        // Inform the host that we're done, so it un-blocks its UI.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: { _ in
            // Open your app here
            var urlString = "ShareMedia://"
            if let sharedText = self.sharedText {
                urlString += "?text=" + sharedText
            }
            if let sharedURL = self.sharedURL {
                urlString += "&url=" + sharedURL.absoluteString
            }
            if let sharedMetaTag = self.sharedMetaTag {
                urlString += "&metatag=" + sharedMetaTag
            }
            if let url = URL(string: urlString) {
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
