#pragma once
#include <stdint.h>

#define UART_BASE      0x90000000u
#define UART_DATA      (*(volatile uint32_t*)(UART_BASE + 0x0))
#define UART_STATUS    (*(volatile uint32_t*)(UART_BASE + 0x4))
#define UART_TX_BUSY() (UART_STATUS & 1u)

static inline void uart_putc(char c) {
  while (UART_TX_BUSY()) { }
  UART_DATA = (uint32_t)(uint8_t)c;
}

static inline void uart_puts(const char *s) {
  while (*s) {
    if (*s == '\n') uart_putc('\r');
    uart_putc(*s++);
  }
}

