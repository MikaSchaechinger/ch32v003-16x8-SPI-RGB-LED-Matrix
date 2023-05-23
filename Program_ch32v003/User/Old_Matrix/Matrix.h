
#include "debug.h"

#define HEIGHT 8
#define WIDTH 16
#define BRIGHTNESS_SIZE 2
#define RED_MASK   0b1111100000000000
#define GREEN_MASK 0b0000011111100000
#define BLUE_MASK  0b0000000000011111

typedef union{
    uint16_t value;
    struct{
        uint16_t blue : 5;
        uint16_t green : 6;
        uint16_t red : 5;
    } rgb;
} Pixel;

typedef struct{
    Pixel image[HEIGHT][WIDTH];
    uint8_t flag;
} Image;

uint8_t outRegisterArray[BRIGHTNESS_SIZE][HEIGHT][WIDTH];


class MatixController{
    static constexpr uint8_t height = HEIGHT;
    static constexpr uint8_t width = WIDTH;


    GPIO_TypeDef* shiftRegisterGPIO;
    const uint16_t CLK_PIN;
    const uint16_t SER_RED_PIN;
    const uint16_t SER_GREEN_PIN;
    const uint16_t SER_BLUE_PIN;
    const uint16_t RCLK_PIN;
    const uint16_t OE_PIN;

    const uint16_t rowA_PIN;
    const uint16_t rowB_PIN;
    const uint16_t rowC_PIN;

    uint8_t testIndex = 0;

public:
    Image image0;
    Image image1;

    Image* outputImage = &image0;
    Image* inputImage = &image1;

    // Brightness shifts each time to the right
    uint8_t brightness = 0;



    void writeOutRegisterArray(uint8_t brightness, uint8_t row){
        if(brightness > BRIGHTNESS_SIZE){
            printf("Error in writeOutRegisterArray(). Brightness was %d\n", brightness);
            return;
        }

        Pixel* line = reinterpret_cast<Pixel*>(&(outputImage->image)[row]);
        uint8_t* registerArray = reinterpret_cast<uint8_t *>(&outRegisterArray[brightness][row]);

        uint16_t brightnessMask;
        uint8_t red;
        uint8_t green;
        uint8_t blue;
        uint16_t colors;

        if(brightness == 0){
            brightnessMask = 0b0000000000100000;
            for(uint8_t i = 0; i < this->width; i++){
                registerArray[i] = (line[i].value & brightnessMask) ? SER_GREEN_PIN : 0;
            }
        }
        else{
            brightnessMask = 0b0000100001000001 << (brightness - 1);
            uint8_t andMask;
            for(uint8_t i = 0; i < this->width; i++){
                colors = line[i].value & brightnessMask;
                red   = colors & 0b1111100000000000;
                green = colors & 0b0000011111100000;
                blue  = colors & 0b0000000000011111;
                andMask = (red ? SER_RED_PIN : 0) | (green ? SER_GREEN_PIN : 0) | (blue ? SER_BLUE_PIN : 0);

                // OR
                /*
                andMask = 0;
                if(red)
                    andMask |= SER_RED_PIN;
                if(green)
                    andMask |= SER_GREEN_PIN;
                if(blue)
                    andMask |= SER_BLUE_PIN;
                */

                registerArray[i] = andMask;
            }
        }
    }

    /*
     * Time for 1000000 Function Calls: 4708ms
     */
    void printFastRow(uint8_t row){
        uint8_t* registerArray = reinterpret_cast<uint8_t *>(&outRegisterArray[this->brightness][row]);

        for(uint8_t* i = registerArray; i < registerArray + WIDTH; i++){
            shiftRegisterGPIO->OUTDR = *i;
            //Delay_Ms(1);
            shiftRegisterGPIO->BSHR = CLK_PIN;
            //Delay_Ms(1);
        }
    }

    /*
     *  Only for 5 Brightness Levels, not for the 6th (the lowest of green)
     */
    void printRow(uint8_t row){
        Pixel* line = reinterpret_cast<Pixel*>(&outputImage->image[row]);
        uint8_t red;
        uint8_t green;
        uint8_t blue;
        uint16_t colors;

        for(uint8_t i = 0; i < this->width; i++){
            colors = line[i].value & (0b0000100001000001 << brightness);
            red   = colors & 0b1111100000000000;
            green = colors & 0b0000011111100000;
            blue  = colors & 0b0000000000011111;

            if(red)
                shiftRegisterGPIO->BSHR = SER_RED_PIN;  // Set SER Red Pin
            else
                shiftRegisterGPIO->BCR = SER_RED_PIN;   // Reset SER Red Pin
            if(green)
                shiftRegisterGPIO->BSHR = SER_GREEN_PIN;
            else
                shiftRegisterGPIO->BCR = SER_GREEN_PIN;
            if(blue)
                shiftRegisterGPIO->BSHR = SER_BLUE_PIN;
            else
                shiftRegisterGPIO->BCR = SER_BLUE_PIN;

        }
    }





/*
    void printRow(uint8_t row){
        // TODO: Enable Matrix with OE

        Pixel* line = reinterpret_cast<Pixel*>(&outputImage[row]);

        for(uint8_t i = 0; i < this->width; i++){
            Pixel out;
            out.value.value = line[i].value.value & brightnes;
            shiftRegisterGPIO->BCR = CLK_PIN;   // Reset CLock Pin
            if(out.rgb[0])
                shiftRegisterGPIO->BSHR = SER_RED_PIN;  // Set SER Red Pin
            else
                shiftRegisterGPIO->BCR = SER_RED_PIN;   // Reset SER Red Pin
            if(out.rgb[1])
                shiftRegisterGPIO->BSHR = SER_GREEN_PIN;
            else
                shiftRegisterGPIO->BCR = SER_GREEN_PIN;
            if(out.rgb[2])
                shiftRegisterGPIO->BSHR = SER_BLUE_PIN;
            else
                shiftRegisterGPIO->BCR = SER_BLUE_PIN;

            shiftRegisterGPIO->BSHR = CLK_PIN;  // Set Clock Pin    Shift in the SER Values

        }
        // New Line is finish written.
        // Brightnes dependent delay

        // Disable Matrix with OE
        // Select the new Row
        // use RCLK to update the shift Registers

    }
    */


    void printMatrix(){
        for(uint8_t i = 0; i < height; i++){
            this->printRow(i);
        }
    }


public:
    MatixController(GPIO_TypeDef* shiftRegisterGPIO, const uint16_t CLK_PIN, const uint16_t SER_RED_PIN, const uint16_t SER_GREEN_PIN, const uint16_t SER_BLUE_PIN, const uint16_t RCLK_PIN, const uint16_t OE_PIN, const uint16_t rowA_PIN, const uint16_t rowB_PIN, const uint16_t rowC_PIN) :
        shiftRegisterGPIO(shiftRegisterGPIO), CLK_PIN(CLK_PIN), SER_RED_PIN(SER_RED_PIN), SER_GREEN_PIN(SER_GREEN_PIN), SER_BLUE_PIN(SER_BLUE_PIN), RCLK_PIN(RCLK_PIN), OE_PIN(OE_PIN), rowA_PIN(rowA_PIN), rowB_PIN(rowB_PIN), rowC_PIN(rowC_PIN)
    {
        this->clearImage(this->outputImage);
        this->clearImage(this->inputImage);
        this->testImage(this->outputImage);
        this->testImage(this->inputImage);

        Pixel p;
        printf("Pixel Size: %d Byte\n", sizeof(p));
        printf("Image Size: %d Byte\n", sizeof(image0));
    }

    ~MatixController(){}


    void printImage(){
    }




    void clearImage(Image* image, uint16_t color = 0){
        for(uint8_t i = 0; i < HEIGHT; i++){
            for(uint8_t j = 0; j < WIDTH; j++){
                (image->image[i][j]).value = color;
            }
        }
    }

    void testImage(Image* image){
        for(uint8_t i = 0; i < HEIGHT; i++){
            for(uint8_t j = 0; j < WIDTH; j++){
                (image->image[i][j]).rgb.green = j%3 ? 0b01 : ((j+1)%3 ? 0b10 : 0);
            }
        }
    }

    void show(){
        shiftRegisterGPIO->BSHR = RCLK_PIN;
    }

    void updateImage(){
        for(uint8_t i = 0; i < HEIGHT; i++){
            for(uint8_t j = 0; j < WIDTH; j++){
                if (j == testIndex){
                    inputImage->image[i][j].value = 0xFFFF;

                }
                else{
                    inputImage->image[i][j].value = 0;
                }
            }
        }

        Image* img = inputImage;
        inputImage = outputImage;
        outputImage = img;

        testIndex++;
        if (testIndex > WIDTH)
            testIndex = 0;

        writeOutRegisterArray(1, 0);
        writeOutRegisterArray(0, 0);
    }

    void printOutputImage(){
        for(uint32_t i = 0; i < WIDTH; i++){
            if(outputImage->image[0][i].rgb.green){
                printf("1");
            }
            printf("0");
        }
        printf("\n");
    }

};






