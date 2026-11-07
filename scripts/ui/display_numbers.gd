class_name DisplayNumbers
extends RefCounted

static var decimal_regex:RegEx
static func number(value:float)->String:
 if value!=0 and absf(value)<.5:return "menos de 1" if value>0 else "menos de -1"
 return str(roundi(value))
static func seconds(value:float)->String:
 if is_equal_approx(value,roundf(value)) and value>=1:return "%d s"%roundi(value)
 return "%d ms"%maxi(0,roundi(value*1000))
static func regeneration(value:float)->String:
 if value<=0:return "0 de vida"
 for period in range(1,61):
  var amount:float=value*period
  if amount>=1 and is_equal_approx(amount,roundf(amount)):return "%d de vida a cada %d s"%[roundi(amount),period]
 return "%d de vida por minuto"%roundi(value*60)
static func change(label:String,before:float,after:float,current:int,unit:String="")->String:
 if current>0 and is_equal_approx(before,after):return ""
 var a:String=seconds(before) if unit==" s" else number(before)+unit
 var b:String=seconds(after) if unit==" s" else number(after)+unit
 var result:String=label+": "+(a+" → " if current>0 else "")+b
 if current>0 and a==b and before!=0:
  var percent:float=(after/before-1)*100
  result+=" (%s%s%%)"%["+" if percent>0 else "",number(percent)] if absf(percent)>=.5 else " (mudança menor que 1%)"
 return result
# Legacy descriptions and DEV diagnostics use the same presentation rules.
static func clean(value:String)->String:
 if decimal_regex==null:
  decimal_regex=RegEx.new();decimal_regex.compile("[0-9]+[.,][0-9]+(?:\\s*(?:vida/s|s\\b))?")
 var result:String=value
 var matches:Array=decimal_regex.search_all(value)
 for i in range(matches.size()-1,-1,-1):
  var hit=matches[i];var raw:String=hit.get_string();var n:float=raw.replace(",",".").to_float()
  var formatted:String=regeneration(n) if raw.ends_with("vida/s") else seconds(n) if raw.ends_with("s") else number(n)
  result=result.substr(0,hit.get_start())+formatted+result.substr(hit.get_end())
 return result
