import DeviceActivity
import Foundation

final class MonitorExtension: DeviceActivityMonitor {
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    guard activity == PolicyRepository.activityName else { return }
    // Reconcile the persisted deadline. An old callback must not end a newer release.
    do { _ = try PolicyRepository().reconcile() }
    catch {
      // Preserve the store's existing settings if protected data is unavailable.
      // The foreground app also reconciles at every launch and resume.
    }
  }
}
