#include "debug.h"
#include "cmath"

#define COLOR 3
#define HEIGHT 8
#define WIDTH 16

// Help Function to convert from HSV to RGB
void hsvToRgb(double h, double s, double v, double& r, double& g, double& b)
{
    if (s == 0.0)
    {
        // Grey
        r = g = b = v;
        return;
    }

    h *= 6.0;
    int i = static_cast<int>(std::floor(h));
    double f = h - i;
    double p = v * (1.0 - s);
    double q = v * (1.0 - s * f);
    double t = v * (1.0 - s * (1.0 - f));

    switch (i % 6)
    {
        case 0:
            r = v;
            g = t;
            b = p;
            break;
        case 1:
            r = q;
            g = v;
            b = p;
            break;
        case 2:
            r = p;
            g = v;
            b = t;
            break;
        case 3:
            r = p;
            g = q;
            b = v;
            break;
        case 4:
            r = t;
            g = p;
            b = v;
            break;
        case 5:
            r = v;
            g = p;
            b = q;
            break;
    }
}

void colorTest(uint8_t inputImage[COLOR][HEIGHT][WIDTH])
{
    for (int y = 0; y < HEIGHT; y++)
    {
        double brightness = static_cast<double>((uint8_t)0xFF >> y) / ((double)0xFF);
        for (int x = 0; x < WIDTH; x++)
        {
            double hue = static_cast<double>(x) / WIDTH;  // Hue-Value from 0 to 1
            double r,g,b;


            hsvToRgb(hue, 1.0, 1.0, r, g, b);
            r *= brightness;
            g *= brightness;
            b *= brightness;

            inputImage[0][y][x] = static_cast<uint8_t>(r * 255);
            inputImage[1][y][x] = static_cast<uint8_t>(g * 255);
            inputImage[2][y][x] = static_cast<uint8_t>(b * 255);
        }
    }
}

double myPow(double base, uint8_t exponent){
    double result = 1;
    while(exponent != 0){
        result *= base;
        exponent--;
    }
    return result;
}


void greyTest(uint8_t inputImage[COLOR][HEIGHT][WIDTH])
{
    for (uint8_t y = 0; y < HEIGHT; y++)
    {
        for (uint8_t x = 0; x < WIDTH; x++)
        {
            double brightness = myPow((double)0.7071067, x);


            inputImage[0][y][x] = static_cast<uint8_t>(brightness * 255);
            inputImage[1][y][x] = static_cast<uint8_t>(brightness * 255);
            inputImage[2][y][x] = static_cast<uint8_t>(brightness * 255);
        }
    }
}

