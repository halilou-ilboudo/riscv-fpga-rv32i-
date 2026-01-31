ENTRY(_start)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
  . = 0x00000000;

  .text : { *(.text*) } > RAM
  .data : { *(.data*) } > RAM
  .bss  : { *(.bss*)  } > RAM
}

