# 🚗 휴대용 차량 온도 모니터링 시스템  
**Arduino + Processing + WebApp (HTML5)**  

> 실시간 차량 내부 온도를 측정하고, 블루투스를 통해 경보를 울리거나 모바일 웹으로 확인하는 스마트 온도 감지 시스템.

---

## 📘 프로젝트 개요
- **프로젝트명:** CarThermo-BT  
- **목적:** 차량 내부의 온도를 실시간으로 측정하여, 사용자가 스마트폰으로 현재 온도를 확인하고 임계 온도 초과 시 경보를 울릴 수 있도록 함.  
- **특징:**
  - Arduino UNO 기반 온도 감지 (NTC 온도센서)
  - Processing을 이용한 데이터 브릿지 서버
  - 웹앱(HTML/JS)을 통한 시각화 및 임계 온도 설정 기능

---

## 🧩 시스템 구성도
```
[NTC 센서] → [Arduino UNO] ↔ [Processing Bridge] ↔ [WebApp (HTML/JS)]
                                     ↑
                                  스마트폰 브라우저
```

| 구성요소 | 역할 |
|-----------|------|
| Arduino UNO | 온도 측정 및 부저 제어 |
| Processing 서버 (`CarThermoBridgeServer_r4_CORS.pde`) | 아두이노와 웹 간 데이터 브릿지 |
| WebApp (`carthermo_v3.html`) | 실시간 온도 그래프, 임계값 설정, 설정 전송 UI |
| 부저(Buzzer) | 고온/저온 임계값 초과 시 경보음 발생 |

---

## 🔧 아두이노 코드 (`sketch_dec11a.ino`)
- **핵심 기능:**
  - NTC 온도센서(A0)로부터 온도값을 계산
  - Bluetooth 모듈(HC-06) 또는 직렬 통신을 통해 Processing으로 데이터 전송  
  - 설정 명령(`SET,HI,40.0` 등)을 수신해 임계값 변경  
  - 부저 제어 (능동/수동 모두 지원)

```cpp
#define BUZZER_IS_PASSIVE false  // 수동버저면 true, 능동버저면 false
#define PIN_NTC A0
#define PIN_BUZ 4
#define PIN_LED 12
```

- **온도 공식:**
  \[
  T(K) = \frac{1}{\frac{1}{BETA}\ln(\frac{R}{R0}) + \frac{1}{T0}}
  \]
  (10kΩ, Beta=3950 기준)

- **데이터 포맷 예시:**
  ```
  T,26.3
  CFG,HI,40.0,LO,0.0,SILENT,0
  ```

---

## 💻 Processing 브릿지 서버 (`CarThermoBridgeServer_r4_CORS.pde`)
- **역할:**  
  Arduino와 WebApp 간의 중간 다리 역할.  
  Arduino의 데이터를 HTTP API로 변환해줌.

- **API 엔드포인트**
  | 메서드 | 경로 | 설명 |
  |--------|------|------|
  | `GET` | `/api/latest` | 최신 온도 데이터와 설정값 반환 |
  | `GET` | `/api/cfg` | 현재 설정값 반환 |
  | `POST` | `/api/update_cfg` | 웹앱에서 받은 설정값 적용 |
  | `OPTIONS` | 모든 경로 | CORS 프리플라이트 처리 |

- **CORS 대응:**  
  `Access-Control-Allow-Origin: *` 헤더 자동 추가  
  → 웹앱과 포트가 달라도 문제없이 통신 가능

---

## 🌐 웹앱 (`carthermo_v3.html`)
- **기능**
  - 실시간 온도 그래프 표시
  - 임계값 설정 (고온/저온)
  - Silent 모드 제어 (부저 끔)
  - 설정값 전송 및 자동 업데이트

- **UI 구성**
  - 서버 주소 입력 (기본: `http://127.0.0.1:5200`)
  - 현재 온도 표시 및 상태 배지 (정상 / 주의 / 오류)
  - Canvas 그래프
  - 설정값 입력창 및 버튼

---

## ⚙️ 실행 방법
1. **Processing 실행**
   ```bash
   Processing → CarThermoBridgeServer_r4_CORS.pde 실행
   ```
   콘솔에  
   `HTTP server on 5200` 표시 확인.

2. **아두이노 업로드**
   - `sketch_dec11a.ino`를 업로드
   - 센서, LED, 부저 연결 확인 (D4, D12, A0)

3. **웹앱 열기**
   - `carthermo_v3.html`을 브라우저에서 실행  
   - “서버 주소”에 `http://127.0.0.1:5200` 입력 → 적용  
   - 온도 그래프 확인 및 설정값 변경 가능

---

## 🚨 주의사항
- PC와 스마트폰은 반드시 같은 Wi-Fi 네트워크 사용  
- 브라우저에서 “설정 보내기 실패” 시 방화벽에서 Processing 허용 필요  
- Arduino COM 포트 확인 필수 (예: COM3)

---

## 🔮 개선 아이디어
| 기능 | 설명 |
|------|------|
| 🔋 배터리 잔량 측정 | 차량용 배터리 또는 보조 배터리 상태 표시 |
| 🌤 온습도 통합 | DHT22 등으로 확장 |
| 📱 PWA 변환 | 웹앱을 홈화면에 추가하여 앱처럼 실행 |
| ☁️ 클라우드 연동 | Firebase / Thingspeak로 실시간 업로드 |

---

## 📁 파일 구성
```
📦 CarThermo-BT
 ┣ 📄 sketch_dec11a.ino
 ┣ 📄 CarThermoBridgeServer_r4_CORS.pde
 ┗ 🌐 carthermo_v3.html
```
해당 파일은 위 cartemp에 있습니다
---

## 👨‍💻 제작자
- **개발:** 김휘수  
- **마지막 업데이트:** 2025-12-11  
