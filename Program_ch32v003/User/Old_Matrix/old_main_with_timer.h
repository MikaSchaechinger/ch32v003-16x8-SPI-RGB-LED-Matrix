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
#define SPI_DMA
//#define TEST_IMAGE

/* Select Timer */
#define SYSTICK_TIMER
//#define TIMER1
//#define TIMER2

#ifdef TEST_IMAGE
#include "testImage.h"
#endif

#define ever ;;

#define IMAGE_SIZE (COLOR * HEIGHT * WIDTH)
/* Global Variable */

// SRAM 0x2000 0000 to 0x2000 0800
uint8_t inputImage[COLOR][HEIGHT][WIDTH];           // 0x2000 0404
uint8_t buffer0[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];  // 0x2000 0004
uint8_t buffer1[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];  // 0x2000 0204
//uint32_t flag = 0;

uint32_t spi_data = 0;
uint32_t data_address;

FastMatrix matrix(inputImage, buffer0, buffer1);








extern "C" {    // Maybe this is not needed. DMA was not tested yet.
    void DMA1_Channel2_IRQHandler(void);
}



void setup_interrupt(){
    // Setup Interrupts

#ifdef SYSTICK_TIMER
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
#elif defined TIMER1

    TIM_Cmd(TIM1, DISABLE);
    NVIC_InitTypeDef NVIC_InitStructure;
    TIM_TimeBaseInitTypeDef TIM_TimeBaseInitStructure;

    // Clock f¨¹r TIM1 aktivieren
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1|RCC_APB2Periph_GPIOC|RCC_APB2Periph_GPIOD, ENABLE);

    // Timer-Interrupt configure
    NVIC_InitStructure.NVIC_IRQChannel = TIM1_UP_IRQn; // TIM1 Update Interrupt
    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = NVIC_PriorityGroup_1;
    NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
    NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_InitStructure);

    // Timer-Konfiguration
    TIM_TimeBaseInitStructure.TIM_Period = 0x7FFF; /* Setze den Auto-Reload-Wert */
    TIM_TimeBaseInitStructure.TIM_Prescaler = 1; /* Setze den Prescaler */
    TIM_TimeBaseInitStructure.TIM_ClockDivision = TIM_CKD_DIV4;
    TIM_TimeBaseInitStructure.TIM_CounterMode = TIM_CounterMode_Up;
    TIM_TimeBaseInitStructure.TIM_RepetitionCounter = 0;
    TIM_TimeBaseInit(TIM1, &TIM_TimeBaseInitStructure);

//
//    TIM_OCInitTypeDef TIM_OCInitTypeStructure;
//    TIM_OCInitTypeStructure.TIM_OCMode = TIM_OCMode_Timing;
//    TIM_OCInitTypeStructure.TIM_OCNPolarity = 0;



    // Timer-Interrupt f¨¹r Update aktivieren
    TIM_ITConfig(TIM1, TIM_IT_Update, ENABLE);   // Works with "TIM1_UP_IRQHandler"
    //TIM_ITConfig(TIM1, TIM_CC1IE, ENABLE);


    TIM1->CNT = 0;
    // Timer starten
    TIM_Cmd(TIM1, ENABLE);

#elif defined TIMER2
    // activate Timer 2

    // This two lines destroy the Mikrocontroller...
    // RCC->CFGR0 &= ~RCC_PPRE1_0;
    // RCC->CFGR0 |= RCC_PPRE1_DIV1;

    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);
    //RCC_AHBPeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);
    // configure Timer interrupt
    TIM_ITConfig(TIM2,  TIM_IT_Update, ENABLE);


    // configure Timer
    TIM_TimeBaseInitTypeDef TIM_TimeBaseInitStructure;
    NVIC_InitTypeDef NVIC_InitStructure;

    TIM_TimeBaseInitStructure.TIM_Period = 0xFFFF;
    TIM_TimeBaseInitStructure.TIM_Prescaler = 0;
    TIM_TimeBaseInitStructure.TIM_ClockDivision = TIM_CKD_DIV1;
    TIM_TimeBaseInitStructure.TIM_CounterMode = TIM_CounterMode_Up;
    TIM_TimeBaseInit(TIM2, &TIM_TimeBaseInitStructure);

    // Timer-Interrupt configure
    NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = NVIC_PriorityGroup_4;
    NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
    NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_InitStructure);

    // start timer
    TIM_Cmd(TIM2, ENABLE);

#endif
}



void GPIO_Clock_Init(void){
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOC|RCC_APB2Periph_GPIOD, ENABLE);
}



void DMA_Rx_Init(DMA_Channel_TypeDef *DMA_CHx, u32 ppadr, u32 memadr, u16 bufsize){
    DMA_DeInit(DMA_CHx);

    DMA_InitTypeDef DMA_InitStructure = {0};

    RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);

    DMA_DeInit(DMA_CHx);

    DMA_InitStructure.DMA_PeripheralBaseAddr = ppadr;
    DMA_InitStructure.DMA_MemoryBaseAddr = memadr;
    DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralSRC;
    DMA_InitStructure.DMA_BufferSize = bufsize;
    DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_InitStructure.DMA_PeripheralDataSize = DMA_MemoryDataSize_Byte;
    DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
    DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
    DMA_InitStructure.DMA_Priority = DMA_Priority_VeryHigh;
    // Peripheral to memory (MEM2MEM=0, DIR=0) Datasheet p.62
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
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    // Setup MOSI Pin
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Rx;

    SPI_InitStructure.SPI_Mode = SPI_Mode_Slave;

    SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;  // maybe 8Bit ?
    SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;          // 0 = LOW
    SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;        // ???
    SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;               // Slave Select must be always true
    SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
    SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_64; // Should not be needed
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

    data_address = (uint32_t)(SPI1->DATAR);

#ifdef SPI_DMA
    // DMA not tested jet


    SPI_Slave_Init();
    //uint8_t* inputImagePointer = reinterpret_cast<uint8_t*>(inputImage);
    DMA_Rx_Init(DMA1_Channel2, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE); //IMAGE_SIZE
    DMA_Cmd(DMA1_Channel2, ENABLE);
#endif



    //      1. Check SPI for Errors
    //      2. DMA Timeout

#ifdef SPI_DMA
    for(ever){
        // Transfer completed Flag

        spi_data = SPI1->DATAR;

        FlagStatus newData = DMA_GetFlagStatus(DMA1_FLAG_TC2);

        if(newData){
            DMA_ClearFlag(DMA1_FLAG_TC2);
            matrix.newImage();
            //DMA_Rx_Init(DMA1_Channel2, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE/2);
            //DMA_Cmd(DMA1_Channel2, ENABLE);
        }

        // Transmission error
        if( DMA_GetFlagStatus(DMA1_FLAG_TE2) ){
            DMA_ClearFlag(DMA1_FLAG_TE2);
            //matrix.testImage();
        }
        //Transmission halfway flag
        if( DMA_GetFlagStatus(DMA1_FLAG_HT2) ){
            //matrix.testImage();
        }

    }
#elif defined(TEST_IMAGE)

    greyTest(inputImage);
    //colorTest(inputImage);
    matrix.newImage();


    volatile uint16_t counter_value = TIM1->CNT;
    while(1){
        counter_value = TIM1->CNT;

    }

#endif



}





#ifdef SYSTICK_TIMER
// essential for the timer running with cpps
extern "C" {    void SysTick_Handler(void); }

void SysTick_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));  //("WCH-Interrupt-fast")

void SysTick_Handler(void)
{
    SysTick->SR = 0;    // Reset the Status Registers
    //SysTick->CTLR &= ~0b0001;
    matrix.outputRow();
}





#elif defined TIMER1
// essential for the timer running with cpps
extern "C" { void TIM1_UP_IRQHandler(void); }

void TIM1_UP_IRQHandler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void TIM1_UP_IRQHandler(void)
{
    volatile uint16_t counter_value = TIM1->CNT;
    counter_value = TIM1->CNT;
    // Counter Value auf 0 setzen
    //TIM1->CNT = 0;
    //counter_value = TIM1->CNT;

    // Flags zur¨¹cksetzen
    // TIM_ClearITPendingBit(TIM1, TIM_IT_CC1);


    //matrix.outputRow();
}
#elif defined TIMER2
// essential for the timer running with cpps
extern "C" {    void TIM2_IRQHandler(void); }

void TIM2_IRQHandler(void) __attribute__((interrupt("WCH-Interrupt-fast")));
void TIM2_IRQHandler(void)
{
    // Counter Value to 0
    TIM2->CNT = 0;                          // TIM_SetCounter(TIM2, 0);
    // Reset Flags
    TIM2->INTFR = (uint16_t)~TIM_IT_Update; // TIM_ClearITPendingBit(TIM2,  TIM_IT_Update);

   matrix.outputRow();
}

#endif

