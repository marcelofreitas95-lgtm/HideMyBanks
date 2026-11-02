"""Inspect actual signed app/monitor, entitlements and provisioning in a macOS archive."""
import argparse
import datetime
import json
from pathlib import Path
import plistlib
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def inspect(archive, identity, expected_type):
    app = archive/'Products/Applications/Runner.app'
    monitor = app/'PlugIns/Monitor.appex'
    entitlements = set()
    for bundle, expected_id in [(app, identity['bundleIdentifier']),
                               (monitor, identity['bundleIdentifier']+'.Monitor')]:
        subprocess.run(['codesign', '--verify', '--strict', str(bundle)], check=True,
                       capture_output=True)
        info = plistlib.loads((bundle/'Info.plist').read_bytes())
        if (info['CFBundleIdentifier'] != expected_id or
            info['CFBundleShortVersionString'] != identity['version'] or
            str(info['CFBundleVersion']) != str(identity['buildNumber'])):
            raise ValueError('Identidade ou versão da app/extensão divergente.')
        signed = plistlib.loads(subprocess.check_output(
            ['codesign', '-d', '--entitlements', ':-', str(bundle)], stderr=subprocess.DEVNULL))
        profile = plistlib.loads(subprocess.check_output(
            ['security', 'cms', '-D', '-i', str(bundle/'embedded.mobileprovision')], stderr=subprocess.DEVNULL))
        profile_type = 'development' if signed.get('get-task-allow') else 'ad_hoc' if profile.get('ProvisionedDevices') else 'app_store'
        if profile_type != expected_type or profile.get('ProvisionsAllDevices'):
            raise ValueError('Tipo de perfil incompatível com o workflow.')
        for data in [signed, profile['Entitlements']]:
            if data.get('com.apple.developer.family-controls') is not True:
                raise ValueError('Family Controls ausente na assinatura ou no perfil.')
            if 'group.'+identity['bundleIdentifier'] not in data.get('com.apple.security.application-groups', []):
                raise ValueError('App Group ausente na assinatura ou no perfil.')
        if signed.get('application-identifier') != identity['teamID']+'.'+expected_id:
            raise ValueError('Assinatura de outra equipe ou aplicativo.')
        if profile['ExpirationDate'] <= datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None):
            raise ValueError('Perfil de provisionamento expirado.')
        entitlements.update(set(signed)-{'application-identifier', 'com.apple.developer.team-identifier'})
    return {key: identity[key] for key in ['bundleIdentifier', 'version', 'buildNumber']} | {
        'entitlements': sorted(entitlements), 'signatureVerified': True, 'monitorVerified': True,
        'profileType': expected_type}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--expected-type', choices=['development', 'app_store'], required=True)
    args = parser.parse_args()
    try:
        result = inspect(args.archive, json.loads((ROOT/'release/identity.json').read_text(encoding='utf-8')), args.expected_type)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(result, indent=2), encoding='utf-8')
        print('Assinaturas, Family Controls, App Group e versões conferidos.')
    except Exception:
        raise SystemExit('Validação da assinatura falhou. Confira os perfis, identidades e entitlements da app e da extensão.')
