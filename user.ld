SECTIONS
{
  .text : {
    *(.text*)
  }
  _text_end = .;
  
  .data ALIGN(0x1000) : AT(_text_end) {
    *(.data*)
    *(.rodata*)
    *(.bss*)
  }

  /DISCARD/ : {
    *(.comment)
    *(.debug*)
  }
}