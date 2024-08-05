"# ch32v003-16x8-SPI-RGB-LED-Matrix" 

Program and PCBs by Mika Schächinger

This project is not finished!

It consists of multiple Sub-Parts:
    1. 16x8 24bit RGB Matrix    (finished, but can be changed in the future)
    2. Connector PCBs: connect the them to one big Matrix    (finished, but can be changed in the future)
    3. Adapter PCB: Like the Connector PCB, but Connectors for Input Cables (finished, but can be changed in the future)
    4. HDMI/DVI Matrix Controler    (Currently in Development)
        4.1. Tang Nano 9k (low cost FPGA)    
        4.2. Mainboard which holds the Tang Nano 9k, Level-Shifters and Connectors to the MAtrix Adapters (Not started)
        4.3. HDMI-EDID-Emulator Connector. (Currently in Development)


"# RGB MAtrix Panal"

The main panal is finished and works. It receives images over SPI which are displayed with 24 bit colors. The Internal Framerate is near 100 FPS. Later on a big Matrix, the small 16x8 Panals are chained to multiple rows. The resulting Framerate the depends on teh SPI speed, which must feed one panal after another in the row. With a 480 Pixel wide row I expect a Framerate higher than 30FPS. The Framerate later will depend on the FPGA speed and the internal implementation.
Each matrix panal has its own microcontroller (ch32v003). So below in "Matrix-Panel Program" how the code works.



"# HDMI to Matrix"

The goal is to control the LED-Matrix over HDMI. To drive the Matrix Panals, multiple parallel SPI Streams are needed. 
To convert a HDMI/DVI Video Stream to the SPI stream, the Tang Nano 9k should convert the Signal with its FPGA. An FPGA (Field Programmable Gate Array) has internal connections, lookuptables and more, which can be programmed, so every imaginal logic can be implemented (as long space, ressources and timing constraints are met). 
The FPGA should receive the Videostream and save parts of the Frame in a double buffer (internal BRAM). In the Buffer, one Matrix Column should be saved. This is neccassary, so the output part can send the 384 byte stream (3x16x8 byte) as a whole packet over one SPI Stream to one Matrix panal. Because the FPGA can implement real parallel logic, multiple SPI streams will be send to each panel in a column. Then the buffer access switches and the next column is outputted.
The reason the Tang Nano 9k is selected is, that it costs only about 15€, which is extreamly cheap for a FPGA. The downside is, that it lacks on ressources, however they should be enough to drive a 480x640 Pixel Matrix. 

A current Problem is, that the HDMI Port on the Tang Nano 9k is intended to be an output. But in this case it should work as an input.  
The current approach is to create a EDID-Emulator-Connector which managed the EDID and Hotplug detect. Those HDMI Pins are not Connected on the Tang Nano 9k.
The EDID (Extended Display Identification Data) is saved on the screen side. If a Source connects to the screen, this is detected by Hotplug detect. Then the source asks for the EDID over the I2C Bud in the HDMI Cable. Based on the EDID the source knows shich resolution, Framerate and Colors it has to send. To receive a image, we first have to send the EDID to the video source. Its possible that the Tang Nano 9k Dev Board needs to be modified for receiving...




"# Matrix-Panel Program"

The programm is for the ch32v003 microcontroller, which sits on an self-designed LED-Matrix PCB.
The Matrix has 8x16 Pixels and should be able to display 24bit color images (8bit per color RGB) with a framerate near 100FPS.
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

IMPORTANT: PD7 overlaps with the reset function. To disable this function and use the pin as an IO-Pin, programm with the WCH-LinkUtility and select "Disable mul-func,PD7 is used for IO function". As standard there should be selected "Enable mul-func,ignored pin status within 128us/1ms/12ms"



The PCB:

The PCB has a Size of 40x80 mm. With 8x16 RGB-LEDs there is a distance of 5mm between each LED. 


Main panel back site:
![Alt text](Images/PCB_Panel_Back_20230523.jpg?raw=true "Matrix Panel Back")

Test Image for color (depth) and grey scale:
![Alt text](Images/TestImages_20230717.jpg?raw=true "Test Images")

Both test images have an exponential brightness curve. 
The is dependend by "MIN_COMP_CLOCK" which is 0x7F (127) to 0xFF (255), which describes the clock cycles for the shortest period of the SysTick-Timer. At 24MHz and 0xFF this results in  24MHz / (0x7F * 255 color steps * 8 rows) = 92 FPS.
Because the outputRow() function is relative short, MIN_COMP_CLOCK could be lowered more to gain higher frame rates.


Some interesting things:
1. This project is based on Cpp and not like the example projects on C. This results in problems, when you try to call the SysTick_Handler interrupt. The interrupt worked with this extra line: extern "C" {    void SysTick_Handler(void); }
2. GPIO4 (PD7) is used. This pin workes not out of the box as an ouput, because NRST (Reset) is at the same pin. To use it, you must deactivate the reset function. This can be done by programming the ch32v003 with the WCH-LinkUtility with "Disable mul-func, PD7 is used for IO function" selected.




The PCB is designed with EasyEDA. 
The Parts are from LCSC.com and the PCBs from JLCPCB.com

The goal is to archive a price of under 5€ per Panel.
Higher quantities (~100 PCBs) can probably achieve a price of 3€ per piece.

