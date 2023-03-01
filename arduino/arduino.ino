#include "Board.h"

Board *board;

// Return type of Arduino core function millis()
typedef unsigned long duration_t;

// Turn LED on for ONDUTY ms every PERIOD ms
static duration_t const PERIOD = 1000UL; // 1.0 s
static duration_t const ONDUTY =  100UL; // 0.1 s

// Target device wiring configuration
#define PIN_LED LED_BUILTIN
#define LED_ON  HIGH
#define LED_OFF LOW

void setup() {
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LED_OFF);
  board = new Board();
  if (board->mountFlash()) { 
    board->listDir("/");
    board->listDir("/clean");
    board->listDir("/dirty");
  }
}

void loop() {
  // Static data retained across function calls
  static duration_t sync = 0UL;
  static bool       isOn = false;
  // Data that is computed every function call
  duration_t now = millis();
  duration_t ela = now - sync;
  if (isOn) {
    if (ela >= ONDUTY) {
      digitalWrite(PIN_LED, LED_OFF);
      isOn = false;
    }
  } else {
    if (ela >= PERIOD) {
      digitalWrite(PIN_LED, LED_ON);
      isOn = true;
      sync = now;
    }
  }
}
