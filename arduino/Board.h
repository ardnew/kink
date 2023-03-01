#ifndef Board_h
#define Board_h

#include <Adafruit_ThinkInk.h>
#include <Adafruit_GFX.h>       
#include <Adafruit_SPIFlash.h>  
#include <Adafruit_ImageReader_EPD.h>
#include <Adafruit_NeoPixel.h>
//#include <FS.h>
//#include <LittleFS.h>

#include "ESP.h" // project file, not from IDF

class Board: public ThinkInk_290_Grayscale4_T5 {
private:
  static const uint8_t _dcPin     = 7;
  static const uint8_t _epdPin    = 8;
  static const uint8_t _busyPin   = 5;
  static const uint8_t _sramPin   = -1;
  static const uint8_t _rstPin    = 6;
  static const uint8_t _spkrEnPin = 16;
  static const uint8_t _spkrPin   = 17;
  static const uint8_t _neoEnPin  = 21;
  static const uint8_t _neoPin    = 1;
  static const uint8_t _vmonPin   = 4;
  static const uint8_t _accIntPin = 9;

  Adafruit_NeoPixel *_neo;
  Adafruit_FlashTransport_SPI *_ftx;
  Adafruit_SPIFlash         _fla;
  Adafruit_ImageReader_EPD  _ird;

public:
  Board(void): 
    ThinkInk_290_Grayscale4_T5(_dcPin, _rstPin, _epdPin, -1, -1),
    _neo(new Adafruit_NeoPixel(4, _neoPin, NEO_GRB + NEO_KHZ800)),
    _ftx(new Adafruit_FlashTransport_SPI(SS1, &SPI1)),
    _fla(new Adafruit_SPIFlash(_ftx)),
    _ird(new Adafruit_ImageReader_EPD(LittleFS)) {

    //UART_INIT(IDF, 115200);
    UART_INIT(DEBUG, 115200);

    pinMode(_busyPin, INPUT);
    pinMode(_neoEnPin, OUTPUT);
    digitalWrite(_neoEnPin, LOW); // on
    _neo->fill(25, 0, 0);
    _neo->show();

    begin(THINKINK_GRAYSCALE4);
    //clearBuffer();
    //setFont();
    //setFont((const GFXfont *)&Barrio_Regular12pt7bBitmaps);
    //setTextSize(1);
    //setTextColor(EPD_BLACK);
    //setCursor(10, 10);
    display();
  }
  void sleep(const bool deep) {
    pinMode(_neoEnPin, OUTPUT);
    pinMode(_spkrEnPin, OUTPUT);
    digitalWrite(_spkrEnPin, LOW); // off
    digitalWrite(_neoEnPin, HIGH); // off
    digitalWrite(_rstPin, LOW); // off (yes required to save a few mA)

    esp_sleep_enable_timer_wakeup(60 * 1000000); // 60 seconds
    esp_deep_sleep_start();    
  }
  bool mountFlash(void) {
    if (!LittleFS.begin(false, "", 10, "spiffs")) {
      _pn("Failed to mount LittleFS partition!");
      return false;
    }
    return true;
  }
  void listDir(const char * dirname, uint8_t levels = 0) {
    _ps("Listing directory: ");
    _pn(dirname);
    File root = LittleFS.open(dirname);
    if (!root) {
      _pn(" - failed to open directory");
      return;
    }
    if (!root.isDirectory()) {
      _pn(" - not a directory");
      return;
    }
    File file = root.openNextFile();
    while (file) {
      if (file.isDirectory()) {
        _ps("  DIR: ");
        _pn(file.name());
        if (levels) {
          listDir(file.path(), levels - 1);
        }
      } else {
        _ps("  FILE: ");
        _ps(file.name());
        _ps(" (");
        _pn(file.size());
        _ps("B)");
      }
      file = root.openNextFile();
    }
  }
  void update(void) {}
};

#endif // Board_h
