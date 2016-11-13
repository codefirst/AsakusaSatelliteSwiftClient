import SafariServices
import UIKit

public class Auth: NSObject, SFSafariViewControllerDelegate {
    public var completion: ((String?) -> Void)? // apiKey if signed in
    public private(set) var signinVC: SFSafariViewController?

    public func presentSignInViewController(on onVC: UIViewController, rootURL: URL, callbackScheme: String) {
        guard let authURL = URL(string: "/auth/twitter?callback_scheme=\(callbackScheme)", relativeTo: rootURL) else { return }
        let vc = SFSafariViewController(url: authURL)
        vc.delegate = self
        vc.modalPresentationStyle = .formSheet
        onVC.present(vc, animated: true, completion: nil)
        self.signinVC = vc
    }

    public func open(url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false)
        if let apiKey = components?.queryItems?.filter({$0.name == "api_key"}).first?.value {
            // signed in
            completion?(apiKey)
        } else {
            // not signed in
            completion?(nil)
        }

        signinVC?.dismiss(animated: true, completion: nil)
        return true
    }

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        signinVC = nil
    }
}
