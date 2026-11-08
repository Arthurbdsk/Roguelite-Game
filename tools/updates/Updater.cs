using System;
using System.IO;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Net;
class Updater {
 const string PublicKey="PUBLIC_KEY_XML";
 static string target,backup,root;static bool applied;static Process child;
 static int Main(string[] args) {
  if(args.Length>=4&&args[0]=="--fetch")return Fetch(args);
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
   foreach(var other in Process.GetProcessesByName("Hordas")){try{if(!other.HasExited&&String.Equals(other.MainModule.FileName,target,StringComparison.OrdinalIgnoreCase))throw new IOException("Feche as outras instancias do jogo antes de atualizar");}catch(System.ComponentModel.Win32Exception){}}
   if(File.Exists(target))File.Copy(target,backup,true);else File.Copy((string)r["old"],backup,true);
   string next=Path.Combine(root,"Hordas.next.exe");File.Copy(download,next,true);
   if(File.Exists(target))File.Replace(next,target,null);else File.Move(next,target);
   applied=true;
   string health=Path.Combine(work,"health-"+Guid.NewGuid().ToString("N")+".txt");
   child=Process.Start(new ProcessStartInfo(target,"-- --update-health=\""+health+"\""){WorkingDirectory=root,UseShellExecute=false});
   File.WriteAllText(Path.Combine(work,"installed-pid.txt"),child.Id.ToString());
   for(int i=0;i<60;i++){Thread.Sleep(500);if(child.HasExited)throw new Exception("Nova versao encerrou");if(File.Exists(health)&&File.ReadAllText(health)==(string)p["version"]){File.WriteAllText(Path.Combine(work,"result.txt"),"OK");return 0;}}
   throw new Exception("Inicializacao nao confirmada");
  } catch(Exception e) {
   try{File.WriteAllText(Path.Combine(work,"result.txt"),"ERRO: "+e.Message);}catch{}
   try{if(applied&&File.Exists(backup)){if(child!=null&&!child.HasExited){child.Kill();child.WaitForExit();}File.Copy(backup,target,true);var restored=Process.Start(target);File.WriteAllText(Path.Combine(work,"restored-pid.txt"),restored.Id.ToString());}}catch{}
   return 1;
  }
 }
 static int Fetch(string[] args) {
  string destination=args[2];
  try {
   var uri=new Uri(args[1]);if(uri.Scheme!="https")throw new Exception("HTTPS obrigatorio");
   ServicePointManager.SecurityProtocol=SecurityProtocolType.Tls12;
   long limit=long.Parse(args[3]);
   if(args.Length==5){string pin=args[4];ServicePointManager.ServerCertificateValidationCallback=(sender,cert,chain,errors)=>{using(var sha=SHA256.Create()){string actual=BitConverter.ToString(sha.ComputeHash(cert.GetRawCertData())).Replace("-","").ToLowerInvariant();File.WriteAllText(destination+".tls",actual+" expected "+pin);return actual==pin;}};}
   var request=(HttpWebRequest)WebRequest.Create(uri);if(uri.IsLoopback)request.Proxy=null;request.KeepAlive=false;request.ProtocolVersion=HttpVersion.Version10;request.Timeout=30000;request.ReadWriteTimeout=30000;request.UserAgent="Hordas-Updater";
   using(var response=(HttpWebResponse)request.GetResponse()) {
    if(response.ResponseUri.Scheme!="https"||response.ContentLength>limit)throw new Exception("Resposta invalida");
    using(var input=response.GetResponseStream())using(var output=File.Create(destination)){
     byte[] buffer=new byte[65536];int read;long total=0;var timer=Stopwatch.StartNew();long lastProgress=0;
     while((read=input.Read(buffer,0,buffer.Length))>0){total+=read;if(total>limit)throw new Exception("Arquivo grande demais");output.Write(buffer,0,read);if(timer.ElapsedMilliseconds-lastProgress>=250){File.WriteAllText(destination+".progress",total.ToString());lastProgress=timer.ElapsedMilliseconds;}}
     File.WriteAllText(destination+".progress",total.ToString());
    }
   }
   File.WriteAllText(destination+".result","200");return 0;
  }catch(Exception e){File.WriteAllText(destination+".result","ERROR "+e.ToString());return 1;}
 }
}
