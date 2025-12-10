// CarThermo-BT (NTC Version, bridged)
// - UNO + NTC 온도센서 + HC-06
// - 분압 방향 선택 스위치 추가(가열 시 그래프 하강 문제 해결)
// - USB 시리얼(Processing) + 블루투스(HC-06) 동시 전송
// - 임계치 경고 LED/부저 + 설정 명령 처리

#include <SoftwareSerial.h>
#include <math.h>

// ===== 하드웨어 핀 =====
#define PIN_TEMP A0
#define PIN_BUZ  4
#define PIN_LED  5
#define BT_RX    10   // HC-06 TX -> UNO 10
#define BT_TX    11   // HC-06 RX -> UNO 11  (HC-06 RX는 3.3V 권장: 분압 사용)

SoftwareSerial BT(BT_RX, BT_TX);

// ===== NTC 파라미터 =====
const float R_REF = 10000.0;   // 고정저항(분압용) 10kΩ
const float BETA  = 3950.0;    // 센서 베타값 (데이터시트 확인해 조정)
const float T0    = 298.15;    // 25°C in K
const float R0    = 10000.0;   // 25°C에서의 NTC 저항(보통 10kΩ)

// ===== 분압 방향 선택 (배선에 맞춰 true/false 설정) =====
// 대부분의 배선: 위=R_REF–VCC, 아래=NTC–GND 이므로 NTC_TO_GND=true 가 일반적
#define NTC_TO_GND  true   // Vout = 5 * (R_NTC / (R_REF + R_NTC))
#define NTC_TO_VCC  false  // Vout = 5 * (R_REF / (R_REF + R_NTC))
// =======================================================

// ===== 임계치/동작 =====
float T_HI = 40.0;
float T_LO = 0.0;
bool  SILENT = false;

unsigned long lastSend = 0;
const unsigned long INTERVAL = 1000; // 1s

// ==============================

void setup() {
  pinMode(PIN_BUZ, OUTPUT);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_BUZ, LOW);
  digitalWrite(PIN_LED, LOW);

  Serial.begin(9600);   // Processing 브릿지용
  BT.begin(9600);       // HC-06 기본 9600

  String hello = "CarThermo-BT (NTC Version) Ready";
  Serial.println(hello);
  BT.println(hello);
}

void loop() {
  // 1) 주기적으로 온도 측정 & 전송
  if (millis() - lastSend >= INTERVAL) {
    lastSend = millis();
    float t = readTemperature();
    sendTemp(t);

    // 임계치 경고 (사일런트 아닐 때)
    if (!SILENT) {
      if (t > T_HI) {
        digitalWrite(PIN_LED, HIGH);
        tone(PIN_BUZ, 1000, 180);
      } else if (t < T_LO) {
        digitalWrite(PIN_LED, HIGH);
        tone(PIN_BUZ, 600, 180);
      } else {
        digitalWrite(PIN_LED, LOW);
      }
    }
  }

  // 2) 명령 처리 (블루투스/USB 모두 수신)
  if (BT.available()) {
    String cmd = BT.readStringUntil('\n'); cmd.trim();
    if (cmd.length()) processCommand(cmd);
  }
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n'); cmd.trim();
    if (cmd.length()) processCommand(cmd);
  }
}

// ==============================
// 온도 계산 (분압 방향 스위치 반영)

float readTemperature() {
  int adc = analogRead(PIN_TEMP);
  if (adc <= 0)   adc = 1;      // 0 분모 보호
  if (adc >= 1023) adc = 1022;  // 0 분모 보호

  float r_ntc;

  #if NTC_TO_GND
    // 위=R_REF–VCC, 아래=NTC–GND
    // Vout = 5 * (R_NTC / (R_REF + R_NTC)) => R_NTC = R_REF * (ADC / (1023-ADC))
    r_ntc = R_REF * ( (float)adc / (1023.0 - adc) );
  #elif NTC_TO_VCC
    // 위=NTC–VCC, 아래=R_REF–GND
    // Vout = 5 * (R_REF / (R_REF + R_NTC)) => R_NTC = R_REF * ((1023-ADC)/ADC)
    r_ntc = R_REF * ( (1023.0 - adc) / (float)adc );
  #else
    #error "NTC_TO_GND 또는 NTC_TO_VCC 중 하나를 true로 설정하세요."
  #endif

  // Beta 식(단순화된 Steinhart-Hart)
  float tK = 1.0 / ( (1.0 / T0) + (1.0 / BETA) * log(r_ntc / R0) );
  float tC = tK - 273.15;
  return tC;
}

// ==============================
// 전송/명령/설정

void sendTemp(float t) {
  String s = "T," + String(t, 1);
  Serial.println(s);  // Processing 브릿지로
  BT.println(s);      // 스마트폰 블루투스로
}

void sendCfg() {
  String s = String("CFG,HI,") + String(T_HI,1) +
             ",LO," + String(T_LO,1) +
             ",SILENT," + (SILENT ? "1" : "0");
  Serial.println(s);
  BT.println(s);
}

void processCommand(String cmd) {
  if (cmd.startsWith("SET,HI,")) {
    T_HI = cmd.substring(7).toFloat();
    sendCfg();
  } else if (cmd.startsWith("SET,LO,")) {
    T_LO = cmd.substring(7).toFloat();
    sendCfg();
  } else if (cmd.startsWith("SET,SILENT,")) {
    SILENT = cmd.endsWith("1");
    sendCfg();
  } else if (cmd.startsWith("REQ,CFG")) {
    sendCfg();
  } else if (cmd.length()) {
    // 디버그용 에코(선택)
    Serial.println(String("OK: ") + cmd);
    BT.println(String("OK: ") + cmd);
  }
}
