import Foundation
import Security
import XCTest
@testable import Runner

final class RunnerTests: XCTestCase {
  private var service: String!
  private var vault: CodeVault!
  override func setUp() {
    super.setUp()
    service = "calculadora.tests." + UUID().uuidString
    vault = CodeVault(service: service)
  }
  override func tearDown() {
    SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service!]
      as CFDictionary)
    super.tearDown()
  }
  func testNoDefaultCodeOrOverwrite() throws {
    XCTAssertFalse(try vault.isConfigured)
    XCTAssertFalse(try vault.verify("31415926"))
    try vault.configure("00123456")
    XCTAssertTrue(try vault.verify("00123456"))
    XCTAssertFalse(try vault.verify("123456"))
    XCTAssertThrowsError(try vault.configure("87654321"))
  }
  func testRateLimitPersistsAcrossVaultInstances() throws {
    try vault.configure("00123456")
    let now = Date()
    for _ in 0..<5 { XCTAssertFalse(try vault.verify("99999999", now: now)) }
    let restored = CodeVault(service: service)
    XCTAssertThrowsError(try restored.verify("00123456", now: now))
    XCTAssertTrue(try restored.verify("00123456", now: now.addingTimeInterval(31)))
  }
  func testChangingCodeNeedsCurrentCode() throws {
    try vault.configure("00123456")
    XCTAssertThrowsError(try vault.change(current: "99999999", next: "87654321"))
    try vault.change(current: "00123456", next: "87654321")
    XCTAssertFalse(try vault.verify("00123456"))
    XCTAssertTrue(try vault.verify("87654321"))
  }
  func testAsciiDigitsAndLength() {
    XCTAssertTrue(CodeVault.valid("00000000"))
    XCTAssertTrue(CodeVault.valid("012345678901"))
    XCTAssertFalse(CodeVault.valid("1234567"))
    XCTAssertFalse(CodeVault.valid("0123456789012"))
    XCTAssertFalse(CodeVault.valid("１２３４５６７８"))
  }
  func testPersistedPolicyBlocksAfterDeadline() {
    var policy = ProtectionPolicy()
    XCTAssertTrue(policy.shouldBlock)
    policy.releaseUntil = Date().addingTimeInterval(900)
    XCTAssertFalse(policy.shouldBlock)
    policy.releaseUntil = Date().addingTimeInterval(-1)
    XCTAssertTrue(policy.shouldBlock)
  }
}
