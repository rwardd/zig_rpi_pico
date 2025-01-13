OUTPUT_ARCH("arm")
ENTRY(_start)

MEMORY
{
    FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 2048k
    RAM(rwx)  : ORIGIN = 0x20000000, LENGTH = 256k
}

SECTIONS
{
    .boot2 : ALIGN(4) {
        __boot2_start = .;
        KEEP(*(.boot2))
        __boot2_end = .;
    } > FLASH

    .text : ALIGN(4) {
        __text = .; /* 0x2000000 */
        *(.text*)
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
        __end_text = .;
    } > RAM AT > FLASH

    .data : ALIGN(4) {
        __start_data = .;
        *(.data*)
        . = ALIGN(4);
        __end_data = .;
    } > RAM AT > FLASH

    .bss : ALIGN(4) {
        __start_bss = .;
        *(.bss*)
        . = ALIGN(4);
        __end_bss = .;
    } > RAM

    PROVIDE(__text_start = ORIGIN(FLASH));
    PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
    ASSERT (__boot2_end - __boot2_start == 256, "ERROR: bootloader must be 256 bytes")
}
