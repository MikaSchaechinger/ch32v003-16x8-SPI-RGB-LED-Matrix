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
#include "TIme/time.h"


/* === Testing === */

#define SPI_DMA
//#define SPI_NO_DMA
//#define TEST_IMAGE

/* Select Timer */
#define SYSTICK_TIMER
//#define TIMER1
//#define TIMER2


#ifdef TEST_IMAGE
#include "testImage.h"
#endif

/* === Global define === */
#define ever ;;
#define IMAGE_SIZE (COLOR * HEIGHT * WIDTH)

// Must all have the same Number (here 2)
#define SPI_DMA_CHANNEL DMA1_Channel2
#define SPI_DMA_FLAG_TC DMA1_FLAG_TC2
#define SPI_DMA_FLAG_TE DMA1_FLAG_TE2
#define SPI_DMA_FLAG_HT DMA1_FLAG_HT2



/* === Global Variable === */

// SRAM 0x2000 0000 to 0x2000 0800
uint8_t inputImage[COLOR][WIDTH][HEIGHT];           // 0x2000 0404
uint8_t buffer0[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];  // 0x2000 0004
uint8_t buffer1[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH];  // 0x2000 0204
//uint32_t flag = 0;

uint32_t spi_data = 0;
uint32_t data_address;

FastMatrix matrix(inputImage, buffer0, buffer1);

bool dma_finish_flag = false;







//extern "C" {    // Maybe this is not needed. DMA was not tested yet.
//    void DMA1_Channel2_IRQHandler(void);
//}



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
    DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;   // Circular
    DMA_InitStructure.DMA_Priority = DMA_Priority_VeryHigh;
    // Peripheral to memory (MEM2MEM=0, DIR=0) Datasheet p.62
    DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
    DMA_Init(DMA_CHx, &DMA_InitStructure);

    // Interrupt
//    NVIC_InitTypeDef NVIC_InitStructure;
//    NVIC_InitStructure.NVIC_IRQChannel = DMA1_Channel1_IRQn;
//    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = NVIC_PriorityGroup_1;
//    NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
//    NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
//    NVIC_Init(&NVIC_InitStructure);

    DMA_ITConfig(DMA_CHx, DMA_IT_TC, ENABLE);
}

void SPI_Slave_Init(void){
    GPIO_InitTypeDef GPIO_InitStructure={0};
    SPI_InitTypeDef SPI_InitStructure={0};

    // Enable the High Speed APB (APB2) peripheral clock for SPI
    RCC_APB2PeriphClockCmd( RCC_APB2Periph_SPI1, ENABLE );

    // Setup Clock Pin
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    // Setup MOSI Pin
    GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPD;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init( GPIOC, &GPIO_InitStructure );

    SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex; // SPI_Direction_1Line_Rx;

    SPI_InitStructure.SPI_Mode = SPI_Mode_Slave;

    SPI_InitStructure.SPI_DataSize = SPI_DataSize_8b;  // maybe 8Bit ?
    SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;          // 0 = LOW
    SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;        // Clock Phase CPHA = 0
    SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;               // Slave Select must be always true
    SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
    SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_2; // Should not be needed
    SPI_InitStructure.SPI_CRCPolynomial = 0;
    SPI_Init( SPI1, &SPI_InitStructure );
    // SPI1->CTLR1 &= ~SPI_CTLR1_CRCEN;

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
    TIM2_Init();

    //data_address = (uint32_t)(SPI1->DATAR);

#ifdef SPI_DMA
    // DMA not tested jet


    SPI_Slave_Init();
    //uint8_t* inputImagePointer = reinterpret_cast<uint8_t*>(inputImage);
    DMA_Rx_Init(SPI_DMA_CHANNEL, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE); //IMAGE_SIZE
    DMA_Cmd(SPI_DMA_CHANNEL, ENABLE);

#elif defined(SPI_NO_DMA)
    SPI_Slave_Init();

#endif

    //      1. Check SPI for Errors
    //      2. DMA Timeout


#ifdef SPI_DMA

//    uint16_t newDMACounterValue = 0;
//    uint16_t oldDMACounterValue = 0;
//    uint16_t DMAChangeTime = 0;
//    uint16_t MAX_DATA_SPACE = 10000; // micro second
//
//    uint8_t* inputDataPtr = reinterpret_cast<uint8_t*>(inputImage[0][0]);
    for(ever){


//        oldDMACounterValue = newDMACounterValue;
//        newDMACounterValue = SPI_DMA_CHANNEL->CNTR;   // Is IMAGE_SIZE (384) When DMA has not started
//        if (oldDMACounterValue != newDMACounterValue){
//            // New DMA Data received
//            DMAChangeTime = getTIM2CounterValue();
//        }
//
//        volatile uint16_t now = getTIM2CounterValue();
//        if (DMAChangeTime - now > MAX_DATA_SPACE){
//            // Last Data Change is long ago
//            if(newDMACounterValue < IMAGE_SIZE){ // == DMA Has not started
//
//                if (newDMACounterValue == 0){
//                    DMA_ClearFlag(SPI_DMA_FLAG_TC);
//                    matrix.newImage();
//                }
//                DMA_Rx_Init(SPI_DMA_CHANNEL, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE);
//                DMA_Cmd(SPI_DMA_CHANNEL, ENABLE);
//
//                continue;
//            }
//        }


        // Transfer completed Flag
        FlagStatus newData = DMA_GetFlagStatus(SPI_DMA_FLAG_TC);

        if(newData){
            //uint16_t now = getTIM2CounterValue();     // Test if TIM2 is Running
            //inputDataPtr[now % IMAGE_SIZE] = 0xFF;
            DMA_ClearFlag(SPI_DMA_FLAG_TC);
            matrix.newImage();
            DMA_DeInit(SPI_DMA_CHANNEL);
            DMA_Rx_Init(SPI_DMA_CHANNEL, (u32)&SPI1->DATAR, (u32)inputImage, IMAGE_SIZE);
            DMA_Cmd(SPI_DMA_CHANNEL, ENABLE);
        }
        // Transmission error
        //if( DMA_GetFlagStatus(SPI_DMA_FLAG_TE) ){
        //    DMA_ClearFlag(SPI_DMA_FLAG_TE);
        //    //matrix.testImage();
        //}
        //Transmission halfway flag
        //if( DMA_GetFlagStatus(SPI_DMA_FLAG_HT) ){
        //    //matrix.testImage();
        //}


    }
#elif defined(SPI_NO_DMA)
    uint16_t dataIndex = 0;
    uint8_t* inputDataPtr = reinterpret_cast<uint8_t*>(inputImage);
    for(ever){

        if(SPI1->STATR & SPI_STATR_RXNE){   // New Data available

            inputDataPtr[dataIndex] = (uint8_t)(SPI1->DATAR);

            //matrix.newImage();
            dataIndex++;
            if(dataIndex >= IMAGE_SIZE){
                dataIndex = 0;
                matrix.newImage();
            }
            continue;
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


// essential for the timer running with cpps
extern "C" {    void SysTick_Handler(void); }
void SysTick_Handler(void) __attribute__((interrupt("WCH-Interrupt-fast")));  //("WCH-Interrupt-fast")
void SysTick_Handler(void)
{
    SysTick->SR = 0;    // Reset the Status Registers
    matrix.applyRow();
    //matrix.oldOutputRow();
}


//extern "C" {    void DMA1_Channel2_IRQHandler(void); }
//void DMA1_Channel2_IRQHandler(void) __attribute__((interrupt));  //("WCH-Interrupt-fast")
//void DMA1_Channel2_IRQHandler(void){
//    dma_finish_flag = true;
//}





