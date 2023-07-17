/********************************** (C) COPYRIGHT *******************************
 * File Name          : main.cpp
 * Author             : Mika Schaechinger (based on Example from WCH)
 * Version            : V1.1.0
 * Date               : 2023/07/17
 * Description        : Main program body.
 *
 *
 * Example had this license:
 * Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
 * SPDX-License-Identifier: Apache-2.0
 *******************************************************************************/







#include "debug.h"
#include "FastMatrix/FastMatrix.h"

/* Global define */
//#define SPI_DMA
#define TEST_IMAGE

#ifdef TEST_IMAGE
#include "testImage.h"
#endif

/* Global Variable */

uint8_t inputImage[COLOR][HEIGHT][WIDTH];


#define IMAGE_SIZE (COLOR * HEIGHT * WIDTH)
uint8_t buffer0[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];
uint8_t buffer1[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];
uint32_t flag = 0;


FastMatrix matrix(inputImage, buffer0, buffer1);








extern "C" {    // Maybe this is not needed. DMA was not tested yet.
    void DMA1_Channel2_IRQHandler(void);
}

void setup_interrupt(){
    // Setup Interrupts

    NVIC_EnableIRQ(SysTicK_IRQn);
    // SR = Status Register
    SysTick->SR = 0; // &= ~(1 << 0);   // Reset of the LSB -> LSB is the COUNTFLAG-Bit
    SysTick->CMP = MIN_COMP_CLOCK;   // Set Compare Register
    SysTick->CNT = 0;   // Reset the Count Value
    //SysTick->CTLR = 0;  // Reset System Count Control Register
    //SysTick->CTLR |= 0b0010;    // Enabling counter interrupts
    //SysTick->CTLR |= 0b0100;    //  1: HCLK for time base.
                                //  0: HCLK/8 for time base.
    //SysTick->CTLR |= 0b1000;    // Re-counting from 0 after counting up to the comparison value.

    //SysTick->CTLR |= 0b0001;    // Start the system counter STK
    SysTick->CTLR = 0xF;
}



void GPIO_Clock_Init(void){
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOC|RCC_APB2Periph_GPIOD, ENABLE);
}


void DMA_Rx_Init(DMA_Channel_TypeDef *DMA_CHx, u32 ppadr, u32 memadr, u16 bufsize){

    DMA_InitTypeDef DMA_InitStructure = {0};

    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    DMA_DeInit(DMA_CHx);

    DMA_InitStructure.DMA_PeripheralBaseAddr = ppadr;
    DMA_InitStructure.DMA_MemoryBaseAddr = memadr;
    DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralSRC;
    DMA_InitStructure.DMA_BufferSize = bufsize;
    DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
    DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
    DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
    DMA_InitStructure.DMA_Priority = DMA_Priority_High;
    DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA_CHx, &DMA_InitStructure);
}

void SPI_Slave_Init(void){
    GPIO_InitTypeDef GPIO_InitStructure={0};
    SPI_InitTypeDef SPI_InitStructure={0};

    // Enable the High Speed APB (APB2) peripheral clock for SPI
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_SPI1, ENABLE );

    // Setup Clock Pin
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    // Setup MOSI Pin
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Rx;

    SPI_InitStructure.SPI_Mode = SPI_Mode_Slave;

    SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;  // maybe 8Bit ?
    SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;          // 0 = LOW
    SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;        // ???
    SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;               // Slave Select must be always true
    SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
    SPI_InitStructure.SPI_CRCPolynomial = 7;
    SPI_Init( SPI1, &SPI_InitStructure );

    SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Rx, ENABLE);

    SPI_Cmd( SPI1, ENABLE );




}

/*********************************************************************
 * @fn      main
 *
 * @brief   Main program.
 *
 * @return  none
 */
int main(void)
{
    GPIO_Clock_Init();
    matrix.init();
    setup_interrupt();

#ifdef SPI_DMA
    // DMA not tested jet
    SPI_Slave_Init();
    DMA_Rx_Init(DMA1_Channel2, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE);
    DMA_Cmd(DMA1_Channel2, ENABLE);
#endif


    //      1. Check SPI for Errors
    //      2. DMA Timeout
    //      3. CHeck if slave select is True (SPI_NSS_Soft)

#ifdef SPI_DMA
    while(1){
        // Transfer completed Flag
        if( DMA_GetFlagStatus(DMA1_FLAG_TC2) ){
            DMA_ClearFlag(DMA1_FLAG_TC2);
            matrix.newImage();
        }

        // Transmission error
        if( DMA_GetFlagStatus(DMA1_FLAG_TE2) ){
            matrix.testImage();
        }
        // Transmission halfway flag
        if( DMA_GetFlagStatus(DMA1_FLAG_HT2) ){
            matrix.testImage();
        }

    }
#elif defined(TEST_IMAGE)

    greyTest(inputImage);
    matrix.newImage();

    while(1){

    }

#endif



}


// essential for the timer running with cpps
extern "C" {    void SysTick_Handler(void); }

void SysTick_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));  //("WCH-Interrupt-fast")

void SysTick_Handler(void)
{
    SysTick->SR = 0;    // Reset the Status Registers
    //SysTick->CTLR &= ~0b0001;
    matrix.outputRow();
}

