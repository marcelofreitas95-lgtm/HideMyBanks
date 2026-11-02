#!/usr/bin/env bash
set -euo pipefail
flutter build ios --simulator --debug
destination="$(python3 - <<'PY'
import json, subprocess
devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','-j']))['devices']
for runtime, items in devices.items():
    if 'iOS' in runtime:
        for item in items:
            if item['name'].startswith('iPhone'):
                print('platform=iOS Simulator,id='+item['udid'])
                raise SystemExit(0)
raise SystemExit('Nenhum simulador iPhone disponível.')
PY
)"
mkdir -p build/reports
xcode_args=(
  -project ios/Runner.xcodeproj -scheme Runner -configuration Debug
  -destination "$destination" -derivedDataPath build/ios-tests
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
)
# Simulator tests need signed entitlements for real Keychain access. The local
# ad hoc signature uses no Apple certificate and does not sign a device IPA.
xcodebuild build-for-testing "${xcode_args[@]}"
simulator_app=build/ios-tests/Build/Products/Debug-iphonesimulator/Runner.app
codesign --verify --strict "$simulator_app"
codesign -d --entitlements - "$simulator_app" > build/reports/simulator-entitlements.plist
python3 - <<'PY'
import plistlib
from pathlib import Path
entitlements = plistlib.loads(Path('build/reports/simulator-entitlements.plist').read_bytes())
if not any(entitlements.get(key) for key in (
    'application-identifier', 'keychain-access-groups', 'com.apple.security.application-groups'
)):
    raise SystemExit('A assinatura do simulador nao permite acesso ao Keychain.')
print('Assinatura e grupos de acesso ao Keychain verificados no app do simulador.')
PY
test_status=0
xcodebuild test-without-building "${xcode_args[@]}" \
  -resultBundlePath build/reports/native.xcresult || test_status=$?
if xcrun xcresulttool get test-results summary --path build/reports/native.xcresult \
    > build/reports/native-summary.json; then
  cat build/reports/native-summary.json
fi
exit "$test_status"
