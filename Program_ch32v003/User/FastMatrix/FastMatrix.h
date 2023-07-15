#include "debug.h"

#define WIDTH 16
#define SHIFT_WIDTH 8   // half WIDTH
#define HEIGHT 8
#define COLOR 3

#define COLOR_DEPTH 8



// GPIO C
#define A0 GPIO_Pin_0
#define A1 GPIO_Pin_1
#define A2 GPIO_Pin_2
#define STCP GPIO_Pin_3
#define OE_NOT GPIO_Pin_4

#define OE_OR_HEIGHT (HEIGHT | OE_NOT)

// GPIO D
#define CLOCK_MASK GPIO_Pin_0
#define RED1_MASK GPIO_Pin_2
#define RED2_MASK GPIO_Pin_3
#define GREEN1_MASK GPIO_Pin_4
#define GREEN2_MASK GPIO_Pin_5
#define BLUE1_MASK GPIO_Pin_6
#define BLUE2_MASK GPIO_Pin_7

// With the SysTick-Timer the Period-Time of the shortest Row cycle
#define MIN_COMP_CLOCK 0xFF



class FastMatrix{
    uint8_t (*inputImage)[HEIGHT][WIDTH];   //[COLOR]
    uint8_t (*inputBuffer)[HEIGHT][SHIFT_WIDTH]; // [COLOR_DEPTH]
    uint8_t (*outputBuffer)[HEIGHT][SHIFT_WIDTH]; // [COLOR_DEPTH]


    uint8_t brightness = 0;     // current brightness   [0...7] for 8 Bit brightness
    uint8_t row = 0;            // active row           [0...7] ( < HEIGHT)
    uint32_t testImageCounter = 0;


    void calcInputBuffer();
    void blackBuffer(uint8_t (*buffer)[HEIGHT][SHIFT_WIDTH]);

public:
    FastMatrix(uint8_t (*inputImage)[HEIGHT][WIDTH], uint8_t (*buffer0)[HEIGHT][SHIFT_WIDTH], uint8_t (*buffer1)[HEIGHT][SHIFT_WIDTH]);
    void init();
    void testImage();
    void newImage();
    void outputRow();


};
