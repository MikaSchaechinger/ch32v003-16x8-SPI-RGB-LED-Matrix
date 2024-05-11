#include "debug.h"

void TIM2_Init(void) {
    // Enable the clock for Timer 2
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

    // Configure the Timer
    TIM_TimeBaseInitTypeDef TIM_TimeBaseInitStructure;

    TIM_TimeBaseInitStructure.TIM_Period = 0xFFFF; // Maximaler Zählwert
    TIM_TimeBaseInitStructure.TIM_Prescaler = 24;   // Kein Prescaler (Teiler)
    TIM_TimeBaseInitStructure.TIM_ClockDivision = TIM_CKD_DIV1;
    TIM_TimeBaseInitStructure.TIM_CounterMode = TIM_CounterMode_Up;

    TIM_TimeBaseInit(TIM2, &TIM_TimeBaseInitStructure);

    // Starte den Timer
    TIM_Cmd(TIM2, ENABLE);
}

uint16_t getTIM2CounterValue(void){
    return TIM2->CNT;
}
