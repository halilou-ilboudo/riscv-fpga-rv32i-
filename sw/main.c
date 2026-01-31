#define LED_ADDR 0x80000000

int main(void)
{
   volatile unsigned int *gpio = (unsigned int*)0x80000000;

   *gpio = 0x10;   // Allumer la LED

    while (1) {
   
        // boucle infinie
    }

    return 0;
}
