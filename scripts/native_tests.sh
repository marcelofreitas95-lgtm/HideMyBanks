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
xcodebuild test -project ios/Runner.xcodeproj -scheme Runner \
  -destination "$destination" -resultBundlePath build/reports/native.xcresult \
  CODE_SIGNING_ALLOWED=NO
