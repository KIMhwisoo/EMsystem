# EMsystem

아두이노 코딩

void setup() {
  Serial.begin(9600);
  pinMode(4, INPUT_PULLUP);
}
void loop() {
  int a = digitalRead(4);
  Serial.println(a);
  delay(500);
}


서버 코딩

import processing.serial.*;
import processing.net.*;
Serial p;
Server s;
Client c;
void setup() {
  p = new Serial(this, "COM4", 9600); // 주의1: 포트번호
  s = new Server(this, 12345);
}
String m="0";
void draw() {
  c = s.available();
  if (c!=null) {
    String a = c.readString();
    println(a);
    c.write("HTTP/1.1 200 OK\r\n\r\n");
    c.write(m);
    c.stop();
  }
  if (p.available()>0) {
    String a = p.readString();
    println(a);
    if (a!=null) m = a;
  }
}

<img width="459" height="548" alt="image" src="https://github.com/user-attachments/assets/8290aa24-b75b-4e66-812f-bdbe72c28b75" />
