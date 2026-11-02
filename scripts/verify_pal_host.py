"""Compare each hosted ADP file with the locally recorded bytes before distribution."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import quote
import urllib.request
from prepare_pal_source import https_url

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--base-url', required=True)
    args = parser.parse_args()
    base = https_url(args.base_url).rstrip('/')
    inventory = json.loads((args.package/'integrity.json').read_text(encoding='utf-8'))
    for item in inventory:
        digest, size = hashlib.sha256(), 0
        with urllib.request.urlopen(base+'/'+quote(item['path'], safe='/'), timeout=60) as response:
            while chunk := response.read(1024 * 1024): digest.update(chunk); size += len(chunk)
        if size != item['size'] or digest.hexdigest() != item['sha256']:
            raise SystemExit('Integridade divergente: ' + item['path'])
    with urllib.request.urlopen(base+'/source.json', timeout=30) as response:
        remote_source = json.load(response)
    local_source = json.loads((args.package/'source.json').read_text(encoding='utf-8'))
    if remote_source != local_source: raise SystemExit('source.json publicado difere do preparado.')
    print('Fonte e arquivos ADP publicados conferem com o pacote local.')
