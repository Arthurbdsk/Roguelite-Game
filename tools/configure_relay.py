"""Validate permanent HTTPS health before writing the public WSS endpoint."""
import argparse, json
from pathlib import Path
from urllib.parse import urlsplit
from urllib.request import urlopen

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('url',help='wss://salas.seudominio.com')
parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parents[1]/'network.cfg')
args=parser.parse_args()
url=urlsplit(args.url)
if url.scheme!='wss' or not url.hostname or url.username or url.password or url.query or url.fragment:
    parser.error('Use WSS publico, sem credenciais, parametros ou fragmentos.')
health='https://'+url.netloc+'/health'
try:
    with urlopen(health,timeout=10) as response:
        info=json.load(response)
    if not info.get('ok') or 2 not in info.get('supported',[]):
        raise ValueError('Servidor nao suporta protocolo 2')
except Exception as error:
    raise SystemExit(f'Endpoint nao configurado: {error}')
args.output.write_text('[relay]\nurl='+json.dumps(args.url)+'\n',encoding='utf8')
print('HTTPS/certificado e protocolo verificados. WSS deve ser validado com quatro processos antes de distribuir:',args.output)
