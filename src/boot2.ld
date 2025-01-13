MEMORY
{
    SRAM(rx) : ORIGIN = 0x20041f00, LENGTH = 252
}

SECTIONS 
{
    . = ORIGIN(SRAM);
    .text : {
        _start = .;
        *(.text*)
    } > SRAM
}
