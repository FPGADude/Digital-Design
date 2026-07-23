#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>

HardwareSerial FpgaSerial(2);

constexpr int FPGA_RX_PIN = 16;
constexpr int FPGA_TX_PIN = 17;
constexpr uint32_t FPGA_UART_BAUD = 115200;
constexpr char AP_SSID[] = "FPGA_TEMP";
constexpr char AP_PASSWORD[] = "fpga1234";
constexpr uint8_t SYNC_BYTE = 0x55;

WebServer server(80);

enum class ReceiveState : uint8_t {
  WaitForSync,
  ReadMsb,
  ReadLsb,
  ReadChecksum
};

ReceiveState receiveState = ReceiveState::WaitForSync;
uint8_t receivedMsb = 0;
uint8_t receivedLsb = 0;

volatile uint16_t latestRawWord = 0;
volatile int16_t latestTemperatureX16 = 0;
volatile uint32_t validPacketCount = 0;
volatile uint32_t checksumErrorCount = 0;
volatile uint32_t lastPacketTimeMs = 0;
volatile bool hasValidData = false;

const char DASHBOARD_HTML[] PROGMEM = R"HTML(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <meta name="theme-color" content="#0d1720">
  <title>FPGA Temperature Monitor</title>
  <style>
    :root {
      --background:#10161d; --panel:#19232d; --panel-soft:#202c37;
      --text:#f2f5f7; --muted:#9eabb5; --good:#45ba76;
      --warn:#d7a642; --bad:#d85c5c; --accent:#4a9bd8; --track:#2b3741;
    }
    * { box-sizing:border-box; }
    body {
      margin:0; min-height:100vh; font-family:Arial,Helvetica,sans-serif;
      background:linear-gradient(180deg,#17212b 0%,var(--background) 36%);
      color:var(--text);
    }
    .page { width:min(94vw,520px); margin:0 auto; padding:20px 0 34px; }
    .brand { text-align:center; margin-bottom:18px; }
    .brand-name { letter-spacing:.18em; font-size:.82rem; font-weight:700; color:var(--accent); }
    .title { margin-top:7px; font-size:1.55rem; font-weight:700; }
    .subtitle { margin-top:6px; font-size:.92rem; color:var(--muted); }
    .card {
      background:rgba(22,38,50,.96); border:1px solid rgba(255,255,255,.06);
      border-radius:18px; box-shadow:0 12px 34px rgba(0,0,0,.32);
    }
    .main-card { padding:25px 20px 22px; text-align:center; }
    .connection-row { display:flex; align-items:center; justify-content:center; gap:8px; color:var(--muted); font-size:.92rem; }
    .status-dot { width:11px; height:11px; border-radius:50%; background:var(--warn); box-shadow:0 0 10px rgba(240,184,75,.75); }
    .temperature { margin-top:20px; font-size:clamp(3.7rem,16vw,5.4rem); line-height:1; font-weight:750; letter-spacing:-.05em; }
    .temperature-unit { font-size:.42em; color:var(--muted); margin-left:4px; vertical-align:18%; letter-spacing:normal; }
    .fahrenheit { margin-top:10px; font-size:1.15rem; color:var(--muted); }
    .bar-labels { display:flex; justify-content:space-between; margin-top:26px; margin-bottom:8px; color:var(--muted); font-size:.72rem; }
    .bar-track { height:16px; overflow:hidden; border-radius:999px; background:var(--track); }
    .bar-fill { height:100%; width:0%; border-radius:999px; background:linear-gradient(90deg,#3d8ec8 0%,#45ba76 48%,#d7a642 75%,#d85c5c 100%); transition:width 650ms cubic-bezier(.22,1,.36,1); }
    .grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:14px; }
    .metric { padding:17px 15px; background:rgba(28,48,62,.96); border:1px solid rgba(255,255,255,.05); border-radius:15px; }
    .metric-label { color:var(--muted); font-size:.78rem; text-transform:uppercase; letter-spacing:.08em; }
    .metric-value { margin-top:9px; font-size:1.25rem; font-weight:700; font-family:"Courier New",monospace; }
    .wide-card { margin-top:14px; padding:17px 18px; }
    .activity-row { display:flex; justify-content:space-between; align-items:center; gap:15px; }
    .activity-title { font-weight:700; }
    .activity-text { margin-top:5px; color:var(--muted); font-size:.84rem; }
    .pulse { width:12px; height:12px; border-radius:50%; background:var(--accent); box-shadow:0 0 12px rgba(76,166,255,.8); opacity:.35; }
    .pulse.active { animation:flash 500ms ease; }
    .metric-value.packet-change { animation:metricFlash 520ms ease; }
    @keyframes flash { 0%{transform:scale(1);opacity:.35} 40%{transform:scale(1.65);opacity:1} 100%{transform:scale(1);opacity:.35} }
    @keyframes metricFlash { 0%{color:var(--text)} 40%{color:var(--accent);transform:scale(1.06)} 100%{color:var(--text);transform:scale(1)} }
    .footer { margin-top:20px; text-align:center; color:#758b99; font-size:.78rem; }
    @media (max-width:370px) { .grid { grid-template-columns:1fr; } }
  </style>
</head>
<body>
  <main class="page">
    <header class="brand">
      <div class="brand-name">FPGA DISCOVERY</div>
      <div class="title">Wi-Fi Temperature Monitor</div>
      <div class="subtitle">Live FPGA sensor data on Android</div>
    </header>

    <section class="card main-card">
      <div class="connection-row">
        <span class="status-dot" id="statusDot"></span>
        <span id="statusText">Waiting for FPGA packets</span>
      </div>

      <div class="temperature">
        <span id="temperatureC">--.--</span><span class="temperature-unit">°C</span>
      </div>
      <div class="fahrenheit"><span id="temperatureF">--.--</span> °F</div>

      <div class="bar-labels"><span>0°C</span><span>25°C</span><span>50°C</span></div>
      <div class="bar-track"><div class="bar-fill" id="temperatureBar"></div></div>
    </section>

    <section class="grid">
      <div class="metric"><div class="metric-label">Raw Sensor Word</div><div class="metric-value" id="rawWord">0x----</div></div>
      <div class="metric"><div class="metric-label">Valid Packets</div><div class="metric-value" id="packetCount">0</div></div>
      <div class="metric"><div class="metric-label">Update Rate</div><div class="metric-value" id="updateRate">0.00 Hz</div></div>
      <div class="metric"><div class="metric-label">Checksum Errors</div><div class="metric-value" id="errorCount">0</div></div>
    </section>

    <section class="card wide-card">
      <div class="activity-row">
        <div>
          <div class="activity-title">Live FPGA Link</div>
          <div class="activity-text" id="lastUpdate">No measurement received yet</div>
        </div>
        <div class="pulse" id="activityPulse"></div>
      </div>
    </section>

    <div class="footer"><strong>FPGA Discovery</strong><br>Cmod A7 • Pmod TMP2 • ESP32</div>
  </main>

  <script>
    let previousPacketCount = -1;
    let displayedCelsius = 0;
    let targetCelsius = 0;
    let animationStarted = false;

    function animateTemperature() {
      if (animationStarted) {
        const difference = targetCelsius - displayedCelsius;
        displayedCelsius =
          Math.abs(difference) < 0.005
            ? targetCelsius
            : displayedCelsius + difference * 0.11;

        document.getElementById('temperatureC').textContent =
          displayedCelsius.toFixed(2);

        document.getElementById('temperatureF').textContent =
          (displayedCelsius * 9.0 / 5.0 + 32.0).toFixed(2);
      }

      requestAnimationFrame(animateTemperature);
    }

    function updateStatus(data) {
      const dot = document.getElementById('statusDot');
      const text = document.getElementById('statusText');

      if (data.connected) {
        dot.style.background = 'var(--good)';
        dot.style.boxShadow = '0 0 10px rgba(69,186,118,.8)';
        text.textContent = 'FPGA connected';
      } else if (data.valid) {
        dot.style.background = 'var(--warn)';
        dot.style.boxShadow = '0 0 10px rgba(215,166,66,.75)';
        text.textContent = 'FPGA data is stale';
      } else {
        dot.style.background = 'var(--bad)';
        dot.style.boxShadow = '0 0 10px rgba(216,92,92,.75)';
        text.textContent = 'Waiting for FPGA packets';
      }
    }

    function flashActivity(count) {
      if (count === previousPacketCount) return;

      const pulse = document.getElementById('activityPulse');
      const counter = document.getElementById('packetCount');

      pulse.classList.remove('active');
      counter.classList.remove('packet-change');
      void pulse.offsetWidth;
      void counter.offsetWidth;
      pulse.classList.add('active');
      counter.classList.add('packet-change');

      previousPacketCount = count;
    }

    function lastUpdateText(ageMs, valid) {
      if (!valid) return 'No measurement received yet';

      const seconds = ageMs / 1000.0;
      if (seconds < 0.1) return 'Last update: just now';
      return 'Last update: ' + seconds.toFixed(1) + ' seconds ago';
    }

    function updateDashboard(data) {
      updateStatus(data);

      if (data.valid) {
        targetCelsius = Number(data.celsius);

        if (!animationStarted) {
          displayedCelsius = targetCelsius;
          animationStarted = true;
        }
      }

      document.getElementById('rawWord').textContent =
        data.valid ? data.raw : '0x----';

      document.getElementById('packetCount').textContent =
        data.packetCount;

      document.getElementById('errorCount').textContent =
        data.checksumErrors;

      document.getElementById('updateRate').textContent =
        Number(data.updateRateHz).toFixed(2) + ' Hz';

      const clamped = Math.max(0, Math.min(50, Number(data.celsius)));
      document.getElementById('temperatureBar').style.width =
        (clamped / 50 * 100) + '%';

      document.getElementById('lastUpdate').textContent =
        lastUpdateText(data.ageMs, data.valid);

      flashActivity(data.packetCount);
    }

    async function fetchData() {
      try {
        const response = await fetch('/data', { cache: 'no-store' });
        if (!response.ok) throw new Error('HTTP ' + response.status);
        updateDashboard(await response.json());
      } catch (error) {
        const dot = document.getElementById('statusDot');
        const text = document.getElementById('statusText');
        dot.style.background = 'var(--bad)';
        dot.style.boxShadow = '0 0 10px rgba(216,92,92,.75)';
        text.textContent = 'ESP32 connection lost';
      }
    }

    requestAnimationFrame(animateTemperature);
    fetchData();
    setInterval(fetchData, 500);
  </script>
</body>
</html>
)HTML";

float temperatureCelsiusFromX16(int16_t temperatureX16) {
  return static_cast<float>(temperatureX16) / 16.0f;
}

float temperatureFahrenheitFromCelsius(float celsius) {
  return (celsius * 9.0f / 5.0f) + 32.0f;
}

String rawWordToHex(uint16_t rawWord) {
  char buffer[7];
  snprintf(buffer, sizeof(buffer), "0x%04X", rawWord);
  return String(buffer);
}

void acceptPacket(uint8_t msb, uint8_t lsb) {
  const uint16_t rawWord = (static_cast<uint16_t>(msb) << 8) | lsb;
  const int16_t temperatureX16 = static_cast<int16_t>(rawWord) >> 3;

  latestRawWord = rawWord;
  latestTemperatureX16 = temperatureX16;
  ++validPacketCount;
  lastPacketTimeMs = millis();
  hasValidData = true;

  Serial.print("Packet ");
  Serial.print(validPacketCount);
  Serial.print("  RAW: ");
  Serial.print(rawWordToHex(rawWord));
  Serial.print("  Temperature: ");
  Serial.print(temperatureCelsiusFromX16(temperatureX16), 2);
  Serial.println(" C");
}

void processFpgaByte(uint8_t value) {
  switch (receiveState) {
    case ReceiveState::WaitForSync:
      if (value == SYNC_BYTE) receiveState = ReceiveState::ReadMsb;
      break;
    case ReceiveState::ReadMsb:
      receivedMsb = value;
      receiveState = ReceiveState::ReadLsb;
      break;
    case ReceiveState::ReadLsb:
      receivedLsb = value;
      receiveState = ReceiveState::ReadChecksum;
      break;
    case ReceiveState::ReadChecksum: {
      const uint8_t expected = SYNC_BYTE ^ receivedMsb ^ receivedLsb;
      if (value == expected) {
        acceptPacket(receivedMsb, receivedLsb);
      } else {
        ++checksumErrorCount;
        Serial.print("Checksum error #");
        Serial.print(checksumErrorCount);
        Serial.print(": received 0x");
        Serial.print(value, HEX);
        Serial.print(", expected 0x");
        Serial.println(expected, HEX);
      }
      receiveState = ReceiveState::WaitForSync;
      break;
    }
  }
}

void serviceFpgaUart() {
  while (FpgaSerial.available() > 0) {
    processFpgaByte(static_cast<uint8_t>(FpgaSerial.read()));
  }
}

void handleDashboard() {
  server.send_P(200, "text/html", DASHBOARD_HTML);
}

void handleData() {
  const uint16_t rawWord = latestRawWord;
  const int16_t temperatureX16 = latestTemperatureX16;
  const uint32_t packetCount = validPacketCount;
  const uint32_t errors = checksumErrorCount;
  const uint32_t packetTime = lastPacketTimeMs;
  const bool valid = hasValidData;

  const uint32_t now = millis();
  const uint32_t ageMs = valid ? now - packetTime : 0;
  const bool connected = valid && ageMs < 3000;
  const float celsius = temperatureCelsiusFromX16(temperatureX16);
  const float fahrenheit = temperatureFahrenheitFromCelsius(celsius);

  static uint32_t previousPacketCount = 0;
  static uint32_t previousRateTimeMs = 0;
  static float updateRateHz = 0.0f;

  if (packetCount != previousPacketCount) {
    if (previousRateTimeMs != 0) {
      const uint32_t elapsed = now - previousRateTimeMs;
      if (elapsed > 0) {
        updateRateHz = 1000.0f * static_cast<float>(packetCount - previousPacketCount) / static_cast<float>(elapsed);
      }
    }
    previousPacketCount = packetCount;
    previousRateTimeMs = now;
  }

  String json;
  json.reserve(240);
  json += "{";
  json += "\"valid\":"; json += valid ? "true" : "false"; json += ",";
  json += "\"connected\":"; json += connected ? "true" : "false"; json += ",";
  json += "\"celsius\":"; json += String(celsius,4); json += ",";
  json += "\"fahrenheit\":"; json += String(fahrenheit,4); json += ",";
  json += "\"raw\":\""; json += rawWordToHex(rawWord); json += "\",";
  json += "\"packetCount\":"; json += String(packetCount); json += ",";
  json += "\"checksumErrors\":"; json += String(errors); json += ",";
  json += "\"updateRateHz\":"; json += String(updateRateHz,4); json += ",";
  json += "\"ageMs\":"; json += String(ageMs);
  json += "}";

  server.send(200, "application/json", json);
}

void handleNotFound() {
  server.send(404, "text/plain", "Not found");
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  FpgaSerial.begin(FPGA_UART_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);

  Serial.println();
  Serial.println("FPGA Connect - Final Polished Dashboard");
  Serial.println("------------------------------------------");

  WiFi.mode(WIFI_AP);
  const bool started = WiFi.softAP(AP_SSID, AP_PASSWORD);
  if (!started) {
    Serial.println("ERROR: Wi-Fi access point failed to start.");
    while (true) delay(1000);
  }

  Serial.print("Wi-Fi network: ");
  Serial.println(AP_SSID);
  Serial.print("Dashboard address: http://");
  Serial.println(WiFi.softAPIP());

  server.on("/", HTTP_GET, handleDashboard);
  server.on("/data", HTTP_GET, handleData);
  server.onNotFound(handleNotFound);
  server.begin();

  Serial.println("Web server started.");
  Serial.println("Waiting for FPGA packets...");
}

void loop() {
  serviceFpgaUart();
  server.handleClient();
}

