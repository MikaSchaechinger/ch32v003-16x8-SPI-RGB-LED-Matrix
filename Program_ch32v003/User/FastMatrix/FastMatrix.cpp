
#include "FastMatrix.h"
#include "MY_GPIO/MY_GPIO.h"
#include "debug/debug.h"







FastMatrix::FastMatrix(uint8_t (*inputImage)[HEIGHT][WIDTH], uint8_t (*buffer0)[HEIGHT][SHIFT_WIDTH], uint8_t (*buffer1)[HEIGHT][SHIFT_WIDTH]  ){

    this->inputImage = inputImage;
    this->inputBuffer = buffer0;
    this->outputBuffer = buffer1;

}

void FastMatrix::init(){
    // Datasheet Shiftregister: https://datasheet.lcsc.com/lcsc/1811021715_Nexperia-74HC595D-118_C5947.pdf
    // Datasheet 3-to-8 line decoder inverting: https://datasheet.lcsc.com/lcsc/1809042014_Nexperia-74HC138D-653_C5602.pdf

    MYGPIO_INIT(PC0, GPIO_Mode_Out_PP);     //  A0  (Row selection)
    MYGPIO_INIT(PC1, GPIO_Mode_Out_PP);     //  A1  (Row selection)
    MYGPIO_INIT(PC2, GPIO_Mode_Out_PP);     //  A2  (Row selection)
    MYGPIO_INIT(PC3, GPIO_Mode_Out_PP);     //  STCP            Storage Register Clock input
    MYGPIO_INIT(PC4, GPIO_Mode_Out_PP);     //  OE#             output enable input (active LOW)

    MYGPIO_INIT(PD0, GPIO_Mode_Out_PP);     //  SHCP            Shift Register Clock Input
    //MYGPIO_INIT(PD1, GPIO_Mode_Out_PP);   //  SWIO
    MYGPIO_INIT(PD2, GPIO_Mode_Out_PP);     //  DS_Red_1        serial data input Red Channel
    MYGPIO_INIT(PD3, GPIO_Mode_Out_PP);     //  DS_Red_2
    MYGPIO_INIT(PD4, GPIO_Mode_Out_PP);     //  DS_Green_1
    MYGPIO_INIT(PD5, GPIO_Mode_Out_PP);     //  DS_Green_2
    MYGPIO_INIT(PD6, GPIO_Mode_Out_PP);     //  DS_Blue_1
    MYGPIO_INIT(PD7, GPIO_Mode_Out_PP);     //  DS_Blue_2
    // PD7 has also a Reset function, which must be deactivated in user selected word (FLASH) (Datasheet page 176)
    // Or it is done with the WCH-LinkUtility
    // 1.)
//    uint32_t lock_is_active = FLASH->CTLR & FLASH_CTLR_LOCK;
//
//    if ( !lock_is_active ){ // "Unlock Flash"
//        // unlock sequence for "user select word operation"
//        //FLASH->OBKEYR = 0x45670123;
//        //FLASH->OBKEYR = 0xCDEF89AB;
//    }
//
//    delete lock_is_active;
//    // 2.)
//    uint32_t programming_in_progress = FLASH->STATR & FLASH_STATR_BSY;
//
//    if ( !programming_in_progress ){
//        // 3.)
//        FLASH->CTLR |= 0x20;   // OBPG Bit of FLASH_CTLR        See Bits of FLASH_CTLR on page 169
//        // 4.)
//        FLASH->CTLR |=
//    }
//
//
//
//
//    // lock the FLASH again
//    FLASH->CTLR |= FLASH_CTLR_LOCK;

    this->blackBuffer(this->inputBuffer);
    this->blackBuffer(this->outputBuffer);

//    // Setup Interrupts
//
//    NVIC_EnableIRQ(SysTicK_IRQn);
//    // SR = Status Register
//    SysTick->SR &= ~(1 << 0);   // Reset of the LSB -> LSB is the COUNTFLAG-Bit
//    SysTick->CMP = MIN_COMP_CLOCK;   // Set Compare Register
//    SysTick->CNT = 0;   // Reset the Count Value
//    SysTick->CTLR = 0;  // Reset System Count Control Register
//    SysTick->CTLR |= 0b0010;    // Enabling counter interrupts
//    //SysTick->CTLR |= 0b0100;    //  1: HCLK for time base.
//                                //  0: HCLK/8 for time base.
//    SysTick->CTLR |= 0b1000;    // Re-counting from 0 after counting up to the comparison value.
//
//    SysTick->CTLR |= 0b0001;    // Start the system counter STK
}

void FastMatrix::calcInputBuffer(){
    //  TODO: Invert high and Low (when low the LED is on, at high the LED is off)
    // Done, but needs testing

    uint8_t output;
    uint8_t offsetWidth;
    uint8_t brightnessMask;
    for(uint8_t depth = 0; depth < COLOR_DEPTH; depth++){
        brightnessMask = 0b1 << depth;
        for(uint8_t height = 0; height < HEIGHT; height++){

            //uint8_t* registerArray = reinterpret_cast<uint8_t *>(&outRegisterArray[brightness][row]);

//            uint8_t (*redRow) = reinterpret_cast<uint8_t (*)>(&(*this->inputImage)[0][height]);
//            uint8_t (*greenRow) = reinterpret_cast<uint8_t (*)>(&(*this->inputImage)[1][height]);
//            uint8_t (*blueRow) = reinterpret_cast<uint8_t (*)>(&(*this->inputImage)[2][height]);

            for(uint8_t width = 0; width < SHIFT_WIDTH; width++){
                output = 0;
                offsetWidth = width + 8;

//                output |= (redRow[width] & brightnessMask)? RED1_MASK : 0;
//                output |= (redRow[offsetWidth] & brightnessMask)? 0 : RED2_MASK;
//
//                output |= (greenRow[width] & brightnessMask)? GREEN1_MASK : 0; //GREEN1_MASK
//                output |= (greenRow[offsetWidth] & brightnessMask)? 0 : GREEN2_MASK;
//
//                output |= (blueRow[width] & brightnessMask)? 0 : BLUE1_MASK; // BLUE1_MASK
//                output |= (blueRow[offsetWidth] & brightnessMask)? 0 : BLUE2_MASK;

                output |= (this->inputImage[0][height][width] & brightnessMask)? 0 : RED2_MASK;
                output |= (this->inputImage[0][height][offsetWidth] & brightnessMask)? 0 : RED1_MASK;

                output |= (this->inputImage[1][height][width] & brightnessMask)? 0 : GREEN2_MASK; //GREEN1_MASK
                output |= (this->inputImage[1][height][offsetWidth] & brightnessMask)? 0 : GREEN1_MASK;

                output |= (this->inputImage[2][height][width] & brightnessMask)? 0 : BLUE2_MASK; // BLUE1_MASK
                output |= (this->inputImage[2][height][offsetWidth] & brightnessMask)? 0 : BLUE1_MASK;

                this->inputBuffer[depth][height][width] = output;
            }
        }
    }
}



void FastMatrix::outputRow(void){
    // Update SysTick-Time
    // SysTick->SR = 0;    // Reset the Status Registers
    // No Reset needed, auto reset configured
    // SysTick->CNT = 0;   // Reset the Count Value

    

    SysTick->CMP = MIN_COMP_CLOCK << this->brightness;  // Update the compare-Value

    //auto a = *(this->outputBuffer);
    uint8_t* rowArray = reinterpret_cast<uint8_t *>(  &((this->outputBuffer)[brightness][this->row][0])  );

    // Shift out one line
    GPIOD->OUTDR = rowArray[0];
    //GPIOD->OUTDR = this->outputBuffer[brightness][this->row][0];   // clock low and all 6 DS
    GPIOD->BSHR = CLOCK_MASK;               // clock high
    GPIOD->OUTDR = rowArray[1];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][1];   // ...
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[2];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][2];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[3];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][3];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[4];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][4];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[5];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][5];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[6];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][6];
    GPIOD->BSHR = CLOCK_MASK;
    GPIOD->OUTDR = rowArray[7];
    // GPIOD->OUTDR = this->outputBuffer[brightness][this->row][7];
    GPIOD->BSHR = CLOCK_MASK;

    GPIOC->BCR = STCP;                  // STCP LOW                     no effect
    GPIOC->BSHR = OE_NOT;               // OE_NOT High                  Matrix dark
    //GPIOC->OUTDR = ;
    GPIOC->OUTDR = this->row | OE_NOT | STCP;   // A0, A1, A2 like height       Select row (Matrix still dark)
    //GPIOC->BSHR = STCP;

    for(uint8_t i = 0; i < 0xA; i++){   // Short delay to reduce ghosting
    }


    this->row++;
    if( this->row >= 8){
        this->row = 0;
        this->brightness++;
        if(this->brightness >= 8){
            this->brightness = 0;
        }
    }
    GPIOC->BCR = OE_NOT;                // Enable Matrix
}



void FastMatrix::blackBuffer(uint8_t (*buffer)[HEIGHT][SHIFT_WIDTH]){
    // size_t bufferSize = sizeof(uint8_t) * COLOR_DEPTH * HEIGHT * SHIFT_WIDTH;
    //uint8_t* bufferPtr = reinterpret_cast<uint8_t*>((*buffer)[0][0][0]);

//    for (size_t i = 0; i < bufferSize; i++) {
//        bufferPtr[i] = 0xFF;
//    }

    for (uint8_t depth=0; depth < COLOR_DEPTH; depth++){
        for (uint8_t height=0; height < HEIGHT; height++){
            for(uint8_t width=0; width < SHIFT_WIDTH; width++){
                buffer[depth][height][width] = 0xFC;
            }
        }
    }
}

void FastMatrix::newImage(){
    this->calcInputBuffer();

    // swap Buffer
    auto bufferPointer = this->outputBuffer;
    this->outputBuffer = this->inputBuffer;
    this->inputBuffer = bufferPointer;
}

void FastMatrix::testImage(){
    //uint8_t* flatArray = reinterpret_cast<uint8_t*>((*this->inputImage));
    //int totalLength = COLOR * HEIGHT * WIDTH;

    //for (uint32_t index=0; index < totalLength; index++){
    //    flatArray[index] = (uint8_t) index;
    //}


     for (uint8_t color=0; color < COLOR; color++){
         for (uint8_t height=0; height < HEIGHT; height++){
             for(uint8_t width=0; width < WIDTH; width++){
                 this->inputImage[color][height][width] = 0;
             }
         }
     }
     for (uint8_t height=0; height < HEIGHT; height++){
          for(uint8_t width=0; width < WIDTH; width++){
              this->inputImage[0][height][width] = width << (height/2);
          }
      }

//    for (uint8_t i = 0; i<testImageCounter; i++){
//        this->inputImage[0][0][i] = 0xFF;
//        this->inputImage[1][4][i] = 0xFF;
//        this->inputImage[2][7][i] = 0xFF;
//    }


    //flatArray[this->testImageCounter] = 0xFF;
//    testImageCounter++;
//    if (testImageCounter >= (totalLength >> 8)){
//        testImageCounter = 0;
//    }

    this->newImage();
}

