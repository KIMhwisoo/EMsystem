// CarThermo Bridge + HTTP Server (r4, CORS preflight fixed)
// - Adds proper CORS handling (OPTIONS) so WebApp on another port (8080) can POST.
// - Endpoints: /api/latest, /api/cfg (GET), /api/update_cfg (POST).
// - Same serial + logging behavior as previous.

import processing.serial.*;
import processing.net.*;
import java.util.*;
import java.nio.charset.StandardCharsets;

String IN_HINT  = "COM3";   // change if needed
String OUT_HINT = "";       // optional second HC-06
final int BAUD = 9600, HTTP_PORT = 5200, HIST_LIMIT = 250;

Serial inSer=null, outSer=null;
Server http=null;

ArrayList<String> hist = new ArrayList<String>();
String latestLine=""; float T_HI=40.0, T_LO=0.0; boolean SILENT=false;
String IN_SELECTED="(none)", OUT_SELECTED="(none)";

void setup(){
  size(920,520);
  textFont(createFont("Consolas",14));

  String[] ports = Serial.list();
  println("Serial Ports:", Arrays.toString(ports));
  String inPort  = selectInPort(ports, IN_HINT);
  String outPort = selectOutPort(ports, inPort, OUT_HINT);
  IN_SELECTED = inPort!=null?inPort:"(none)";
  OUT_SELECTED = outPort!=null?outPort:"(none)";

  if(inPort!=null){ try{ inSer=new Serial(this,inPort,BAUD); inSer.bufferUntil('\n'); log("[SYS] IN opened: "+inPort);}catch(Exception e){log("[ERR] IN open: "+e);} }
  else log("[WARN] IN not found");

  if(outPort!=null){ try{ outSer=new Serial(this,outPort,BAUD); outSer.bufferUntil('\n'); log("[SYS] OUT opened: "+outPort);}catch(Exception e){log("[ERR] OUT open: "+e); outSer=null; OUT_SELECTED="(none)";} }
  else log("[INFO] OUT not found → Monitor-only");

  http = new Server(this, HTTP_PORT);
  println("HTTP server on", HTTP_PORT);
}

void draw(){
  background(250);
  fill(20); text("CarThermo Bridge + HTTP Server (r4 CORS)",12,22);
  fill(0);
  text("IN  : "+IN_SELECTED+" @ "+BAUD,12,48);
  text("OUT : "+OUT_SELECTED+" @ "+BAUD+(outSer==null?"   [Monitor-only]":""),12,70);
  text("HTTP: http://localhost:"+HTTP_PORT+"  (API: /api/latest, /api/cfg, /api/update_cfg)",12,92);

  Client c = http.available();
  if(c!=null){
    try{
      if(c.active()) handleHttp(c);
    }catch(Exception e){
      log("[SOCKET] "+e.getMessage());
    }finally{
      safeClose(c);
    }
  }

  int y=130, start=max(0, hist.size()-22);
  for(int i=start;i<hist.size();i++){
    String line = hist.get(i);
    if(line.startsWith("[IN]")) fill(20,120,20);
    else if(line.startsWith("[OUT]")) fill(40,80,160);
    else fill(60);
    text(line, 12, y); y+=18;
  }
}

void serialEvent(Serial which){
  try{
    String line = which.readStringUntil('\n');
    if(line==null) return;
    line = trim(line);
    if(line.length()==0) return;

    if(which==inSer){
      latestLine = line;
      log("[IN] "+line);
      if(outSer!=null){ outSer.write(line+"\n"); log("[->OUT] "+line); }
      if(line.startsWith("CFG,")) mirrorCfg(line);
    }else if(which==outSer){
      log("[OUT] "+line);
      if(inSer!=null){ inSer.write(line+"\n"); log("[->IN] "+line); }
    }
  }catch(Exception e){ log("[ERR] serialEvent: "+e); }
}

void handleHttp(Client c){
  String req = readReq(c);
  if(req==null) return;

  String method = firstTok(req);
  String path   = secondTok(req);

  // --- CORS preflight (OPTIONS) ---
  if("OPTIONS".equals(method)){
    respondCORS(c); // 204 No Content with CORS headers
    return;
  }

  if(method==null||path==null){
    respondJSON(c,400,"{\"err\":\"bad request\"}");
    return;
  }

  if(method.equals("GET") && path.startsWith("/api/latest")){
    String latest = latestLine.startsWith("T,") ? "{ \"t\":"+latestLine.substring(2)+" }" : "{}";
    respondJSON(c,200,"{ \"latest\": "+latest+", \"cfg\": "+cfgJson()+" }");
  }else if(method.equals("GET") && path.startsWith("/api/cfg")){
    respondJSON(c,200, cfgJson());
  }else if(method.equals("POST") && path.startsWith("/api/update_cfg")){
    String body = bodyOf(req);
    log("[HTTP] /api/update_cfg body: "+body);
    if(body==null || body.trim().isEmpty()){
      respondJSON(c,400,"{\"err\":\"no body\"}");
    }else{
      boolean ok = applyCfg(body);
      respondJSON(c, ok?200:400, ok? "{\"ok\":true}" : "{\"err\":\"bad cfg\"}");
    }
  }else{
    respondJSON(c,404,"{\"err\":\"not found\"}");
  }
}

String cfgJson(){ return "{ \"t_hi\":"+nf(T_HI,0,1)+", \"t_lo\":"+nf(T_LO,0,1)+", \"silent\":"+(SILENT?"true":"false")+" }"; }

boolean applyCfg(String b){
  try{
    Float hi = num(b, "\"t_hi\"");
    Float lo = num(b, "\"t_lo\"");
    Boolean si = bool(b, "\"silent\"");
    if(hi!=null){ T_HI=hi; cmdIn("SET,HI,"+nf(T_HI,0,1)); }
    if(lo!=null){ T_LO=lo; cmdIn("SET,LO,"+nf(T_LO,0,1)); }
    if(si!=null){ SILENT=si.booleanValue(); cmdIn("SET,SILENT,"+(SILENT?"1":"0")); }
    log("[CFG] now "+cfgJson());
    return true;
  }catch(Exception e){
    log("[ERR] applyCfg: "+e);
    return false;
  }
}

void mirrorCfg(String l){
  try{
    String[] t=split(l,',');
    if(t.length>=7){ T_HI=float(t[2]); T_LO=float(t[4]); SILENT=t[6].equals("1"); }
  }catch(Exception e){}
}

void cmdIn(String s){
  if(inSer==null) return;
  log("[HTTP->IN] "+s);
  inSer.write(s+"\n");
}

// ===== HTTP helpers =====
void respondCORS(Client c){
  // Minimal 204 with required headers for preflight success
  try{
    String hdr = ""
      + "HTTP/1.1 204 No Content\r\n"
      + "Access-Control-Allow-Origin: *\r\n"
      + "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
      + "Access-Control-Allow-Headers: Content-Type\r\n"
      + "Access-Control-Max-Age: 600\r\n"
      + "Content-Length: 0\r\n\r\n";
    c.write(hdr);
  }catch(Exception e){ log("[SOCKET] preflight write error: "+e.getMessage()); }
}

void respondJSON(Client c, int code, String json){
  try{
    String status=(code==200)?"200 OK":(code==400)?"400 Bad Request":(code==404)?"404 Not Found":(""+code);
    String hdr = "HTTP/1.1 "+status+"\r\n"
       + "Content-Type: application/json; charset=utf-8\r\n"
       + "Access-Control-Allow-Origin: *\r\n"
       + "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
       + "Access-Control-Allow-Headers: Content-Type\r\n"
       + "Content-Length: "+json.getBytes(StandardCharsets.UTF_8).length+"\r\n\r\n";
    c.write(hdr + json);
  }catch(Exception e){ log("[SOCKET] write error: "+e.getMessage()); }
}

String readReq(Client c){
  int timeout=2000, step=30, waited=0; String acc="";
  while(waited<timeout){
    if(!c.active()) return null;
    if(c.available()>0){
      String s=c.readString(); if(s!=null) acc+=s;
      if(acc.indexOf("\r\n\r\n")>=0){
        int cl=clen(acc);
        String b=bodyOf(acc);
        if(cl<=0 || (b!=null && b.getBytes(StandardCharsets.UTF_8).length>=cl)) return acc;
      }
    }
    delay(step); waited+=step;
  }
  return (acc.length()>0)?acc:null;
}
int clen(String r){
  String[] ls=split(r,"\r\n");
  for(String line:ls){
    if(line==null) continue;
    String low=line.toLowerCase();
    if(low.startsWith("content-length:")){
      try{ return Integer.parseInt(trim(line.substring(15))); }catch(Exception e){ return 0; }
    }
  }
  return 0;
}
String bodyOf(String r){ int i=r.indexOf("\r\n\r\n"); return (i<0)?null:r.substring(i+4); }
String firstTok(String r){ String[] p=split(r," "); return (p==null||p.length<1)?null:p[0]; }
String secondTok(String r){ String[] p=split(r," "); return (p==null||p.length<2)?null:p[1]; }
Float num(String b,String k){
  int p=b.indexOf(k); if(p<0) return null;
  int c=b.indexOf(':',p); if(c<0) return null;
  String s=b.substring(c+1).trim();
  String n=""; for(int i=0;i<s.length();i++){ char ch=s.charAt(i);
    if((ch>='0'&&ch<='9')||ch=='+'||ch=='-'||ch=='.') n+=ch; else break; }
  if(n.length()==0) return null;
  try{ return Float.parseFloat(n);}catch(Exception e){ return null; }
}
Boolean bool(String b,String k){
  int p=b.indexOf(k); if(p<0) return null;
  int c=b.indexOf(':',p); if(c<0) return null;
  String s=b.substring(c+1).trim().toLowerCase();
  if(s.startsWith("true")||s.startsWith("1")) return true;
  if(s.startsWith("false")||s.startsWith("0")) return false;
  return null;
}

void log(String s){ println(s); hist.add(s); if(hist.size()>HIST_LIMIT) hist.remove(0); }
void safeClose(Client c){ try{ if(c!=null) c.stop(); }catch(Exception e){} }

// ===== port selection helpers =====
String selectInPort(String[] ports, String hint){
  if(hint!=null && hint.length()>0) for(String p:ports) if(p.equalsIgnoreCase(hint)) return p;
  for(String p:ports) if(!p.equalsIgnoreCase("COM1")) return p;
  return null;
}
String selectOutPort(String[] ports, String inPort, String hint){
  if(hint!=null && hint.length()>0){
    if(inPort==null || !hint.equalsIgnoreCase(inPort))
      for(String p:ports) if(p.equalsIgnoreCase(hint)) return p;
  }
  for(String p:ports){
    if(inPort==null || !p.equalsIgnoreCase(inPort)){
      if(!p.equalsIgnoreCase("COM1")) return p;
    }
  }
  return null;
}
