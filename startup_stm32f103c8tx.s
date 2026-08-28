/*
 * startup_stm32f103c8tx.s — STM32F103C8T6 最小启动文件
 *
 * 上电流程：
 *   1. CPU 从 Flash 0 地址读取栈顶地址（_estack）装入 MSP
 *   2. CPU 从 Flash 4 地址读取复位处理函数地址，跳转到 Reset_Handler
 *   3. Reset_Handler 把 .data 段从 Flash 拷到 RAM、把 .bss 段清零
 *   4. 调用 main()
 */

    .syntax unified
    .cpu cortex-m3
    .thumb

/* 由链接脚本提供的符号 */
    .word _sidata   /* .data 段在 Flash 中的起始地址 */
    .word _sdata    /* .data 段在 RAM 中的起始地址 */
    .word _edata    /* .data 段在 RAM 中的结束地址 */
    .word _sbss     /* .bss 段起始 */
    .word _ebss     /* .bss 段结束 */

    .section .text.Reset_Handler
    .weak Reset_Handler
    .type Reset_Handler, %function
Reset_Handler:
    /* 把已初始化的全局变量（.data）从 Flash 复制到 RAM */
    ldr   r0, =_sdata
    ldr   r1, =_edata
    ldr   r2, =_sidata
    movs  r3, #0
CopyLoop:
    ldr   r4, [r2, r3]
    str   r4, [r0, r3]
    adds  r3, r3, #4
    adds  r4, r0, r3
    cmp   r4, r1
    bcc   CopyLoop

    /* 把未初始化的全局变量（.bss）清零 */
    ldr   r2, =_sbss
    ldr   r4, =_ebss
    movs  r3, #0
ZeroLoop:
    str   r3, [r2], #4
    cmp   r2, r4
    bcc   ZeroLoop

    /* 进入 main */
    bl    main
    bx    lr
.size Reset_Handler, .-Reset_Handler

/* 默认异常处理：死循环（初学阶段足够，出异常时停在这里便于调试发现） */
    .section .text.Default_Handler,"ax",%progbits
Default_Handler:
    b     .
.size Default_Handler, .-Default_Handler

/*
 * 中断向量表（Cortex-M3 规定必须放在 Flash 起始处）
 * .weak 让所有中断默认指向 Default_Handler，以后要用哪个中断，
 * 在 C 代码里定义同名函数即可自动替换。
 */
    .section .isr_vector,"a",%progbits
    .type g_pfnVectors, %object
g_pfnVectors:
    .word _estack               /* 0x00 栈顶地址 */
    .word Reset_Handler         /* 0x04 复位 */
    .word NMI_Handler           /* 0x08 */
    .word HardFault_Handler     /* 0x0C */
    .word MemManage_Handler     /* 0x10 */
    .word BusFault_Handler      /* 0x14 */
    .word UsageFault_Handler    /* 0x18 */
    .word 0, 0, 0, 0            /* 0x1C~0x28 保留 */
    .word SVC_Handler           /* 0x2C */
    .word DebugMon_Handler      /* 0x30 */
    .word 0                     /* 0x34 保留 */
    .word PendSV_Handler        /* 0x38 */
    .word SysTick_Handler       /* 0x3C */
    /* 以下为 STM32F103 外设中断（本项目未使用，只保留常用项占位） */
    .word WWDG_IRQHandler
    .word PVD_IRQHandler
    .word TAMPER_IRQHandler
    .word RTC_IRQHandler
    .word FLASH_IRQHandler
    .word RCC_IRQHandler
    .word EXTI0_IRQHandler
    .word EXTI1_IRQHandler
    .word EXTI2_IRQHandler
    .word EXTI3_IRQHandler
    .word EXTI4_IRQHandler
    .word DMA1_Channel1_IRQHandler
    .word DMA1_Channel2_IRQHandler
    .word DMA1_Channel3_IRQHandler
    .word DMA1_Channel4_IRQHandler
    .word DMA1_Channel5_IRQHandler
    .word DMA1_Channel6_IRQHandler
    .word DMA1_Channel7_IRQHandler
    .word ADC1_2_IRQHandler
    .word USB_HP_CAN1_TX_IRQHandler
    .word USB_LP_CAN1_RX0_IRQHandler
    .word CAN1_RX1_IRQHandler
    .word CAN1_SCE_IRQHandler
    .word EXTI9_5_IRQHandler
    .word TIM1_BRK_IRQHandler
    .word TIM1_UP_IRQHandler
    .word TIM1_TRG_COM_IRQHandler
    .word TIM1_CC_IRQHandler
    .word TIM2_IRQHandler
    .word TIM3_IRQHandler
    .word TIM4_IRQHandler
    .word I2C1_EV_IRQHandler
    .word I2C1_ER_IRQHandler
    .word I2C2_EV_IRQHandler
    .word I2C2_ER_IRQHandler
    .word SPI1_IRQHandler
    .word SPI2_IRQHandler
    .word USART1_IRQHandler
    .word USART2_IRQHandler
    .word USART3_IRQHandler
    .word EXTI15_10_IRQHandler
    .word RTC_Alarm_IRQHandler
    .word USBWakeUp_IRQHandler
.size g_pfnVectors, .-g_pfnVectors

/* 所有中断默认指向 Default_Handler */
    .weak NMI_Handler
    .thumb_set NMI_Handler,Default_Handler
    .weak HardFault_Handler
    .thumb_set HardFault_Handler,Default_Handler
    .weak MemManage_Handler
    .thumb_set MemManage_Handler,Default_Handler
    .weak BusFault_Handler
    .thumb_set BusFault_Handler,Default_Handler
    .weak UsageFault_Handler
    .thumb_set UsageFault_Handler,Default_Handler
    .weak SVC_Handler
    .thumb_set SVC_Handler,Default_Handler
    .weak DebugMon_Handler
    .thumb_set DebugMon_Handler,Default_Handler
    .weak PendSV_Handler
    .thumb_set PendSV_Handler,Default_Handler
    .weak SysTick_Handler
    .thumb_set SysTick_Handler,Default_Handler
    .weak WWDG_IRQHandler
    .thumb_set WWDG_IRQHandler,Default_Handler
    .weak PVD_IRQHandler
    .thumb_set PVD_IRQHandler,Default_Handler
    .weak TAMPER_IRQHandler
    .thumb_set TAMPER_IRQHandler,Default_Handler
    .weak RTC_IRQHandler
    .thumb_set RTC_IRQHandler,Default_Handler
    .weak FLASH_IRQHandler
    .thumb_set FLASH_IRQHandler,Default_Handler
    .weak RCC_IRQHandler
    .thumb_set RCC_IRQHandler,Default_Handler
    .weak EXTI0_IRQHandler
    .thumb_set EXTI0_IRQHandler,Default_Handler
    .weak EXTI1_IRQHandler
    .thumb_set EXTI1_IRQHandler,Default_Handler
    .weak EXTI2_IRQHandler
    .thumb_set EXTI2_IRQHandler,Default_Handler
    .weak EXTI3_IRQHandler
    .thumb_set EXTI3_IRQHandler,Default_Handler
    .weak EXTI4_IRQHandler
    .thumb_set EXTI4_IRQHandler,Default_Handler
    .weak DMA1_Channel1_IRQHandler
    .thumb_set DMA1_Channel1_IRQHandler,Default_Handler
    .weak DMA1_Channel2_IRQHandler
    .thumb_set DMA1_Channel2_IRQHandler,Default_Handler
    .weak DMA1_Channel3_IRQHandler
    .thumb_set DMA1_Channel3_IRQHandler,Default_Handler
    .weak DMA1_Channel4_IRQHandler
    .thumb_set DMA1_Channel4_IRQHandler,Default_Handler
    .weak DMA1_Channel5_IRQHandler
    .thumb_set DMA1_Channel5_IRQHandler,Default_Handler
    .weak DMA1_Channel6_IRQHandler
    .thumb_set DMA1_Channel6_IRQHandler,Default_Handler
    .weak DMA1_Channel7_IRQHandler
    .thumb_set DMA1_Channel7_IRQHandler,Default_Handler
    .weak ADC1_2_IRQHandler
    .thumb_set ADC1_2_IRQHandler,Default_Handler
    .weak USB_HP_CAN1_TX_IRQHandler
    .thumb_set USB_HP_CAN1_TX_IRQHandler,Default_Handler
    .weak USB_LP_CAN1_RX0_IRQHandler
    .thumb_set USB_LP_CAN1_RX0_IRQHandler,Default_Handler
    .weak CAN1_RX1_IRQHandler
    .thumb_set CAN1_RX1_IRQHandler,Default_Handler
    .weak CAN1_SCE_IRQHandler
    .thumb_set CAN1_SCE_IRQHandler,Default_Handler
    .weak EXTI9_5_IRQHandler
    .thumb_set EXTI9_5_IRQHandler,Default_Handler
    .weak TIM1_BRK_IRQHandler
    .thumb_set TIM1_BRK_IRQHandler,Default_Handler
    .weak TIM1_UP_IRQHandler
    .thumb_set TIM1_UP_IRQHandler,Default_Handler
    .weak TIM1_TRG_COM_IRQHandler
    .thumb_set TIM1_TRG_COM_IRQHandler,Default_Handler
    .weak TIM1_CC_IRQHandler
    .thumb_set TIM1_CC_IRQHandler,Default_Handler
    .weak TIM2_IRQHandler
    .thumb_set TIM2_IRQHandler,Default_Handler
    .weak TIM3_IRQHandler
    .thumb_set TIM3_IRQHandler,Default_Handler
    .weak TIM4_IRQHandler
    .thumb_set TIM4_IRQHandler,Default_Handler
    .weak I2C1_EV_IRQHandler
    .thumb_set I2C1_EV_IRQHandler,Default_Handler
    .weak I2C1_ER_IRQHandler
    .thumb_set I2C1_ER_IRQHandler,Default_Handler
    .weak I2C2_EV_IRQHandler
    .thumb_set I2C2_EV_IRQHandler,Default_Handler
    .weak I2C2_ER_IRQHandler
    .thumb_set I2C2_ER_IRQHandler,Default_Handler
    .weak SPI1_IRQHandler
    .thumb_set SPI1_IRQHandler,Default_Handler
    .weak SPI2_IRQHandler
    .thumb_set SPI2_IRQHandler,Default_Handler
    .weak USART1_IRQHandler
    .thumb_set USART1_IRQHandler,Default_Handler
    .weak USART2_IRQHandler
    .thumb_set USART2_IRQHandler,Default_Handler
    .weak USART3_IRQHandler
    .thumb_set USART3_IRQHandler,Default_Handler
    .weak EXTI15_10_IRQHandler
    .thumb_set EXTI15_10_IRQHandler,Default_Handler
    .weak RTC_Alarm_IRQHandler
    .thumb_set RTC_Alarm_IRQHandler,Default_Handler
    .weak USBWakeUp_IRQHandler
    .thumb_set USBWakeUp_IRQHandler,Default_Handler
