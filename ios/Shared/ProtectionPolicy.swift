import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

enum ProtectionFailure: Error {
  case unavailable, invalidSelection, authorizationRequired, sessionRequired
  case invalidCode, rateLimited, alreadyConfigured, monitorFailed, storageFailed
}

struct ProtectionPolicy: Codable {
  var selection = FamilyActivitySelection()
  var releaseUntil: Date?

  var shouldBlock: Bool { releaseUntil == nil || releaseUntil! <= Date() }
  var count: Int { selection.applicationTokens.count }
}

/// Shared between the app and monitor. File coordination serializes both processes.
final class PolicyRepository {
  static let storeName = ManagedSettingsStore.Name("calculadora")
  static let activityName = DeviceActivityName("calculadora.temporary-access")
  private let url: URL

  init() throws {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "CalculatorAppGroup") as? String,
          let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: group) else {
      throw ProtectionFailure.storageFailed
    }
    url = container.appendingPathComponent("protection-policy.json")
  }

  func update<T>(_ body: @escaping (inout ProtectionPolicy) throws -> T) throws -> T {
    var coordinationError: NSError?
    var outcome: Result<T, Error>?
    let coordinator = NSFileCoordinator(filePresenter: nil)
    coordinator.coordinate(writingItemAt: url, options: .forMerging,
                           error: &coordinationError) { file in
      outcome = Result {
        var policy: ProtectionPolicy
        if FileManager.default.fileExists(atPath: file.path) {
          policy = try JSONDecoder().decode(ProtectionPolicy.self, from: Data(contentsOf: file))
        } else {
          policy = ProtectionPolicy()
        }
        let value = try body(&policy)
        try JSONEncoder().encode(policy).write(to: file,
          options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return value
      }
    }
    if let coordinationError = coordinationError { throw coordinationError }
    guard let outcome = outcome else { throw ProtectionFailure.storageFailed }
    return try outcome.get()
  }

  func read() throws -> ProtectionPolicy { try update { $0 } }

  static func apply(_ policy: ProtectionPolicy) {
    let store = ManagedSettingsStore(named: storeName)
    store.application.blockedApplications = policy.shouldBlock && policy.count > 0
      ? Set(policy.selection.applicationTokens.map { Application(token: $0) }) : nil
  }

  func reconcile() throws -> ProtectionPolicy {
    try update { policy in
      if policy.shouldBlock { policy.releaseUntil = nil }
      Self.apply(policy)
      return policy
    }
  }
}
