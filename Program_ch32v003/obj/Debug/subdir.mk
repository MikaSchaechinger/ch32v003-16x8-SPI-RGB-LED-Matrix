################################################################################
# MRS Version: 1.9.2
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Debug/debug.c 

C_DEPS += \
./Debug/debug.d 

OBJS += \
./Debug/debug.o 


# Each subdirectory must supply rules for building sources it contributes
Debug/%.o: ../Debug/%.c
	@	@	riscv-none-embed-gcc -march=rv32ecxw -mabi=ilp32e -msmall-data-limit=0 -msave-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common -Wunused -Wuninitialized  -g -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Debug" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Core" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\User" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Peripheral\inc" -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@	@

