#include "debug.h"


enum MYGPIO{
    PA1 = 1,
    PA2 = 2,
    PC0 = 16,
    PC1 = 17,
    PC2 = 18,
    PC3 = 19,
    PC4 = 20,
    PC5 = 21,
    PC6 = 22,
    PC7 = 23,
    PD0 = 24,
    PD1 = 25,
    PD2 = 26,
    PD3 = 27,
    PD4 = 28,
    PD5 = 29,
    PD6 = 30,
    PD7 = 31,
};

/***********************************************************************************
 * @fn      GPIO_INIT               by Mika Schaechinger
 *
 * @brief   Initialized given GPIO from struct GPIO (PA1, PA2, PC0...PC7, PD0...PD7)
 *
 * @param   gpio - gives the gpio from the struct GPIO
 *          GPIO_MODE - Mode from ch32v00x_gpio.h
 *              GPIO_Mode_IN_FLOATING
 *              GPIO_Mode_IPD       ->  Input Pull Down
 *              GPIO_Mode_IPU       ->  Input Pull Up
 *              GPIO_Mode_Out_OD    ->  Output Open Drain
 *              GPIO_Mode_Out_PP    ->  Output Push Pull
 *                  other Analog
 *
 * @return  when gpio was valid, returning true, else false
 */

bool MYGPIO_INIT(MYGPIO gpio, GPIOMode_TypeDef GPIO_Mode){
    GPIO_InitTypeDef GPIO_InitStructure = {0};

    GPIO_TypeDef* GPIOX;

    switch((gpio & 0b11000) >> 3){
    case 0:
        GPIOX = GPIOA;
        if((gpio != PA1) && (gpio != PA2))
            return false;
    break;
    case 2: GPIOX = GPIOC; break;
    case 3: GPIOX = GPIOD; break;
    default: return false;
    }

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
    GPIO_InitStructure.GPIO_Pin = ((uint16_t)0b1 << (gpio & 0b111));
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;

    GPIO_Init(GPIOX, &GPIO_InitStructure);


    return true;
}


void MYGPIO_WriteBit(MYGPIO gpio, BitAction state){
    GPIO_TypeDef* GPIOX;
    switch((gpio & 0b11000) >> 3){
        case 0: GPIOX = GPIOA; break;
        case 2: GPIOX = GPIOC; break;
        case 3: GPIOX = GPIOD; break;
        default: return;
        }

    GPIO_WriteBit(GPIOX, ((uint16_t)0b1 << (gpio & 0b111)), state);
}

















