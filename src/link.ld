OUTPUT_ARCH("arm")
ENTRY(_start)

MEMORY
{
    FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 2048k
    RAM(rwx)  : ORIGIN = 0x20000000, LENGTH = 256k
}

__stack_top = ORIGIN(RAM) + LENGTH(RAM);
__data_dest = ORIGIN(RAM) + 256;
__end_data_dest = __data_dest + (__end_data - __start_data);

SECTIONS
{
    .boot2 : ALIGN(4) {
        __boot2_start = .;
        KEEP(*(.boot2))
        __boot2_end = .;
    } > FLASH

    .flashtext : ALIGN(4) {
        KEEP(*(.vectors*))
    } > FLASH

    .text : ALIGN(4) {
        __text = .;k
        *(.text*)
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
        __end_text = .;
    } > RAM AT> FLASH
    __text_source = LOADADDR(.text);
    . = ALIGN(4);

    .data : ALIGN(4) {
        __start_data = .;
        *(.data*)
        . = ALIGN(4);
        __end_data = .;
    } > RAM AT > FLASH
    __data_source = LOADADDR(.data);
    . = ALIGN(4);

    .bss : ALIGN(4) {
        __start_bss = .;
        *(.bss*)
        . = ALIGN(4);
        __end_bss = .;
    } > RAM

    ASSERT (__boot2_end - __boot2_start == 256, "ERROR: bootloader must be 256 bytes")
}


