"""Require actual evidence for this version before marketplace submission."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ('nativeBuild', 'nativeTests', 'familyControlsAppApproved',
 'familyControlsMonitorApproved', 'marketplaceProvisioningSupported', 'physicalDevice',
 'hiddenHomeAndLibrary', 'hiddenSearch', 'launchBlocked', 'notificationsSuppressed',
 'automaticRelock', 'rebootAndTermination', 'authorizationRevocation', 'privacyAndMetadata')

def validate(identity, readiness):
    errors = []
    for key in ('bundleIdentifier', 'teamID', 'marketplaceID', 'developerName',
                'website', 'privacyURL', 'iconURL'):
        if not identity.get(key): errors.append('Identidade pendente: ' + key)
    if not identity.get('screenshots'): errors.append('Screenshots reais pendentes.')
    for key in ('version', 'buildNumber'):
        if identity.get(key) != readiness.get(key): errors.append('Evidências de outra versão: ' + key)
    for key in REQUIRED:
        item = readiness.get(key, {})
        if item.get('passed') is not True or not str(item.get('evidence', '')).strip():
            errors.append('Validação pendente: ' + key)
    return errors

if __name__ == '__main__':
    errors = validate(json.loads((ROOT/'release/identity.json').read_text(encoding='utf-8')),
                      json.loads((ROOT/'release/readiness.json').read_text(encoding='utf-8')))
    if errors: raise SystemExit('\n'.join(errors))
    print('Evidências presentes para esta versão. Continuar com a notarização.')
