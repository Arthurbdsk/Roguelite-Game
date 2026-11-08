from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
source=(root/'tools/updates/Updater.cs').read_text().replace('PUBLIC_KEY_XML',(root/'data/updates/public.xml').read_text())
generated=root/'build/Updater.generated.cs';generated.parent.mkdir(exist_ok=True);generated.write_text(source)
subprocess.run([r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe','/nologo','/target:winexe','/r:System.Web.Extensions.dll','/r:Microsoft.CSharp.dll','/out:'+str(root/'data/updates/Updater.exe'),str(generated)],check=True)
