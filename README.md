"# ch32v003-16x8-SPI-RGB-LED-Matrix" 

Program by Mika Schächinger

This project is neither completed nor tested!




The programm is for the ch32v003 microcontroller, which sits on an self-designed LED-Matrix PCB.
The Matrix has 8x16 Pixels and should be able to display 24bit images with a framerate > 30FPS (Hopefully :D).
It can be chaned together to achieve decent image sizes.


How the program works:

    1. Controlled is the Panel over SPI. (Each Image is 384 Bytes [3x8x16])
    2. The DMA-controller moves the Data from the SPI-controller to the image-array (uint8_t)(size 3x8x16).
    3. After the image is received ready, the image is calculated to an array of the size 8x8x8 (uint8_t) and written to one of the two buffer ('inputBuffer')
        This format helps to write the six shiftregisters with only two assignments per Bit (all six shiftregisters are filled after 16 assignments).
    4. The pointer of the two buffers are swapped.
    5. The image from the 'outputBuffer' is output via binary code modulation.
        5.1 The SysTick Timer calls cyclic an interrupt, by which one row is output and the row counter is updated.
        5.2 After one brightness-level-image is finish, the brightness counter is updated and the Timer compare Register is bit-shifted left (muliply by 2)

        When we output the LSB of the brightness, the controller should be fully utilized. By incrementing the brightness levels, the controller should have enough time to calculate the 8x8x8 array from the 3x8x16 image

        But why a 8x8x8 array?
            The 8x16 matrix is divided into two 8x8 matrices (which are the last two dimensions).
            The first dimension is for the 8 brightness bits -> [COLOR_DEPTH][HEIGHT][WIDTH/2] <-> 8x8x8
            The values include the GPIOD Register which can easily assigned to the OUTDR-Register of GPIOD, to apply 6 data bits and the clock low simultaneously

    To save the powerconsumption, PC7 is used as an Enable-Input.


Pinout:

PA1 OSCI<br>
PA2 OSCO<br>

PC0 MATRIX A0<br>
PC1 MATRIX A1<br>
PC2 MATRIX A2<br>
PC3 MATRIX STCP<br>
PC4 MATRIX OE#<br>
PC5 SPI CLK<br>
PC6 SPI MOSI<br>
PC7 MATRIX_ENABLE Input<br>

PD0 MATRIX SHCP<br>
PD1	SWIO            <- for programming and debugging<br>
PD2 MATRIX DS_Red_1<br>
PD3 MATRIX DS_Red_2<br>
PD4 MATRIX DS_Green_1<br>
PD5 MATRIX DS_Green_2<br>
PD6 MATRIX DS_Blue_1<br>
PD7 MATRIX DS_Blue_2<br>


![Alt text](Image/PCB_Panel_Back_20230523.jpg?raw=true "Title")
