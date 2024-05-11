################################################################################
# MRS Version: 1.9.0
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Core/core_riscv.c 

C_DEPS += \
./Core/core_riscv.d 

OBJS += \
./Core/core_riscv.o 


# Each subdirectory must supply rules for building sources it contributes
Core/%.o: ../Core/%.c
	@	@	riscv-none-embed-gcc -march=rv32ecxw -mabi=ilp32e -msmall-data-limit=0 -msave-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common -Wunused -Wuninitialized  -g -I"C:\Users\Mika\Programmieren\MounRiver\Projects\LED-Matrix\Program_ch32v003\Debug" -I"C:\Users\Mika\Programmieren\MounRiver\Projects\LED-Matrix\Program_ch32v003\Core" -I"C:\Users\Mika\Programmieren\MounRiver\Projects\LED-Matrix\Program_ch32v003\User" -I"C:\Users\Mika\Programmieren\MounRiver\Projects\LED-Matrix\Program_ch32v003\Peripheral\inc" -std=gnu99 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@	@

