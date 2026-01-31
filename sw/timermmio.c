#include <stdint.h>

#define GPIO_OUT   (*(volatile uint32_t*)0x80000000u)
#define TIMER_TIME (*(volatile uint32_t*)0xA0000000u)   // adapte si besoin

int main(void){
  while(1){
    uint32_t t = TIMER_TIME;
    GPIO_OUT = (t >> 20) & 0xFF;   // on affiche un morceau du timer
  }
}

