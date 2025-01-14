.cpu cortex-m0plus
.thumb
.align 4

.section .vectors, "ax"
.global __vectors
__vectors:
.balign 4
.word __stack_top
.word _start
.word 0
.word loop

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

;@_start:
;@    ldr r0, =(0x10000000 + 0x100)  /* Load address of Vector table */
;@    ldr r1, =(0xe0000000 + 0xed08) /* VTOR */
;@    str r0, [r1]
;@    ldmia r0, {r0, r1}
;@    msr msp, r0
;@    bx r1

.global _start
.thumb_func
_start:
    /* Copy data from flash to ram */
    ldr r3, =__text_source;
    ldr r4, =__text
    ldr r5, =__end_text
    b text_copy
text_copy_loop:
    ldm r3!, {r0}
    stm r4!, {r0}
text_copy:
    cmp r4, r5
    bne text_copy_loop

begin_data_copy:
    ldr r3, =__data_source
    ldr r4, =__start_data
    ldr r5, =__end_data
    b data_copy
data_copy_loop:
    ldm r3!, {r0}
    stm r4!, {r0}
data_copy:
    cmp r4, r5
    bne data_copy_loop

begin_fill_bss:
    ldr r1, =__start_bss;
    ldr r2, =__end_bss;
    movs r0, #0
    b fill_bss
fill_bss_loop:
    stm r1!, {r0}
fill_bss:
    cmp r1, r2
    bne fill_bss_loop
start_main:
    ldr r0, =start
    bx r0

.thumb_func
loop:
    b loop


