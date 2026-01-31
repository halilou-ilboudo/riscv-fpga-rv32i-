#include <stdint.h>

#define GPIO_OUT (*(volatile uint32_t*)0x80000000u)

int main(void) {
    volatile uint32_t d;
    while (1) {
        GPIO_OUT = 1;
        for (d = 0; d < 2000000; d++) { __asm__ volatile ("nop"); }

        GPIO_OUT = 0;
        for (d = 0; d < 2000000; d++) { __asm__ volatile ("nop"); }
    }
}


