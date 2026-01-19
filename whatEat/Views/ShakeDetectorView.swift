import SwiftUI
import UIKit

struct ShakeDetectorView: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorViewController {
        ShakeDetectorViewController(onShake: onShake)
    }

    func updateUIViewController(_ uiViewController: ShakeDetectorViewController, context: Context) {
        uiViewController.onShake = onShake
    }
}

extension Notification.Name {
    static let shakeDetectorRestore = Notification.Name("shakeDetectorRestore")
}

final class ShakeDetectorViewController: UIViewController {
    var onShake: () -> Void
    private var observers: [NSObjectProtocol] = []

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restoreFirstResponder()
        })
        observers.append(center.addObserver(
            forName: .shakeDetectorRestore,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restoreFirstResponder()
        })
        observers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restoreFirstResponder()
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }

    deinit {
        let center = NotificationCenter.default
        observers.forEach { center.removeObserver($0) }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake()
    }

    private func restoreFirstResponder() {
        guard isViewLoaded, view.window != nil else { return }
        becomeFirstResponder()
    }
}
