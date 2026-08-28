/*
 * STM32F103C8Tx_FLASH.ld — 链接脚本
 * 告诉链接器：程序各部分（代码、数据）放在芯片的哪个地址。
 *
 * STM32F103C8T6 硬件资源：
 *   Flash: 64KB，起始地址 0x08000000（程序烧录到这里）
 *   RAM:   20KB，起始地址 0x20000000（全局变量、栈在这里）
 */

ENTRY(Reset_Handler)   /* 程序入口 */

_estack = 0x20005000;  /* 栈顶 = RAM 末尾（0x20000000 + 20KB），栈向下生长 */

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 20K
}

SECTIONS
{
    /* 中断向量表必须放在 Flash 最开头 */
    .isr_vector :
    {
        . = ALIGN(4);
        KEEP(*(.isr_vector))
        . = ALIGN(4);
    } >FLASH

    /* 代码和只读数据 */
    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
        _etext = .;
    } >FLASH

    /* 已初始化全局变量：运行时住在 RAM，初始值存在 Flash（由启动文件拷贝） */
    _sidata = LOADADDR(.data);
    .data :
    {
        . = ALIGN(4);
        _sdata = .;
        *(.data)
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } >RAM AT> FLASH

    /* 未初始化全局变量：启动时由启动文件清零 */
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } >RAM
}
