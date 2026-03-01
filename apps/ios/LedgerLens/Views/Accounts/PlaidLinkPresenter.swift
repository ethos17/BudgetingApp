import SwiftUI
import LinkKit

/// Presents Plaid Link using the given link token. Callbacks run on main actor.
struct PlaidLinkPresenter: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: (String?) -> Void

    func makeUIViewController(context: Context) -> PlaidLinkHostController {
        PlaidLinkHostController(
            linkToken: linkToken,
            onSuccess: onSuccess,
            onExit: onExit
        )
    }

    func updateUIViewController(_ uiViewController: PlaidLinkHostController, context: Context) {}
}

final class PlaidLinkHostController: UIViewController {
    private let linkToken: String
    private let onSuccess: (String) -> Void
    private let onExit: (String?) -> Void
    private var handler: Handler?

    init(linkToken: String, onSuccess: @escaping (String) -> Void, onExit: @escaping (String?) -> Void) {
        self.linkToken = linkToken
        self.onSuccess = onSuccess
        self.onExit = onExit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard handler == nil else { return }

        // LinkTokenConfiguration initializer takes only token + onSuccess (SDK 6.x).
        // onExit is set as a property after creation.
        var linkConfiguration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { [weak self] (linkSuccess: LinkSuccess) in
                Task { @MainActor in
                    self?.onSuccess(linkSuccess.publicToken)
                }
            }
        )
        linkConfiguration.onExit = { [weak self] (linkExit: LinkExit) in
            Task { @MainActor in
                let message = linkExit.error?.displayMessage ?? linkExit.error?.errorMessage
                self?.onExit(message)
            }
        }

        // Plaid.create(configuration) — first argument is unlabeled, no "configuration:" label.
        // Optional onLoad is omitted.
        let result = Plaid.create(linkConfiguration)
        switch result {
        case .failure(let error):
            onExit(error.localizedDescription)
        case .success(let linkHandler):
            handler = linkHandler
            let method: PresentationMethod = .viewController(self)
            linkHandler.open(presentUsing: method)
        }
    }
}
