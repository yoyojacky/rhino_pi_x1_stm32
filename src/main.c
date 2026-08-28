/*
 * main.c — STM32F103C8T6 驱动 28BYJ-48 步进电机（ULN2003 驱动板）
 *
 * 接线：PA1~PA4 -> ULN2003 驱动板 IN1~IN4
 * 逻辑：正转一圈 -> 停 1 秒 -> 反转一圈 -> 停 1 秒 -> 循环
 *
 * 本项目不使用 HAL/标准库，直接操作寄存器，方便初学者理解底层原理。
 */

#include <stdint.h>

/* ---------------- 寄存器地址定义（参考 RM0008 参考手册） ---------------- */

/* RCC（复位和时钟控制） */
#define RCC_BASE        0x40021000UL
#define RCC_APB2ENR     (*(volatile uint32_t *)(RCC_BASE + 0x18))  /* APB2 外设时钟使能 */
#define RCC_APB2ENR_IOPAEN   (1UL << 2)   /* GPIOA 时钟使能位 */

/* GPIOA */
#define GPIOA_BASE      0x40010800UL
#define GPIOA_CRL       (*(volatile uint32_t *)(GPIOA_BASE + 0x00)) /* 引脚 0~7 配置寄存器 */
#define GPIOA_BSRR      (*(volatile uint32_t *)(GPIOA_BASE + 0x10)) /* 置位/复位寄存器 */

/* SysTick 系统滴答定时器（用于精确延时） */
#define SYSTICK_BASE    0xE000E010UL
#define SYSTICK_CSR     (*(volatile uint32_t *)(SYSTICK_BASE + 0x00)) /* 控制和状态 */
#define SYSTICK_RVR     (*(volatile uint32_t *)(SYSTICK_BASE + 0x04)) /* 重装载值 */
#define SYSTICK_CVR     (*(volatile uint32_t *)(SYSTICK_BASE + 0x08)) /* 当前值 */

/* STM32F103C8T6 内部 HSI 时钟默认 8MHz，上电后系统时钟就是 8MHz（未配置 PLL） */
#define SYSCLK_HZ       8000000UL

/* ---------------- 步进电机参数 ---------------- */

/* 28BYJ-48 在 8 拍（半步）模式下，输出轴转一圈需要 4096 步 */
#define STEPS_PER_REV   4096

/* 每步之间的延时（毫秒）。数值越小转得越快；28BYJ-48 太小会失步，建议 >= 1 */
#define STEP_DELAY_MS   2

/* 8 拍（半步）励磁顺序：A -> AB -> B -> BC -> C -> CD -> D -> DA
 * 每一位对应一个引脚：bit0=IN1(PA1) bit1=IN2(PA2) bit2=IN3(PA3) bit3=IN4(PA4) */
static const uint8_t step_seq[8] = {
    0x1,  /* 0001 只通 IN1 */
    0x3,  /* 0011 IN1+IN2 */
    0x2,  /* 0010 只通 IN2 */
    0x6,  /* 0110 IN2+IN3 */
    0x4,  /* 0100 只通 IN3 */
    0xC,  /* 1100 IN3+IN4 */
    0x8,  /* 1000 只通 IN4 */
    0x9,  /* 1001 IN4+IN1 */
};

/* ---------------- 基础函数 ---------------- */

/* 用 SysTick 实现毫秒级延时 */
static void delay_ms(uint32_t ms)
{
    /* SysTick 时钟 = 系统时钟 8MHz，计 8000 个数就是 1ms */
    SYSTICK_RVR = (SYSCLK_HZ / 1000UL) - 1UL;
    SYSTICK_CVR = 0;
    /* 使能 SysTick，使用处理器时钟，不开中断（轮询计数标志位） */
    SYSTICK_CSR = (1UL << 0) | (1UL << 2);

    while (ms--) {
        /* 等待 COUNTFLAG（bit16）置 1，表示 1ms 到；读取该位会自动清零 */
        while (!(SYSTICK_CSR & (1UL << 16)))
            ;
    }
    SYSTICK_CSR = 0;  /* 关闭 SysTick */
}

/* 初始化 PA1~PA4 为推挽输出，最大速度 2MHz */
static void gpio_init(void)
{
    /* 1. 打开 GPIOA 的时钟（STM32 所有外设默认无时钟，必须先使能） */
    RCC_APB2ENR |= RCC_APB2ENR_IOPAEN;

    /* 2. 配置 PA1~PA4：
     *    CRL 寄存器中每个引脚占 4 位 [CNF1:CNF0:MODE1:MODE0]
     *    MODE=10（2MHz 输出），CNF=00（通用推挽输出）-> 4 位值 = 0b0010 = 0x2
     *    PA1~PA4 对应 CRL 的第 1~4 个引脚槽位（每个槽位 4bit） */
    for (int pin = 1; pin <= 4; pin++) {
        GPIOA_CRL &= ~(0xFUL << (pin * 4));   /* 先清零该引脚的 4 位配置 */
        GPIOA_CRL |=  (0x2UL << (pin * 4));   /* 写入：2MHz 推挽输出 */
    }
}

/* 输出一步：pattern 的低 4 位写到 PA1~PA4 */
static void motor_write(uint8_t pattern)
{
    /* BSRR 高 16 位写 1 = 引脚清 0，低 16 位写 1 = 引脚置 1
     * 一条语句同时完成置位和复位，避免中间状态 */
    uint32_t bits = (uint32_t)(pattern & 0xF) << 1;      /* 要置 1 的引脚（PA1~PA4） */
    uint32_t mask = (uint32_t)(~pattern & 0xF) << 1;     /* 要清 0 的引脚 */
    GPIOA_BSRR = bits | (mask << 16);
}

/* 让步进电机转动指定步数；dir>0 正转，dir<0 反转 */
static void motor_rotate(int32_t steps, int dir)
{
    static int idx = 0;   /* 当前处于励磁序列的哪一拍，static 保证多次调用间连续 */

    for (int32_t i = 0; i < steps; i++) {
        motor_write(step_seq[idx]);
        idx += (dir > 0) ? 1 : -1;
        if (idx > 7) idx = 0;
        if (idx < 0) idx = 7;
        delay_ms(STEP_DELAY_MS);
    }
}

/* 电机停止：四个线圈全部断电，省电且避免发热（步进电机断电后无保持力矩） */
static void motor_stop(void)
{
    motor_write(0x0);
}

int main(void)
{
    gpio_init();
    motor_stop();

    while (1) {
        motor_rotate(STEPS_PER_REV, +1);   /* 正转一圈 */
        motor_stop();
        delay_ms(1000);                    /* 停 1 秒 */

        motor_rotate(STEPS_PER_REV, -1);   /* 反转一圈 */
        motor_stop();
        delay_ms(1000);                    /* 停 1 秒 */
    }
}
