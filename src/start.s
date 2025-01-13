.cpu cortex-m0plus
.thumb

.section .vectors, "ax"
.align 2
.global __vectors
__vectors:
.word __stack_top
.word _reset_handler
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0
.word 0

.section .reset, "ax"
_reset_handler:
    /* Copy data from flash to ram */
    ldr r3, =__text_start
    ldr r4, =__text
    ldr r5, =__end_data;
    b data_copy

data_copy_loop:
    ldm r3!, {r0}
    stm r4!, {r0}
data_copy:
    cmp r4, r5
    bne data_copy_loop

    ldr r1, =__start_bss;
    ldr r2, =__end_bss;
    movs r0, #0
    b fill_bss
fill_bss_loop:
    stm r1!, {r0}
fill_bss:
    cmp r1, r2
    bne fill_bss_loop

    ldr r0, =start
    bx r0



