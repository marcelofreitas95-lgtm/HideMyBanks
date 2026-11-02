"""Configure registered identifiers and matching app/extension versions."""
import argparse
import json
import re
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def configure(bundle, team, version, number):
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z][A-Za-z0-9-]*){2,}', bundle):
        raise ValueError('Use um bundle identifier registrado, com três ou mais componentes.')
    if bundle.startswith(('com.example.', 'com.calculadora.')):
        raise ValueError('Substitua o identificador de exemplo pelo registrado em sua conta.')
    if not re.fullmatch(r'[A-Z0-9]{10}', team): raise ValueError('Team ID inválido.')
    if not re.fullmatch(r'\d+\.\d+\.\d+', version) or number < 1:
        raise ValueError('Versão ou número de build inválidos.')
    project = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    text = project.read_text(encoding='utf-8')
    match = re.search(r'PRODUCT_BUNDLE_IDENTIFIER = ([A-Za-z0-9.-]+);', text)
    if not match: raise ValueError('Identificador base não encontrado.')
    old = match[1].removesuffix('.RunnerTests').removesuffix('.Monitor')
    text = text.replace(old, bundle)
    text = re.sub(r'\bDEVELOPMENT_TEAM = [^;]+;', '', text)
    text = text.replace('CODE_SIGN_STYLE = Automatic;',
                        f'CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = {team};')
    text = re.sub(r'MARKETING_VERSION = [^;]+;', f'MARKETING_VERSION = {version};', text)
    text = re.sub(r'CURRENT_PROJECT_VERSION = [0-9]+;', f'CURRENT_PROJECT_VERSION = {number};', text)
    project.write_text(text, encoding='utf-8')
    for name in ['Runner/Runner.entitlements', 'DeviceActivityMonitor/Monitor.entitlements']:
        file = ROOT / 'ios' / name
        data = plistlib.loads(file.read_bytes())
        data['com.apple.security.application-groups'] = ['group.' + bundle]
        file.write_bytes(plistlib.dumps(data, sort_keys=False))
    for name in ['Runner/Info.plist', 'DeviceActivityMonitor/Info.plist']:
        file = ROOT / 'ios' / name
        data = plistlib.loads(file.read_bytes())
        data['CalculatorAppGroup'] = 'group.' + bundle
        file.write_bytes(plistlib.dumps(data, sort_keys=False))
    print(f'Runner: {bundle}; Monitor: {bundle}.Monitor; App Group: group.{bundle}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--identity', type=Path, default=ROOT/'release/identity.json')
    args = parser.parse_args()
    data = json.loads(args.identity.read_text(encoding='utf-8'))
    configure(data.get('bundleIdentifier') or '', data.get('teamID') or '',
              data['version'], data['buildNumber'])
