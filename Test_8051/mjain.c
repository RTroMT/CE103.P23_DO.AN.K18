#include <REGX52.H>
#include <intrins.h>  // For _nop_()

void Delay5us() {
    _nop_();  // ~1 µs
    _nop_();
    _nop_();
    _nop_();
    _nop_();  // Approx 5 µs total
}

void READ_ADC() {
    P3_7 = 0;      // CS = 0
    P3_6 = 1;      // RD = 1
    P3_5 = 0;      // WR = 0
    _nop_();   
    _nop_(); 
    _nop_(); 	// Small delay
    P3_5 = 1;      // WR = 1
    _nop_();
		_nop_(); 
    // Wait until INTR (P3.4) goes LOW
    while (P3_4);

    P3_7 = 0;      // CS = 0
    P3_6 = 0;      // RD = 0
    _nop_();
		_nop_(); 
	
	
    P2 = P1;       // Read ADC value (P1) and output to P2
}

void main() {
    P1 = 0xFF;     // Set Port 1 as input (ADC data)
    P2 = 0x00;     // Set Port 2 as output (display/output)
    
    while (1) {
        READ_ADC();  // Continuously read ADC and output to P2
			Delay5us();
			Delay5us();
    }
}