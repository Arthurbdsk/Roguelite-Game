class_name DisplayNumbers
extends RefCounted

static var decimal_regex:RegEx
static var version_regex:RegEx
static func number(value:float)->String:
 if value!=0 and absf(value)<.5:return "menos de 1" if value>0 else "menos de -1"
 return str(roundi(value))
static func seconds(value:float)->String:
 if value<=0:return "0 s"
 if value<1:return "Menos de 1 s"
 return ("" if is_equal_approx(value,roundf(value)) else "Cerca de ")+"%d s"%roundi(value)
static func attack_interval(value:float)->String:
 if value>=1 or value<=0:return seconds(value)
 var frequency:float=1/value
 if is_equal_approx(frequency,roundf(frequency)):return "%d ataques por segundo"%roundi(frequency)
 return "Ataques rápidos"
static func regeneration(value:float)->String:
 if value<=0:return "0 de vida"
 for period in range(1,61):
  var amount:float=value*period
  if amount>=1 and is_equal_approx(amount,roundf(amount)):return "%d de vida a cada %d s"%[roundi(amount),period]
 return "%d de vida por minuto"%roundi(value*60)
static func change(label:String,before:float,after:float,current:int,unit:String="")->String:
 if current>0 and is_equal_approx(before,after):return ""
 var interval:bool=label.to_lower().contains("intervalo") or label=="Recarga"
 var a:String=(attack_interval(before) if interval else seconds(before)) if unit==" s" else number(before)+unit
 var b:String=(attack_interval(after) if interval else seconds(after)) if unit==" s" else number(after)+unit
 var result:String=label+": "+(a+" → " if current>0 else "")+b
 if current>0 and a==b and before!=0:
  var percent:float=(after/before-1)*100
  result+=" (%s%s%%)"%["+" if percent>0 else "",number(percent)] if absf(percent)>=.5 else " (mudança menor que 1%)"
 return result
# Legacy descriptions and DEV diagnostics use the same presentation rules.
static func clean(value:String)->String:
 if decimal_regex==null:
  decimal_regex=RegEx.new();decimal_regex.compile("[0-9]+(?:[.,][0-9]+)?\\s*ms\\b|[0-9]+[.,][0-9]+(?:\\s*(?:vida/s|s\\b))?")
  version_regex=RegEx.new();version_regex.compile("[0-9]+\\.[0-9]+\\.[0-9]+")
 var versions:Dictionary={}
 for hit in version_regex.search_all(value):versions["VERSION_"+str(versions.size())+"_END"]=hit.get_string()
 for token in versions:value=value.replace(versions[token],token)
 var result:String=value
 var matches:Array=decimal_regex.search_all(value)
 for i in range(matches.size()-1,-1,-1):
  var hit=matches[i];var raw:String=hit.get_string();var n:float=raw.replace(",",".").to_float()
  var formatted:String=seconds(n/1000) if raw.ends_with("ms") else regeneration(n) if raw.ends_with("vida/s") else seconds(n) if raw.ends_with("s") else number(n)
  result=result.substr(0,hit.get_start())+formatted+result.substr(hit.get_end())
 for token in versions:result=result.replace(token,versions[token])
 return result
