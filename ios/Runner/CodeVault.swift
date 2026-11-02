import CommonCrypto
import Foundation
import Security

struct CodeRecord: Codable {
  var salt: Data
  var digest: Data
  var rounds: UInt32
  var failures: Int = 0
  var retryAfter: Date?
}

final class CodeVault {
  private let service: String
  private let account = "verifier.v1"
  private let rounds: UInt32 = 210_000

  init(service: String? = nil) {
    self.service = service ?? (Bundle.main.bundleIdentifier ?? "calculadora") + ".access-code"
  }

  private var query: [String: Any] {
    [kSecClass as String: kSecClassGenericPassword,
     kSecAttrService as String: service, kSecAttrAccount as String: account]
  }

  private func load() throws -> CodeRecord? {
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = result as? Data else {
      throw ProtectionFailure.storageFailed
    }
    let record = try JSONDecoder().decode(CodeRecord.self, from: data)
    guard record.salt.count == 32, record.digest.count == 32,
          record.rounds >= 210_000, record.rounds <= 1_000_000,
          record.failures >= 0 else { throw ProtectionFailure.storageFailed }
    return record
  }

  var isConfigured: Bool { get throws { try load() != nil } }

  private func save(_ record: CodeRecord) throws {
    let data = try JSONEncoder().encode(record)
    let attributes: [String: Any] = [kSecValueData as String: data]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      var insert = query
      insert[kSecValueData as String] = data
      insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
      guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
        throw ProtectionFailure.storageFailed
      }
    } else if status != errSecSuccess { throw ProtectionFailure.storageFailed }
  }

  static func valid(_ code: String) -> Bool {
    code.count >= 8 && code.count <= 12 && code.utf8.allSatisfy { $0 >= 48 && $0 <= 57 }
  }

  private func derive(_ code: String, salt: Data, rounds: UInt32) throws -> Data {
    var output = [UInt8](repeating: 0, count: 32)
    let password = Array(code.utf8)
    let status = password.withUnsafeBytes { passwordBytes in
      salt.withUnsafeBytes { saltBytes in
        CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
          passwordBytes.baseAddress!.assumingMemoryBound(to: Int8.self), password.count,
          saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self), salt.count,
          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds, &output, 32)
      }
    }
    guard status == kCCSuccess else { throw ProtectionFailure.storageFailed }
    return Data(output)
  }

  private func createRecord(_ code: String) throws -> CodeRecord {
    guard Self.valid(code) else { throw ProtectionFailure.invalidCode }
    var salt = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt) == errSecSuccess else {
      throw ProtectionFailure.storageFailed
    }
    let data = Data(salt)
    return CodeRecord(salt: data, digest: try derive(code, salt: data, rounds: rounds), rounds: rounds)
  }

  func configure(_ code: String) throws {
    guard try !isConfigured else { throw ProtectionFailure.alreadyConfigured }
    try save(createRecord(code))
  }

  func verify(_ code: String, now: Date = Date()) throws -> Bool {
    guard Self.valid(code) else { return false }
    guard var record = try load() else { return false }
    if let retry = record.retryAfter, retry > now { throw ProtectionFailure.rateLimited }
    let candidate = try derive(code, salt: record.salt, rounds: record.rounds)
    var mismatch: UInt8 = 0
    for (left, right) in zip(candidate, record.digest) { mismatch |= left ^ right }
    let accepted = mismatch == 0 && Self.valid(code)
    if accepted { record.failures = 0; record.retryAfter = nil }
    else {
      record.failures = min(record.failures + 1, 15)
      if record.failures >= 5 {
        record.retryAfter = now.addingTimeInterval(min(3600, 30 * pow(2, Double(record.failures - 5))))
      }
    }
    try save(record)
    return accepted
  }

  func change(current: String, next: String) throws {
    guard Self.valid(next), try verify(current) else { throw ProtectionFailure.invalidCode }
    try save(createRecord(next))
  }
}
