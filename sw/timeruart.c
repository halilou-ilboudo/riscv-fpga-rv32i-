#include "uart.h"

int main(void) {
  uart_puts("Timer test...\n");
  while (1) {
    uart_puts("tick\n");
    delay_us(500000); // 0.5 s
  }
}

