# STM32F103C8T6 步进电机控制项目

用 STM32F103C8T6（俗称"最小系统板 / Blue Pill"）通过 ULN2003 驱动板控制
28BYJ-48 五线四相步进电机。程序烧录使用 ST-Link V2 仿真器（SWD 接口）。

本项目为**裸机寄存器级**代码，不依赖 HAL 库或标准外设库，适合初学者理解
STM32 的底层工作原理。

## 效果

烧录后电机自动运行：**正转一圈 → 停 1 秒 → 反转一圈 → 停 1 秒 → 循环**。

## 硬件清单

| 物品 | 说明 |
|---|---|
| STM32F103C8T6 最小系统板 | 主控 |
| ST-Link V2 | 烧录器/调试器 |
| ULN2003 驱动板 | 步进电机驱动（带 IN1~IN4 和 4 个指示灯的那种） |
| 28BYJ-48 步进电机 | 5V 五线四相减速步进电机 |
| 杜邦线若干 | 连接用 |

## 接线速查

```
ST-Link        STM32 最小系统板
  SWDIO  ----->  DIO  (SWDIO, 板上排针丝印 DIO/IO)
  SWCLK  ----->  DCLK (SWCLK, 板上排针丝印 DCLK/CLK)
  3.3V   ----->  3.3V
  GND    ----->  GND

STM32          ULN2003 驱动板
  PA1  ----->  IN1
  PA2  ----->  IN2
  PA3  ----->  IN3
  PA4  ----->  IN4
  GND  ----->  "-"（驱动板电源负，必须与 STM32 共地！）

驱动板 "+" 接 5V 电源（可用 ST-Link 的 5V 输出或 USB 5V）
电机白色插头插到驱动板白色插座上
```

详细图文见 [docs/02-硬件接线.md](docs/02-硬件接线.md)。

## 快速开始（3 条命令）

```bash
sudo apt install gcc-arm-none-eabi stlink-tools   # 1. 安装工具（只需一次）
make                                              # 2. 编译
make flash                                        # 3. 烧录（接好 ST-Link 后）
```

烧录成功会看到 `Flash written and verified!`，电机随即开始转动。

## 目录结构

```
├── Makefile                     编译/烧录脚本（make、make flash）
├── STM32F103C8Tx_FLASH.ld       链接脚本（代码存放地址定义）
├── startup_stm32f103c8tx.s      启动文件（上电初始化、中断向量表）
├── src/
│   └── main.c                   主程序（步进电机控制逻辑，全部寄存器级）
└── docs/                        详细教程（按顺序阅读）
    ├── 01-环境搭建.md           从零安装编译器和烧录工具
    ├── 02-硬件接线.md           ST-Link、电机驱动板接线详解
    ├── 03-编译与烧录.md         编译、烧录、擦除、复位的完整说明
    ├── 04-代码讲解.md           逐行讲解代码和步进电机原理，教你怎么改
    └── 05-常见问题.md           报错排查、电机不转/抖动的解决办法
```

## 常用命令一览

| 命令 | 作用 |
|---|---|
| `make` | 编译，生成 `build/stepper.bin` |
| `make flash` | 烧录到开发板 |
| `make erase` | 擦除芯片里的程序 |
| `make reset` | 复位芯片 |
| `make clean` | 删除编译产物，重新来过 |
| `st-info --probe` | 检查 ST-Link 和芯片是否连接正常 |

## 想改转速/转向？

打开 `src/main.c`，改这两个宏然后重新 `make && make flash`：

```c
#define STEPS_PER_REV   4096   /* 一圈的步数 */
#define STEP_DELAY_MS   2      /* 每步间隔毫秒数：改大变慢，改小变快 */
```

更多玩法（按键控制、指定角度、加减速）见
[docs/04-代码讲解.md](docs/04-代码讲解.md)。
# rhino_pi_x1_stm32
