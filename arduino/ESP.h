#ifndef ESP_h
#define ESP_h

#define UART_IDF Serial0
#define UART_USB Serial
#define UART_DEBUG UART_USB
#define UART_INIT(x, baud) \
  (UART_ ## x).begin((baud)); \
  while (!(UART_ ## x)) { delay(10); }

#define _ps (UART_DEBUG).print
#define _pn (UART_DEBUG).println
#define _pf (UART_DEBUG).printf

#endif // ESP_h