#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <WiFi.h>
#include <TFT_eSPI.h>
#include <Preferences.h>
#include <HTTPClient.h>
#include "ACS712.h"
#include <ZMPT101B.h>
#include "max6675.h"
#include <ArduinoJson.h>
#include "driver/temp_sensor.h"

#define SENSITIVITY 265.0f

#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define IDENTIFY_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define WIFI_LIST_CHARACTERISTIC_UUID "d1f64a55-6fc3-44ae-9f7a-3d9a4e20e2f7"
#define WIFI_CONNECT_CHARACTERISTIC_UUID "e0b4e907-097b-4081-9a72-dd72ee9f5895"
#define TOKEN_CHARACTERISTIC_UUID "e8d4bbf7-af0d-43b5-8e3f-70a95907db68"

#define tft_BACKLIGHT 38
#define button_buildin 14
#define USE_SERIAL Serial

bool tryconnect = 0;
int lastconnect = 0;
String connectssid = "";
String connectpasswd = "";
int restartCount = 0;
String serverName = "http://sam07205.synology.me:5555/api";
bool isconnto = 0;
String token = "";
String devstatus = "0";
StaticJsonDocument<512> doc;

BLECharacteristic charwifiList(WIFI_LIST_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ);
BLECharacteristic charConnect(WIFI_CONNECT_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
BLECharacteristic charToken(TOKEN_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_READ);

TFT_eSPI tft = TFT_eSPI();

Preferences preferences;

HTTPClient http;

ACS712 ACS1(1, 3.3, 4095, 100);
ACS712 ACS2(2, 3.3, 4095, 100);
ZMPT101B voltageSensor(3, 60.0);
MAX6675 thermocouple(12, 10, 11);

String httpGETRequest(const char *serverName)
{
  HTTPClient http;

  // Your IP address with path or Domain name with URL path
  http.begin(serverName);

  // If you need Node-RED/server authentication, insert user and password below
  // http.setAuthorization("REPLACE_WITH_SERVER_USERNAME", "REPLACE_WITH_SERVER_PASSWORD");

  // Send HTTP POST request
  int httpResponseCode = http.GET();

  String payload = "";

  if (httpResponseCode > 0)
  {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    payload = http.getString();
  }
  else
  {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  // Free resources
  http.end();

  return payload;
}
String httpPOSTRequest(const char *serverName, const char *parm)
{
  HTTPClient http;

  // Your IP address with path or Domain name with URL path
  http.begin(serverName);

  // If you need Node-RED/server authentication, insert user and password below
  // http.setAuthorization("REPLACE_WITH_SERVER_USERNAME", "REPLACE_WITH_SERVER_PASSWORD");

  // Send HTTP POST request
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  int httpResponseCode = http.POST(parm);

  String payload = "";

  if (httpResponseCode > 0)
  {
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    payload = http.getString();
  }
  else
  {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  // Free resources
  http.end();

  return payload;
}

void register_device()
{

  tft.fillScreen(TFT_BLACK);
  tft.setCursor(0, 0);
  tft.setTextColor(TFT_WHITE);
  tft.setTextSize(4);
  tft.print("REGG..");
  tft.setTextSize(2);
  tft.setCursor(0, 50);
  tft.print("TOKEN: Getting..");
  tft.setCursor(0, 80);
  tft.print("RESP:");

  token = preferences.getString("DEVICE_TOKEN", "");
  if (token == "")
  {
    String serverNameTok = serverName + "/gentoken";
    token = httpGETRequest(serverNameTok.c_str());
    preferences.putString("DEVICE_TOKEN", token);
  }

  tft.fillScreen(TFT_BLACK);
  tft.setCursor(0, 0);
  tft.setTextColor(TFT_WHITE);
  tft.setTextSize(4);
  tft.print("REGG..");
  tft.setTextSize(2);
  tft.setCursor(0, 50);
  tft.print("TOKEN:");

  if (token.length() > 0)
  {
    tft.print(token.substring(0, 5));
    tft.print("...");
    tft.setCursor(0, 80);
    tft.print("RESP: Getting..");
  }
  else
  {
    tft.print("ERR");
    tft.print("...");
    tft.setCursor(0, 80);
    tft.print("RESP: Abort!");
    return;
  }
  charToken.setValue(token.c_str());

  String httpRequestData = "token=" + token + "&type=PLUGDUAL";
  String serverPath = serverName + "/register?"; // serverName + "/register"
  String respond = httpPOSTRequest(serverPath.c_str(), httpRequestData.c_str());

  tft.fillScreen(TFT_BLACK);
  tft.setCursor(0, 0);
  tft.setTextColor(TFT_WHITE);
  tft.setTextSize(4);
  tft.print("REGG");
  tft.setTextSize(2);
  tft.setCursor(0, 50);
  tft.print("TOKEN:");
  tft.print(token.substring(0, 5));
  tft.print("...");
  tft.setCursor(0, 80);
  tft.print("RESP:");
  Serial.println(respond);
  if (respond.length() > 0)
  {

    DeserializationError error = deserializeJson(doc, respond);
    const char *setting_name = doc["setting"]["name"];
    if (error)
    {
      tft.print("ERR");
      return;
    }
    tft.print(setting_name);
  }
  else
  {
    tft.print("ERR");
    return;
  }
  http.end();
  delay(1000);
  isconnto = 1;
}

bool isbleconn = 0;

class ConnectCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    String value = pCharacteristic->getValue().c_str();
    pCharacteristic->setValue("DISCONNECTED");

    String getssid = value.substring(0, value.indexOf('\n'));
    connectssid = getssid;

    String getpasswd = value.substring(value.indexOf('\n') + 1, value.length());
    connectpasswd = getpasswd;

    tft.fillScreen(TFT_BLACK);
    tft.setCursor(0, 0);
    tft.setTextColor(TFT_WHITE);
    tft.setTextSize(4);
    tft.print("CONN..");
    tft.setTextSize(2);
    tft.setCursor(0, 50);
    tft.print("SSID:");
    tft.print(connectssid.length() <= 15 ? connectssid.substring(0, 15) : connectssid.substring(0, 15) + "...");
    tft.setCursor(0, 80);
    tft.print("PASSWD:");
    for (int xx = 0; xx <= connectpasswd.length() && xx <= 15; xx++)
      tft.print("*");

    WiFi.disconnect();

    tryconnect = 1;
    isbleconn = 1;
    lastconnect = millis();
    WiFi.begin(connectssid, connectpasswd);
  }
};

String getWifiList()
{
  String wifiListString = "";
  int n = WiFi.scanNetworks();
  Serial.println(n);
  for (int i = 0; i < n; i++)
  {
    wifiListString += WiFi.SSID(i) + "\n" + String(WiFi.RSSI(i)) + "\n";
  }
  Serial.println(wifiListString);

  return wifiListString;
}

void socket_Connected(const char *payload, size_t length)
{
  Serial.println("Socket.IO Connected!");
}

void setup()
{
  Serial.begin(115200);
  tft.init();
  tft.setRotation(3);
  tft.fillScreen(TFT_BLACK);
  tft.setCursor(0, 0);
  tft.setTextColor(TFT_WHITE);
  tft.setTextSize(4);
  preferences.begin("restart", false);
  restartCount = preferences.getInt("count", 0);
  if (restartCount >= 5)
  {
    tft.print("Factory Reset");
    restartCount = 0;
    preferences.putInt("count", restartCount);
    connectssid = "";
    connectpasswd = "";
    preferences.putString("WIFI_SSID", connectssid);
    preferences.putString("WIFI_PASSWD", connectpasswd);
    preferences.putString("DEVICE_TOKEN", "");
    tft.setTextSize(2);
    tft.setCursor(0, 50);
    tft.print("OK");
  }
  else
  {
    tft.print("Starting..");
    // restartCount &&tft.print(restartCount);
    restartCount &&tft.print(restartCount);
    restartCount += 1;
    preferences.putInt("count", restartCount);
  }

  pinMode(tft_BACKLIGHT, OUTPUT);
  digitalWrite(tft_BACKLIGHT, 1);
  delay(2000);
  preferences.putInt("count", 0);

  connectssid = preferences.getString("WIFI_SSID", "");
  connectpasswd = preferences.getString("WIFI_PASSWD", "");

  tft.fillScreen(TFT_BLACK);
  tft.setCursor(0, 0);
  tft.setTextSize(4);

  if (connectpasswd.length() != 0)
  {
    tft.fillScreen(TFT_BLACK);
    tft.setCursor(0, 0);
    tft.setTextColor(TFT_WHITE);
    tft.setTextSize(4);
    tft.print("CONN..");
    tft.setTextSize(2);
    tft.setCursor(0, 50);
    tft.print("SSID:");
    tft.print(connectssid.length() <= 15 ? connectssid.substring(0, 15) : connectssid.substring(0, 15) + "...");
    tft.setCursor(0, 80);
    tft.print("PASSWD:");
    for (int xx = 0; xx <= connectpasswd.length() && xx <= 15; xx++)
      tft.print("*");

    WiFi.disconnect();

    tryconnect = 1;
    lastconnect = millis();
    WiFi.begin(connectssid, connectpasswd);
  }
  else
  {
    tft.print("SETUP..");
  }

  BLEDevice::init("ESP32");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Identify Characteristic
  BLECharacteristic *charIdentify = pService->createCharacteristic(
      IDENTIFY_CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ);
  // charIdentify->setCallbacks(new MyCallbacks());
  charIdentify->setValue("ESP32 SMART PLUG");

  pService->addCharacteristic(&charwifiList);
  charwifiList.setValue(getWifiList().c_str());

  pService->addCharacteristic(&charConnect);
  charConnect.setValue("DISCONNECTED");
  charConnect.setCallbacks(new ConnectCallbacks());

  pService->addCharacteristic(&charToken);
  charConnect.setValue("");

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // functions for iPhone connection
  pAdvertising->setMinPreferred(0x12);

  if (tryconnect == 0)
  {
    BLEDevice::startAdvertising();
    Serial.println("Characteristics defined! BLE Server Ready");
  }

  WiFi.mode(WIFI_STA);
  pinMode(button_buildin, INPUT);

  ACS1.autoMidPoint();
  ACS2.autoMidPoint();
  voltageSensor.setSensitivity(SENSITIVITY);

  pinMode(21, OUTPUT);
  pinMode(16, OUTPUT);

  temp_sensor_config_t temp_sensor = TSENS_CONFIG_DEFAULT();
  temp_sensor.dac_offset = TSENS_DAC_L2;  //TSENS_DAC_L2 is default   L4(-40℃ ~ 20℃), L2(-10℃ ~ 80℃) L1(20℃ ~ 100℃) L0(50℃ ~ 125℃)
  temp_sensor_set_config(temp_sensor);
  temp_sensor_start();
}

long lastscanwifi = -5000;
long lastupdatestat = -2000;
bool isoffine = 0;
bool iserrconn = 0;
bool last_button_buildin_status = 1;
long last_button_buildin = -100;
String digitcode = "";
long lastshowdigitcode = 0;

int current1 = random(500, 2000);
int current2 = random(500, 2000);
float voltage = random(100, 120);
float tempture = random(20, 25);

void loop()
{
  float tsens_out;
  temp_sensor_read_celsius(&tsens_out); 
  // Serial.println(tsens_out);
   current1 = ACS1.mA_AC(60, 10);
   current2 = ACS2.mA_AC(60, 10);
   voltage = voltageSensor.getRmsVoltage();
   tempture = thermocouple.readCelsius();
  // current1 = random(500, 2000);
  // current2 = random(500, 2000);
  // voltage = random(100, 120);
  // tempture = random(20, 25);
  if (std::isnan(tempture)) tempture = 0;

  if (tryconnect == 1)
  {
    if (iserrconn)
    {
      if (millis() - lastconnect >= 15000)
      {
        WiFi.begin(connectssid, connectpasswd);
        tft.fillScreen(TFT_BLACK);
        tft.setCursor(0, 0);
        tft.setTextColor(TFT_WHITE);
        tft.setTextSize(4);
        tft.print("CONN..");
        tft.setTextSize(2);
        tft.setCursor(0, 50);
        tft.print("SSID:");
        tft.print(connectssid.length() <= 15 ? connectssid.substring(0, 15) : connectssid.substring(0, 15) + "...");
        tft.setCursor(0, 80);
        tft.print("PASSWD:");
        for (int xx = 0; xx <= connectpasswd.length() && xx <= 15; xx++)
          tft.print("*");
        lastconnect = millis();
        iserrconn = 0;
      }
    }
    else if (millis() - lastconnect >= 10000)
    {
      WiFi.disconnect();
      if (isbleconn)
      {
        tryconnect = 0;
      }
      tft.fillScreen(TFT_BLACK);
      tft.setCursor(0, 0);
      tft.setTextColor(TFT_WHITE);
      tft.setTextSize(4);
      tft.print("ERR CONN");
      tft.setTextSize(2);
      tft.setCursor(0, 50);
      tft.print("SSID:");
      tft.print(connectssid.length() <= 15 ? connectssid.substring(0, 15) : connectssid.substring(0, 15) + "...");
      tft.setCursor(0, 80);
      tft.print("PASSWD:");
      for (int xx = 0; xx <= connectpasswd.length() && xx <= 15; xx++)
        tft.print("*");
      iserrconn = 1;
    }

    // digitalWrite(38,((millis() - lastconnect) / 500) % 2);
    if (WiFi.status() == WL_CONNECTED)
    {
      charConnect.setValue("CONNECTED");
      tryconnect = 0;
      tft.fillScreen(TFT_BLACK);
      tft.setCursor(0, 0);
      tft.setTextColor(TFT_WHITE);
      tft.setTextSize(4);
      tft.print("CONNED");
      tft.setTextSize(2);
      tft.setCursor(0, 50);
      tft.print("SSID:");
      tft.print(connectssid.length() <= 15 ? connectssid.substring(0, 15) : connectssid.substring(0, 15) + "...");
      tft.setCursor(0, 80);
      tft.print("PASSWD:");
      for (int xx = 0; xx <= connectpasswd.length() && xx <= 15; xx++)
        tft.print("*");
      if (isbleconn)
      {
        preferences.putString("WIFI_SSID", connectssid);
        preferences.putString("WIFI_PASSWD", connectpasswd);
      }
      delay(1000);
      register_device();
    }
  }

  if (WiFi.status() == WL_DISCONNECTED && millis() - lastscanwifi > 5000)
  {
    charwifiList.setValue(getWifiList().c_str());
    lastscanwifi = millis();
  }

  if (isconnto)
  {
    // 如果經連線至伺服器註冊
    if (millis() - lastupdatestat > 1000)
    {
      if (isoffine)
      {
        // 如果中途斷線
        if (WiFi.status() == WL_CONNECTED)
        {
          if (httpGETRequest(serverName.c_str()) == "alive")
          {
            // 恢復連線
            register_device();
            isoffine = 0;
          }
          else
          {
            // Wifi連線中但server離線
            tft.fillScreen(TFT_BLACK);
            tft.setCursor(0, 0);
            tft.setTextColor(TFT_WHITE);
            tft.setTextSize(4);
            tft.print("SERVER OFFINE");
            tft.setTextSize(2);
            if (devstatus == "0")
            {
              tft.print("ON ON");
            }
            else if (devstatus == "1")
            {
              tft.print("OFF OFF");
            }
            else if (devstatus == "2")
            {
              tft.print("ON OFF");
            }
            else if (devstatus == "3")
            {
              tft.print("OFF ON");
            }
            tft.setCursor(0, 70);
            tft.print("Voltage: ");
            tft.print(voltage);
            tft.print(" V");
            tft.setCursor(0, 90);
            tft.print("Watt 1: ");
            tft.print(voltage * current1 * 0.001);
            tft.print(" W");
            tft.setCursor(0, 110);
            tft.print("Watt 2: ");
            tft.print(voltage * current2 * 0.001);
            tft.print(" W");
            tft.setCursor(0, 130);
            tft.print("Tempture: ");
            if (tempture >= 35)
            {
              tft.setTextColor(TFT_RED);
            }
            else
            {
              tft.setTextColor(TFT_WHITE);
            }
            tft.print(tempture);
            tft.print(" *C");
            tft.setTextColor(TFT_WHITE);
            lastupdatestat = millis();
          }
        }
        else
        {
          // Wifi斷線
          tft.fillScreen(TFT_BLACK);
          tft.setCursor(0, 0);
          tft.setTextColor(TFT_WHITE);
          tft.setTextSize(4);
          tft.print("WIFI DISCONN");
          tft.setTextSize(2);
          tft.setCursor(0, 50);
          tft.print("Status: ");
          if (devstatus == "0")
          {
            tft.print("ON ON");
          }
          else if (devstatus == "1")
          {
            tft.print("OFF OFF");
          }
          else if (devstatus == "2")
          {
            tft.print("ON OFF");
          }
          else if (devstatus == "3")
          {
            tft.print("OFF ON");
          }

          tft.setCursor(0, 70);
          tft.print("Voltage: ");
          tft.print(voltage);
          tft.print(" V");
          tft.setCursor(0, 90);
          tft.print("Watt 1: ");
          tft.print(voltage * current1 * 0.001);
          tft.print(" W");
          tft.setCursor(0, 110);
          tft.print("Watt 2: ");
          tft.print(voltage * current2 * 0.001);
          tft.print(" W");
          tft.setCursor(0, 130);
          tft.print("Tempture: ");
          if (tempture >= 35)
          {
            tft.setTextColor(TFT_RED);
          }
          else
          {
            tft.setTextColor(TFT_WHITE);
          }
          tft.print(tempture);
          tft.print(" *C");
          tft.setTextColor(TFT_WHITE);
          lastupdatestat = millis();
        }
      }
      else if (WiFi.status() == WL_CONNECTED)
      {
        current1 = current1 >= 35 ? current1 : 0;
        current2 = current2 >= 35 ? current2 : 0;
        voltage = voltage >= 50 ? voltage : 0;

        if (tempture > 35)
        {
          String httpRequestData = "token=" + token + "&status=2";
          String pathupdate = serverName + "/setstat?";
          httpPOSTRequest(pathupdate.c_str(), httpRequestData.c_str());
          devstatus = "1";
        }

        String httpRequestData = "token=" + token + "&data={\"voltage\":" + String(voltage, 2) + ",\"temp\":" + String(tempture, 2) + ",\"current1\":" + current1 + ",\"current2\":" + current2 += "}";

        String pathupdate = serverName + "/update?";

        String rest = httpPOSTRequest(pathupdate.c_str(), httpRequestData.c_str());
        if (rest == "UPD")
        {
          register_device();
        }
        else
        {
          devstatus = rest;
        }

        if (devstatus != "")
        {
          tft.fillScreen(TFT_BLACK);
          tft.setCursor(0, 0);
          tft.setTextColor(TFT_WHITE);
          tft.setTextSize(4);
          const char *setting_name = doc["setting"]["name"];

          tft.print(setting_name ? setting_name : "Device");

          tft.setTextSize(2);
          tft.setCursor(0, 50);
          tft.print("Status: ");

          if (devstatus == "0")
          {
            tft.print("ON ON");
          }
          else if (devstatus == "1")
          {
            tft.print("OFF OFF");
          }
          else if (devstatus == "2")
          {
            tft.print("ON OFF");
          }
          else if (devstatus == "3")
          {
            tft.print("OFF ON");
          }

          tft.setCursor(0, 70);
          tft.print("Voltage: ");
          tft.print(voltage);
          tft.print(" V");
          tft.setCursor(0, 90);
          tft.print("Watt 1: ");
          tft.print(voltage * current1 * 0.001);
          tft.print(" W");
          tft.setCursor(0, 110);
          tft.print("Watt 2: ");
          tft.print(voltage * current2 * 0.001);
          tft.print(" W");
          tft.setCursor(0, 130);
          tft.print("Tempture: ");
          if (tempture >= 35)
          {
            tft.setTextColor(TFT_RED);
          }
          else
          {
            tft.setTextColor(TFT_WHITE);
          }
          tft.print(tempture);
          tft.print(" *C");
          tft.setTextColor(TFT_WHITE);
          tft.setCursor(0, 150);
          if (digitcode != "" && millis() - lastshowdigitcode <= 60000)
          {
            tft.print("Pair Code: ");
            tft.print(digitcode);
          }

          lastupdatestat = millis();
        }
        else
        {
          isoffine = 1;
        }
      }
      else
      {

        isoffine = 1;
      }
    }

    if (WiFi.status() == WL_CONNECTED)
    {
      if (last_button_buildin_status != digitalRead(button_buildin))
      {
        if (millis() - last_button_buildin >= 100)
        {
          if (last_button_buildin_status == LOW)
          {
            last_button_buildin = millis();
            String httpRequestData = "token=" + token;
            String pathupdate = serverName + "/reqdigit?";
            digitcode = httpPOSTRequest(pathupdate.c_str(), httpRequestData.c_str());
            lastshowdigitcode = millis();
          }
          last_button_buildin_status = digitalRead(button_buildin);
        }
      }
    }
  }
  if (tempture <= 35)
  {
    if (devstatus == "0")
    {
      digitalWrite(16, 0);
      digitalWrite(21, 0);
    }
    else if (devstatus == "1")
    {
      digitalWrite(16, 1);
      digitalWrite(21, 1);
    }
    else if (devstatus == "2")
    {
      digitalWrite(16, 0);
      digitalWrite(21, 1);
    }
    else if (devstatus == "3")
    {
      digitalWrite(16, 1);
      digitalWrite(21, 0);
    }
  }
  else
  {
    digitalWrite(16, 1);
    digitalWrite(21, 1);
  }
}
