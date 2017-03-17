// adapted from: https://kartikmohta.com/tech/avr/tutorial/interrupts/walkingled.c.html

#include <inttypes.h>           // short forms for various integer types
#include <avr/io.h>
#include <avr/interrupt.h>      // file to be included if using interrupts

// bitwise helpers
#define setBit(x,y)    x |=  (1 << y)  //!< set bit - using bitwise OR operator
#define clearBit(x,y)  x &= ~(1 << y)  //!< clear bit - using bitwise AND operator
#define toggleBit(x,y) x ^=  (1 << y)  //!< toggle bit - using bitwise XOR operator

// --- Hardware Configuration
#define EXT_CLOCK_FREQ         (16000000ul)    // External Oscillator frequency (Hz)

// --- Timer Period
#define INDICATOR_FLASH_FREQ      ( 1u)   // Indicator flash frequency (Hz)


// --- UART
//#define USART_BAUD_FREQ (57600u)
#define USART_BAUD_FREQ (9600u) // UART comms frequency (Hz)


void sendUartByte(uint8_t data) {
    //wait while previous byte is completed
    while(!(UCSR0A & (1 << UDRE0))) {};
    // Transmit data
    UDR0 = (uint8_t)(data);
}

uint8_t receiveUartByte(void) {
    // Wait for byte to be received
    while(!(UCSR0A & (1 << RXC0))) {};
    // Return received data
    return (uint8_t)(UDR0);
}

void sendSpi(uint8_t byte) {
    /* Start transmission */
    SPDR = byte;
    /* Wait for transmission complete */
    while (!(SPSR & (1 << SPIF))) {}
}

ISR(TIMER1_COMPA_vect) { // handler for Output Compare 1 overflow interrupt
    // code is run once per second
    toggleBit(PORTB, PB7); // toggle the indicator LED on Arduino
    // your code here
}

void initialize_hardware(void) {
    // ============== Ports & Direction ==============
    // ----- Port B
    // Initial value
    PORTB = 0x00;               // set all outputs low
    // Pin Direction(s)
    DDRB  = 0x00;     // (default: all input)
    DDRB |= (1 << PB7); // PB7: indicator LED
    DDRB |= (1 << PB2); // PB2: SPI MOSI
    DDRB |= (1 << PB1); // PB1: SPI SCK (master)
    DDRB |= (1 << PB0); // PB1: SPI SS (unused, but making it an output makes it non-influential)

    // ============== Timers & Overflow Interrupts ==============
    // --- Operational Indicator
    TCCR1B = (1 << CS12) | (1 << WGM12); // Pre-scaler = 256; CTC: Clear Timer on Compare mode
    OCR1A  = (uint16_t)(((EXT_CLOCK_FREQ >> 8) / INDICATOR_FLASH_FREQ) - 1); // set Overflow (pre-scaler of 256)
    TIMSK1 = (1 << OCIE1A); // enable Output Compare 1 overflow interrupt

    // ============== UART: 0 ==============
    // Description:
    //      UART designed for initial development & debugging in future.
    //      (to be used in place of the RPi3 <- SPI -> ATmega2560 (target) for now)
    // Pins:
    //      Arduino MEGA:    PWML connector pins 2 & 1 (labeled TX0 & RX0)
    //      ATmega2560 pins: 3 & 2 (for TX0 & RX0 respectively)
    //
    // Note regarding baud-rate & connectivity on the Arduino MEGA:
    //       this serial port connects from the ATmega2560 (target) to the ATmega16U2,
    //       which connects to the PC via USB which emulates a serial-port.
    //       Therefore, there are 2 independent UART busses connecting this
    //       software to a PC.
    //          - ATmega2560 (target) <--> ATmega16U2
    //          - ATmega16U2          <--> PC (via USB)
    // Set baud rate
    UBRR0 = (uint16_t)(((EXT_CLOCK_FREQ / (USART_BAUD_FREQ * 0x10ul))) - 1);
    UCSR0A &= ~(1 << U2X0); // Clear UART 2x baud mode

    // Set frame format to: 8 data bits, no parity, no stop bit
    UCSR0C |= (1 << UCSZ01) | (1 << UCSZ00);

    //enable transmission and reception
    UCSR0B |= (1 << RXEN0) | (1 << TXEN0);


    // ============== SPI ==============
    /* Enable SPI, Master, set clock rate fck/16 */
    SPCR = (1 << SPE) | (1 << MSTR) | (1 << SPR0);
}

int main(void) {

    initialize_hardware();

    // enable interrupts
    sei();

    while (1) {
        // your loop code here
    }
}
