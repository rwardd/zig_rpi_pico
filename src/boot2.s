.cpu cortex-m0plus
.thumb

.section .text, "ax"
    push {lr} 
    ldr r2, =0x18000000  /* XIP SSI Base register */
    
    ldr r0, =0x00000000  /* Disable SSI */
    str r0, [r2, #0x08]  /* SSI ENR Offset */

    ldr r0, =0x00000008  /* Set the SSI baud rate */
    str r0, [r2, #0x14]  /* SSI Baud rate offset  */

    ldr r0, =0x001F0300  /* Configure the SSI Controller 0 register */
    str r0, [r2, #0x00]

    ldr r0, =0x03000218  /* Set the SSI SPI controller */
    ldr r1, =0x180000F4  /* Special snowflake address */
    str r0, [r1]

    ldr r0, =0x00000000  /* Configure the SSI Controller 1 register */
    str r0, [r2, #0x04]

    ldr r0, =0x00000001  /* Enable SSI */
    str r0, [r2, #0x08]  /* SSI ENR Offset */

    ldr r0, =0x10000100  /* Load address of Vector table */
    ldr r1, =0xe000ed08 /* VTOR */
    str r0, [r1]

    ldr r1, =0x10000100  /* Load address of Vector table */
    ldr r0, [r1]
    msr msp, r0
    
    ldr r1, =0x10000104  /* Load address of Vector table */
    ldr r2, [r1]
    bx r2

