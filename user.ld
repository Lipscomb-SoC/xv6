ENTRY(main)

SECTIONS
{
  . = 0x0000;        /* starting VA */

  .text : {
    *(.text*)
  }
  _text_end = .;

  .data ALIGN(0x1000) : AT(_text_end) {
    *(.data*)
    *(.rodata*)
    *(.bss*)
  }
  _end = .;

  /DISCARD/ : {
    *(.comment)
    *(.debug*)
  }
}