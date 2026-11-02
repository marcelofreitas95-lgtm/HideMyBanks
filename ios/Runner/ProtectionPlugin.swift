import DeviceActivity
import FamilyControls
import Flutter
import Foundation
import ManagedSettings
import SwiftUI
import UIKit

final class ProtectionPlugin: NSObject, FlutterPlugin {
  private let vault = CodeVault()
  private var sessionExpiry: Date?
  private var sessionGeneration = 0
  private var presenting = false
  private var pickerController: UIViewController?
  private var pickerResult: FlutterResult?
  private var channel: FlutterMethodChannel?
  private var snapshotCover: UIView?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = ProtectionPlugin()
    let channel = FlutterMethodChannel(name: "app.calculadora/protection", binaryMessenger: registrar.messenger())
    plugin.channel = channel
    registrar.addMethodCallDelegate(plugin, channel: channel)
    NotificationCenter.default.addObserver(plugin, selector: #selector(plugin.background),
      name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(plugin, selector: #selector(plugin.inactive),
      name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(plugin, selector: #selector(plugin.active),
      name: UIApplication.didBecomeActiveNotification, object: nil)
  }

  private var authorized: Bool { AuthorizationCenter.shared.authorizationStatus == .approved }
  private func requireSession() throws {
    guard let expiry = sessionExpiry, expiry > Date() else { throw ProtectionFailure.sessionRequired }
    sessionExpiry = Date().addingTimeInterval(120)
  }
  private func closeSession() {
    sessionGeneration += 1
    sessionExpiry = nil
  }
  private func status() throws -> [String: Any] {
    let policy = try PolicyRepository().reconcile()
    let applied = ManagedSettingsStore(named: PolicyRepository.storeName)
      .application.blockedApplications?.count ?? 0
    return ["hasCode": try vault.isConfigured, "authorized": authorized,
      "selectedCount": policy.count, "appliedCount": authorized ? min(applied, policy.count) : 0,
      "mode": !authorized ? "unavailable" : policy.count == 0 ? "unconfigured" : policy.shouldBlock ? "blocked" : "released",
      "releaseUntil": policy.releaseUntil.map { $0.timeIntervalSince1970 as Any } ?? NSNull()]
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "status": result(try status())
      case "setupCode":
        guard let code = args["code"] as? String else { throw ProtectionFailure.invalidCode }
        try vault.configure(code)
        result(try status())
      case "openSession":
        guard let code = args["code"] as? String, CodeVault.valid(code) else {
          result(false); return
        }
        let accepted = try vault.verify(code)
        sessionExpiry = accepted ? Date().addingTimeInterval(120) : nil
        result(accepted)
      case "closeSession": closeSession(); result(nil)
      case "changeCode":
        try requireSession()
        guard let current = args["current"] as? String, let next = args["next"] as? String else {
          throw ProtectionFailure.invalidCode
        }
        try vault.change(current: current, next: next)
        result(nil)
      case "authorize":
        try requireSession()
        guard !presenting else { throw ProtectionFailure.unavailable }
        presenting = true
        let generation = sessionGeneration
        Task { @MainActor in
          do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            guard generation == self.sessionGeneration else { throw ProtectionFailure.sessionRequired }
            result(try self.status())
          } catch { result(self.flutterError(error)) }
          self.presenting = false
        }
      case "selectApps":
        try requireSession()
        guard authorized else { throw ProtectionFailure.authorizationRequired }
        try showPicker(result: result)
      case "protect":
        try requireSession()
        guard authorized else { throw ProtectionFailure.authorizationRequired }
        _ = try PolicyRepository().update { policy in
          policy.releaseUntil = nil
          PolicyRepository.apply(policy)
        }
        DeviceActivityCenter().stopMonitoring([PolicyRepository.activityName])
        result(try status())
      case "release":
        try requireSession()
        guard authorized else { throw ProtectionFailure.authorizationRequired }
        try release()
        result(try status())
      default: result(FlutterMethodNotImplemented)
      }
    } catch { result(flutterError(error)) }
  }

  private func release() throws {
    let repository = try PolicyRepository()
    let now = Date()
    let end = now.addingTimeInterval(15 * 60 + 2)
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let schedule = DeviceActivitySchedule(
      intervalStart: Calendar.current.dateComponents(components, from: now),
      intervalEnd: Calendar.current.dateComponents(components, from: end), repeats: false)
    do {
      try repository.update { policy in
        guard policy.count > 0 && policy.count <= 50 else { throw ProtectionFailure.invalidSelection }
        // Persist the deadline while coordinated; schedule must succeed before clearing settings.
        try DeviceActivityCenter().startMonitoring(PolicyRepository.activityName, during: schedule)
        policy.releaseUntil = end
        PolicyRepository.apply(policy)
      }
    } catch {
      // If scheduling or persistence fails, restore blocking before returning any error.
      _ = try? repository.update { policy in
        policy.releaseUntil = nil
        PolicyRepository.apply(policy)
      }
      throw ProtectionFailure.monitorFailed
    }
  }

  private func rootController() -> UIViewController? {
    UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
  }
  private func showPicker(result: @escaping FlutterResult) throws {
    guard !presenting, let root = rootController(), root.presentedViewController == nil else {
      throw ProtectionFailure.unavailable
    }
    let selection = try PolicyRepository().read().selection
    let screen = AppSelectionView(selection: selection) { [weak self] value in
      self?.completePicker(value)
    }
    let controller = UIHostingController(rootView: screen)
    controller.isModalInPresentation = true
    pickerController = controller
    pickerResult = result
    presenting = true
    root.present(controller, animated: true)
  }
  private func completePicker(_ selection: FamilyActivitySelection?) {
    guard let result = pickerResult else { return }
    pickerResult = nil
    do {
      if let selection = selection {
        try requireSession()
        guard authorized else { throw ProtectionFailure.authorizationRequired }
        guard (1...50).contains(selection.applicationTokens.count),
              selection.categoryTokens.isEmpty, selection.webDomainTokens.isEmpty else {
          throw ProtectionFailure.invalidSelection
        }
        try PolicyRepository().update { policy in
          policy.selection = selection
          policy.releaseUntil = nil
          PolicyRepository.apply(policy)
        }
        DeviceActivityCenter().stopMonitoring([PolicyRepository.activityName])
      }
      result(try status())
    } catch { result(flutterError(error)) }
    pickerController?.dismiss(animated: true)
    pickerController = nil
    presenting = false
  }

  private func flutterError(_ error: Error) -> FlutterError {
    let code: String
    switch error {
    case ProtectionFailure.invalidCode: code = "invalid_code"
    case ProtectionFailure.rateLimited: code = "rate_limited"
    case ProtectionFailure.authorizationRequired: code = "authorization_required"
    case ProtectionFailure.sessionRequired: code = "session_required"
    case ProtectionFailure.invalidSelection: code = "selection_invalid"
    case ProtectionFailure.monitorFailed: code = "monitor_failed"
    default: code = "native_failed"
    }
    // Never forward raw errors, PINs, application names or tokens to Dart or logs.
    return FlutterError(code: code, message: "A operação não foi concluída.", details: nil)
  }

  @objc private func background() {
    closeSession()
    if pickerResult != nil {
      pickerResult?(flutterError(ProtectionFailure.sessionRequired))
      pickerResult = nil
      pickerController?.dismiss(animated: false)
      pickerController = nil
      presenting = false
    }
  }
  @objc private func inactive() {
    if !presenting { closeSession() }
    guard snapshotCover == nil, let root = rootController(), let window = root.view.window else { return }
    let cover = UIView(frame: window.bounds)
    cover.backgroundColor = UIColor(red: 23/255, green: 24/255, blue: 23/255, alpha: 1)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    let label = UILabel(frame: cover.bounds)
    label.text = "Calculadora"
    label.textColor = .lightGray
    label.textAlignment = .center
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.addSubview(label)
    window.addSubview(cover)
    snapshotCover = cover
  }
  @objc private func active() {
    snapshotCover?.removeFromSuperview()
    snapshotCover = nil
    _ = try? PolicyRepository().reconcile()
  }
}

private struct AppSelectionView: View {
  @State var selection: FamilyActivitySelection
  var complete: (FamilyActivitySelection?) -> Void
  var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        Text("Selecione de 1 a 50 aplicativos de banco. Não selecione a Calculadora, categorias ou sites.")
          .font(.footnote).padding()
        FamilyActivityPicker(selection: $selection)
      }
      .navigationTitle("Aplicativos")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { complete(nil) } }
        ToolbarItem(placement: .confirmationAction) { Button("Salvar") { complete(selection) } }
      }
    }
  }
}
