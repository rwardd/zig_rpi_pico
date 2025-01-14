MEMORY
{
    FLASH(rx) : ORIGIN = 0x10000000, LENGTH = 2048k
}

SECTIONS 
{
    .text : {
        . = ORIGIN(FLASH);
        _start = .;
        KEEP(*(.text*))
    } > FLASH
}
