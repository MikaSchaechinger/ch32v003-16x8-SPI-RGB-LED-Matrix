################################################################################
# MRS Version: 1.9.2
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
CPP_SRCS += \
../User/FastMatrix/FastMatrix.cpp 

OBJS += \
./User/FastMatrix/FastMatrix.o 

CPP_DEPS += \
./User/FastMatrix/FastMatrix.d 


# Each subdirectory must supply rules for building sources it contributes
User/FastMatrix/%.o: ../User/FastMatrix/%.cpp
	@	@	riscv-none-embed-g++ -march=rv32ecxw -mabi=ilp32e -msmall-data-limit=0 -msave-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common -Wunused -Wuninitialized  -g -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Debug" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\User" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Core" -I"C:\Users\Mika\Programmieren\Projects\ch32v003-16x8-SPI-RGB-LED-Matrix\Program_ch32v003\Peripheral\inc" -std=gnu++11 -fabi-version=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@	@

