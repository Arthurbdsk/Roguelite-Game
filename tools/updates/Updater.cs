using System;
using System.IO;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Collections.Generic;
class Updater {
 const string PublicKey="PUBLIC_KEY_XML";
 static string target,backup,root;static bool applied;static Process child;
 static int Main(string[] args) {
  root=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Hordas","Game");
  target=Path.Combine(root,"Hordas.exe");backup=Path.Combine(root,"Hordas.previous.exe");
  string work=Path.GetDirectoryName(Path.GetFullPath(args[0]));
  try {
   var json=new JavaScriptSerializer();json.MaxJsonLength=262144;
   dynamic r=json.Deserialize<Dictionary<string,object>>(File.ReadAllText(args[0]));
   var e=json.Deserialize<Dictionary<string,object>>((string)r["envelope"]);
   byte[] bytes=Convert.FromBase64String((string)e["payload"]);
   using(var rsa=new RSACryptoServiceProvider()){rsa.FromXmlString(PublicKey);if(!rsa.VerifyData(bytes,"SHA256",Convert.FromBase64String((string)e["signature"])))throw new Exception("Assinatura invalida");}
   var m=json.Deserialize<Dictionary<string,object>>(Encoding.UTF8.GetString(bytes));
   if(Convert.ToInt32(m["schema"])!=1 || Convert.ToInt64(m["expires"])<DateTimeOffset.UtcNow.ToUnixTimeSeconds())throw new Exception("Manifesto vencido");
   var platforms=(Dictionary<string,object>)m["platforms"];var p=(Dictionary<string,object>)platforms["pc"];
   string download=Path.Combine(work,"download.part");
   if((string)p["platform"]!="pc" || new FileInfo(download).Length!=Convert.ToInt64(p["size"]))throw new Exception("Plataforma/tamanho invalidos");
   using(var reader=new BinaryReader(File.OpenRead(download))){if(reader.ReadUInt16()!=0x5a4d)throw new Exception("Formato invalido");reader.BaseStream.Position=0x3c;int offset=reader.ReadInt32();if(offset<64||offset>reader.BaseStream.Length-6)throw new Exception("Formato invalido");reader.BaseStream.Position=offset;if(reader.ReadUInt32()!=0x4550||reader.ReadUInt16()!=0x8664)throw new Exception("Executavel nao e Windows x64");}
   using(var sha=SHA256.Create())using(var file=File.OpenRead(download)){if(BitConverter.ToString(sha.ComputeHash(file)).Replace("-","").ToLowerInvariant()!=(string)p["sha256"])throw new Exception("Arquivo corrompido");}
   try {var old=Process.GetProcessById(Convert.ToInt32(r["pid"]));if(!old.WaitForExit(60000))throw new Exception("Jogo ainda aberto");}catch(ArgumentException){}
   Directory.CreateDirectory(root);
   if(File.Exists(target))File.Copy(target,backup,true);else File.Copy((string)r["old"],backup,true);
   string next=Path.Combine(root,"Hordas.next.exe");File.Copy(download,next,true);
   if(File.Exists(target))File.Replace(next,target,null);else File.Move(next,target);
   applied=true;
   string health=Path.Combine(work,"health-"+Guid.NewGuid().ToString("N")+".txt");
   child=Process.Start(new ProcessStartInfo(target,"-- --update-health=\""+health+"\""){WorkingDirectory=root,UseShellExecute=false});
   for(int i=0;i<60;i++){Thread.Sleep(500);if(child.HasExited)throw new Exception("Nova versao encerrou");if(File.Exists(health)&&File.ReadAllText(health)==(string)p["version"]){File.WriteAllText(Path.Combine(work,"result.txt"),"OK");return 0;}}
   throw new Exception("Inicializacao nao confirmada");
  } catch(Exception e) {
   try{if(applied&&File.Exists(backup)){if(child!=null&&!child.HasExited){child.Kill();child.WaitForExit();}File.Copy(backup,target,true);Process.Start(target);}File.WriteAllText(Path.Combine(work,"result.txt"),"ERRO: "+e.Message);}catch{}
   return 1;
  }
 }
}
