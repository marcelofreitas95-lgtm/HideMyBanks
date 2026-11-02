"""Stage an untouched notarized ADP and a PAL source, after release validation."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import shutil
from urllib.parse import urlparse
from release_gate import validate

ROOT = Path(__file__).resolve().parents[1]

def https_url(value):
    url = urlparse(value)
    if (url.scheme != 'https' or not url.hostname or url.username or url.password
            or url.hostname.endswith(('.invalid', '.localhost'))
            or url.hostname in ('localhost', '127.0.0.1', 'example.com')):
        raise ValueError('Informe uma URL HTTPS pública real.')
    return value

def make_source(identity, manifest_url, size, entitlements):
    for key in ('website', 'privacyURL', 'iconURL'): https_url(identity[key])
    for screenshot in identity['screenshots']: https_url(screenshot)
    https_url(manifest_url)
    if not str(identity['marketplaceID']).isdigit(): raise ValueError('Apple ID inválido.')
    version = {
      'version': identity['version'], 'buildVersion': str(identity['buildNumber']),
      'date': datetime.datetime.now(datetime.timezone.utc).isoformat(),
      'downloadURL': manifest_url, 'size': size, 'minOSVersion': '16.0',
      'localizedDescription': 'Primeira versão da Calculadora com controles privados do Tempo de Uso.'
    }
    return {
      'name': 'Calculadora', 'website': identity['website'], 'tintColor': '#D9AB62',
      'apps': [{
        'name': 'Calculadora', 'bundleIdentifier': identity['bundleIdentifier'],
        'marketplaceID': str(identity['marketplaceID']), 'developerName': identity['developerName'],
        'subtitle': 'Calculadora com controles privados.',
        'localizedDescription': 'Calculadora com uma área privada por número de acesso e seleção de aplicativos pelo Tempo de Uso do iOS. Permite aplicar bloqueio e liberar acesso temporário por 15 minutos. A autorização pode ser revogada e o app pode ser removido. O bloqueio e as notificações dependem do comportamento do iOS. Não há garantia contra coação. Privacidade: ' + identity['privacyURL'],
        'iconURL': identity['iconURL'], 'screenshots': identity['screenshots'],
        'category': 'utilities', 'tintColor': '#D9AB62', 'versions': [version],
        'appPermissions': {'entitlements': entitlements, 'privacy': {}}
      }], 'news': []
    }

def stage(adp, output, identity, base_url, signing):
    if any(signing.get(key) != identity[key] for key in ['bundleIdentifier', 'version', 'buildNumber']):
        raise ValueError('Relatório de assinatura corresponde a outra versão.')
    if not signing.get('signatureVerified') or not signing.get('monitorVerified'):
        raise ValueError('Assinaturas não validadas.')
    if signing.get('profileType') != 'app_store':
        raise ValueError('Pacote de desenvolvimento não pode ser distribuído pelo PAL.')
    adp, output = adp.resolve(), output.resolve()
    if output == adp or adp in output.parents or output in adp.parents:
        raise ValueError('Destino e ADP precisam estar em diretórios separados.')
    if output.exists(): raise ValueError('Use um destino novo; arquivos existentes serão preservados.')
    if not (adp/'manifest.json').is_file(): raise ValueError('manifest.json ausente no ADP.')
    if not (adp/'signature').is_file(): raise ValueError('Assinatura ausente no ADP.')
    files = list(adp.rglob('*'))
    if any(file.is_symlink() for file in files): raise ValueError('Links simbólicos não são aceitos.')
    variants = [file for file in files if file.suffix == '.ipa' and file.is_file()]
    if not variants: raise ValueError('Nenhuma variante IPA encontrada no ADP.')
    size = variants[0].stat().st_size
    base_url = https_url(base_url).rstrip('/')
    subdirectory = f'adp/{identity["version"]}-{identity["buildNumber"]}'
    source = make_source(identity, base_url + '/' + subdirectory + '/manifest.json', size, signing['entitlements'])
    target = output / subdirectory
    shutil.copytree(adp, target)
    inventory = []
    for file in sorted(target.rglob('*')):
        if file.is_file():
            relative = file.relative_to(target)
            original = adp / relative
            with file.open('rb') as stream: digest = hashlib.file_digest(stream, 'sha256').hexdigest()
            with original.open('rb') as stream: original_digest = hashlib.file_digest(stream, 'sha256').hexdigest()
            if digest != original_digest:
                raise ValueError('Arquivo do ADP foi alterado durante a cópia.')
            inventory.append({'path': file.relative_to(output).as_posix(),
                'sha256': digest, 'size': file.stat().st_size})
    (output/'source.json').write_text(json.dumps(source, ensure_ascii=False, indent=2), encoding='utf-8')
    (output/'integrity.json').write_text(json.dumps(inventory, indent=2), encoding='utf-8')
    print('Pacote PAL preparado; manifest e assinatura copiados sem alteração.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--adp', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--base-url', required=True)
    parser.add_argument('--signing-report', required=True, type=Path)
    args = parser.parse_args()
    identity = json.loads((ROOT/'release/identity.json').read_text(encoding='utf-8'))
    readiness = json.loads((ROOT/'release/readiness.json').read_text(encoding='utf-8'))
    errors = validate(identity, readiness)
    if errors: raise SystemExit('\n'.join(errors))
    stage(args.adp, args.output, identity, args.base_url,
          json.loads(args.signing_report.read_text(encoding='utf-8')))
