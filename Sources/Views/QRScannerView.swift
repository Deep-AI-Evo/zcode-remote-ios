import SwiftUI
import VisionKit

/// 二维码扫描（DataScannerViewController，iOS 16+，需要相机权限）。
struct QRScannerView: UIViewControllerRepresentable {
    var onCode: (String?) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let vc = ScannerViewController()
        vc.onCode = onCode
        return vc
    }

    func updateUIViewController(_ vc: ScannerViewController, context: Context) {}

    final class ScannerViewController: UIViewController, DataScannerViewControllerDelegate {
        var onCode: ((String?) -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black

            guard DataScannerViewController.isSupported else {
                label("此设备不支持扫码")
                return
            }
            guard AVCaptureHelper.cameraAuthorized() else {
                AVCaptureHelper.requestCamera { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted { self?.startScanner() }
                        else { self?.label("未授权相机，请在系统设置中允许访问") }
                    }
                }
                return
            }
            startScanner()
        }

        private func startScanner() {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode()],
                qualityMode: .balanced,
                isHighlightingRecognizedItems: true
            )
            scanner.delegate = self
            addChild(scanner)
            scanner.view.frame = view.bounds
            scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(scanner.view)
            scanner.didMove(toParent: self)

            let hint = UILabel()
            hint.text = "对准电脑屏幕上 ZCode 的二维码"
            hint.textColor = .white
            hint.textAlignment = .center
            hint.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hint)
            NSLayoutConstraint.activate([
                hint.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
                hint.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])

            try? scanner.startScanning()
        }

        private func label(_ text: String) {
            let l = UILabel()
            l.text = text
            l.textColor = .white
            l.numberOfLines = 0
            l.textAlignment = .center
            l.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(l)
            NSLayoutConstraint.activate([
                l.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                l.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                l.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
            ])
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }
            if case .barcode(let code) = item, let payload = code.payloadStringValue {
                onCode?(payload)
            }
        }
    }
}

import AVFoundation

enum AVCaptureHelper {
    static func cameraAuthorized() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    static func requestCamera(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
    }
}
