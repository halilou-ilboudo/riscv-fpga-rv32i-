CC      = riscv64-unknown-elf-gcc
OBJDUMP = riscv64-unknown-elf-objdump
OBJCOPY = riscv64-unknown-elf-objcopy

ARCH   = -march=rv32i -mabi=ilp32
CFLAGS = $(ARCH) -nostdlib -ffreestanding -fno-builtin \
         -fomit-frame-pointer -fno-stack-protector -mno-save-restore \
         -Wall -Wextra -O0

LDFLAGS = -T linker.ld -Wl,--gc-sections

SRC = timermmio.c start.s
OUT = build/timermmio
all: elf bin dump

elf:
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $(OUT).elf

bin:
	$(OBJCOPY) -O binary $(OUT).elf $(OUT).bin

dump:
	$(OBJDUMP) -d $(OUT).elf > $(OUT).asm

clean:
	rm -f build/*

