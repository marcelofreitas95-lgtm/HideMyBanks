"""Official PAL API helper. Access tokens are saved privately, never printed."""
import argparse
import json
import os
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
API = 'https://api.altstore.io'
PRIVATE_DIR = Path(os.environ.get('LOCALAPPDATA', str(Path.home()/'.local/share'))) / 'CalculadoraRelease'

def request(path, payload=None):
    body = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(API + path, data=body,
        headers={'Content-Type': 'application/json', 'User-Agent': 'Calculadora-Release/1.0'})
    with urllib.request.urlopen(req, timeout=60) as response:
        return json.load(response)

def private_result(name, result):
    folder = PRIVATE_DIR
    folder.mkdir(parents=True, exist_ok=True)
    if os.name != 'nt': folder.chmod(0o700)
    file = folder / name
    file.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    if os.name != 'nt': file.chmod(0o600)
    print('Resultado salvo fora do projeto: ' + str(file))
    print('Não compartilhe o conteúdo.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='command', required=True)
    register = commands.add_parser('register')
    register.add_argument('--developer-id', required=True)
    register.add_argument('--email', required=True)
    for name in ('process', 'status'):
        command = commands.add_parser(name)
        command.add_argument('--adp-id', required=True)
    args = parser.parse_args()
    try:
        if args.command == 'register':
            private_result('altstore-registration.json', request('/register',
              {'developerID': args.developer_id, 'email': args.email}))
        elif args.command == 'process':
            private_result('altstore-processing.json', request('/adps', {'adpID': args.adp_id}))
        else:
            import urllib.parse
            private_result('altstore-adp.json', request('/adps/' + urllib.parse.quote(args.adp_id, safe='')))
    except Exception:
        raise SystemExit('A operação com AltStore PAL falhou. Verifique a conexão e os dados; detalhes de acesso não serão exibidos.')
