# EMsystem

아두이노 코딩
```
void setup() {
  Serial.begin(9600);
  pinMode(4, INPUT_PULLUP);
}
void loop() {
  int a = digitalRead(4);
  Serial.println(a);
  delay(500);
}

```
서버 코딩
```
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
```

엡 인벤더 

<img width="459" height="548" alt="image" src="https://github.com/user-attachments/assets/8290aa24-b75b-4e66-812f-bdbe72c28b75" />

엡 인밴터 사이트에 들어가 web과 clock을 추가해 줍니다 

<img width="619" height="528" alt="image" src="https://github.com/user-attachments/assets/93ac8cca-eebc-4f66-ba45-0cb76f283a2e" />

위 사진처럼 블록을 만들어 줍니다 블록 설명을 하자면 

<img width="521" height="121" alt="image" src="https://github.com/user-attachments/assets/55706afc-cd08-4afe-83c2-724f6283ebc8" />

스크린에서 제목 부분에 결과값을 출력합니다

<img width="223" height="87" alt="image" src="https://github.com/user-attachments/assets/cf3511a5-a452-4f14-a539-f33be3513b66" />

web에서 일정 시간마다 값을 가져와 줍니다

<img width="527" height="262" alt="image" src="https://github.com/user-attachments/assets/83de4b49-10d8-4770-b2c0-d06021c2a660" />

웹에서 텍스트를 가져왔을 때 만약 재목에 1이 적혀있다면 화면을 붉게 색칠 그게 아니라면 파랗게 색칠하는 코드입니다

이제 다음으로 
<img width="781" height="257" alt="image" src="https://github.com/user-attachments/assets/c0f0deae-7cd5-499e-b898-e4703261f803" />
윈도우 cmd를 열어 ipconfig를 적어 ip번호를 알아줍니다 IPv4 주소 부분이 당신의 ip입니다

<img width="404" height="445" alt="image" src="https://github.com/user-attachments/assets/9ae217b1-481b-429e-b065-d53c82041562" />
ip주소를  web에 url에 적어줍니다 양식은 hhttp:// 000.000.000:12345 이런식으로 적어줍니다 000 부분은 ip 뒤 12345는 포트 번호로 포트번호 입니다.

<img width="1854" height="841" alt="image" src="https://github.com/user-attachments/assets/338f3d11-08c6-42bf-b5e9-4c1c019e870a" />
connect 에서 ai companion 을 눌러줍니다

<img width="398" height="458" alt="image" src="https://github.com/user-attachments/assets/e024d954-e910-48aa-ac97-19a142964b8b" />

mit ai2 companion을 핸드폰 스토어에서 설치 후 qr을 인식해 줍니다.

