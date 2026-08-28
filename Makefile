# Makefile — STM32F103C8T6 步进电机项目
#
# 常用命令：
#   make          编译，生成 build/stepper.elf 和 build/stepper.bin
#   make flash    通过 ST-Link 把程序烧录到开发板
#   make erase    擦除芯片 Flash
#   make reset    复位芯片
#   make clean    清除编译产物

# ---- 工具链 ----
CC      = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE    = arm-none-eabi-size
STFLASH = st-flash

# ---- 目标名 ----
TARGET  = stepper
BUILD   = build

# ---- 编译选项 ----
# -mcpu=cortex-m3 -mthumb : STM32F103 的内核
# -O2 -g                  : 优化级别 2，保留调试信息
# -ffunction-sections...  : 配合 --gc-sections 删掉没用到的函数，减小体积
CFLAGS  = -mcpu=cortex-m3 -mthumb -O2 -g -Wall \
          -ffunction-sections -fdata-sections \
          -fno-common

LDFLAGS = -mcpu=cortex-m3 -mthumb \
          -T STM32F103C8Tx_FLASH.ld \
          -Wl,--gc-sections \
          -Wl,-Map=$(BUILD)/$(TARGET).map \
          --specs=nosys.specs --specs=nano.specs

# ---- 源文件 ----
SRCS = src/main.c startup_stm32f103c8tx.s
OBJS = $(BUILD)/main.o $(BUILD)/startup.o

# ---- 规则 ----
all: $(BUILD)/$(TARGET).bin
	@$(SIZE) $(BUILD)/$(TARGET).elf

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/main.o: src/main.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/startup.o: startup_stm32f103c8tx.s | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/$(TARGET).elf: $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

$(BUILD)/$(TARGET).bin: $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# ---- 烧录（ST-Link，SWD 接口）----
# Flash 起始地址固定为 0x08000000
flash: $(BUILD)/$(TARGET).bin
	$(STFLASH) write $(BUILD)/$(TARGET).bin 0x08000000

erase:
	$(STFLASH) erase

reset:
	$(STFLASH) reset

clean:
	rm -rf $(BUILD)

.PHONY: all flash erase reset clean
