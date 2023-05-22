
#include "FastMatrix.h"
#include "MY_GPIO/MY_GPIO.h"
#include "debug/debug.h"



FastMatrix::FastMatrix(uint8_t (*inputImage)[COLOR][HEIGHT][WIDTH], uint8_t (*buffer0)[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH], uint8_t (*buffer1)[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH]  ){

    this->inputImage = inputImage;
    this->inputBuffer = buffer0;
    this->outputBuffer = buffer1;

    MYGPIO_INIT(PC0, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PC1, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PC2, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PC3, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PC4, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD0, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD1, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD2, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD3, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD4, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD5, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD6, GPIO_Mode_Out_PP);
    MYGPIO_INIT(PD7, GPIO_Mode_Out_PP);


    // TODO: All to Black
    this->blackBuffer(this->inputBuffer);
    this->blackBuffer(this->outputBuffer);


    // Setup Interrupts
    NVIC_EnableIRQ(SysTicK_IRQn);
    // SR = Status Register
    SysTick->SR &= ~(1 << 0);   // Reset of the LSB -> LSB is the COUNTFLAG-Bit
    SysTick->CMP = MIN_COMP_CLOCK;   // Set Compare Register
    SysTick->CNT = 0;   // Reset the Count Value
    SysTick->CTLR = 0;  // Reset System Count Control Register
    SysTick->CTLR |= 0b0010;    // Enabling counter interrupts
    SysTick->CTLR |= 0b0100;    //  1: HCLK for time base.
                                //  0: HCLK/8 for time base.
    SysTick->CTLR |= 0b1000;    // Re-counting from 0 after counting up to the comparison value.

    SysTick->CTLR |= 0b0001;    // Start the system counter STK
}

void FastMatrix::calcInputBuffer(){
    uint8_t output;
    uint8_t offsetWidth;
    uint8_t brightnessMask;
    for(uint8_t depth = 0; depth < COLOR_DEPTH; depth++){
        brightnessMask = 0b1 << depth;
        for(uint8_t height = 0; height < HEIGHT; height++){

            //uint8_t* registerArray = reinterpret_cast<uint8_t *>(&outRegisterArray[brightness][row]);

            uint8_t* redRow = reinterpret_cast<uint8_t *>(&this->inputImage[0][height]);
            uint8_t* greenRow = reinterpret_cast<uint8_t *>(&this->inputImage[1][height]);
            uint8_t* blueRow = reinterpret_cast<uint8_t *>(&this->inputImage[2][height]);

            for(uint8_t width = 0; width < SHIFT_WIDTH; width++){
                output = 0;
                offsetWidth = width + 8;

                output |= (redRow[width] & brightnessMask)? RED1_MASK : 0;
                output |= (redRow[offsetWidth] & brightnessMask)? RED2_MASK : 0;

                output |= (greenRow[width] & brightnessMask)? GREEN1_MASK : 0;
                output |= (greenRow[offsetWidth] & brightnessMask)? GREEN2_MASK : 0;

                output |= (blueRow[width] & brightnessMask)? BLUE1_MASK : 0;
                output |= (blueRow[offsetWidth] & brightnessMask)? BLUE2_MASK : 0;

                *(this->inputBuffer[depth][height][width]) = output;
            }
        }
    }
}



void FastMatrix::outputRow(){
    // Update SysTick-Time
    SysTick->SR = 0;    // Reset the Status Registers
    // No Reset needed, auto reset configured
    // SysTick->CNT = 0;   // Reset the Count Value
    SysTick->CMP = MIN_COMP_CLOCK << this->brightness;  // Update the compare-Value


    uint8_t* rowArray = reinterpret_cast<uint8_t *>(&this->inputBuffer[brightness][this->row]);
    // Shift out one line
    GPIOD->OUTDR = (uint32_t)rowArray[0];   // clock low and all 6 DS
    GPIOD->BSHR = CLOCK_MASK;               // clock high
    GPIOD->OUTDR = (uint32_t)rowArray[1];   // ...
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[2];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[3];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[4];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[5];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[6];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = (uint32_t)rowArray[7];
    GPIOD->BSHR = CLOCK_MASK;

    GPIOC->BCR = STCP;                  // STCP LOW                     no effect
    GPIOC->BSHR = OE_NOT;               // OE_NOT High                  Matrix dark
    GPIOC->LCKR = this->row | OE_NOT;   // A0, A1, A2 like height       Select row (Matrix still dark)
    GPIOC->BCR = OE_NOT;                // Enable Matrix

    // update row

    this->row++;
    if( this->row >= 8){
        this->row = 0;
        this->brightness++;
        if(this->brightness >= 8){
            this->brightness = 0;
        }
    }
}



void FastMatrix::blackBuffer(uint8_t (*buffer)[COLOR_DEPTH][HEIGHT][SHIFT_WIDTH]){
    size_t bufferSize = sizeof(uint8_t) * COLOR_DEPTH * HEIGHT * SHIFT_WIDTH;
    uint8_t* bufferPtr = reinterpret_cast<uint8_t*>(buffer);

    for (size_t i = 0; i < bufferSize; i++) {
        bufferPtr[i] = 0;
    }
}

void FastMatrix::newImage(){
    this->calcInputBuffer();

    // swap Buffer
    auto bufferPointer = this->outputBuffer;
    this->outputBuffer = this->inputBuffer;
    this->inputBuffer = bufferPointer;
}


