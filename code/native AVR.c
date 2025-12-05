/*
  Motion Sensing Light - AVR (Atmega328P)
  - 3 PIR sensors on PD2, PD3, PD4
  - Servo on OC1A (PB1 -> Arduino D9)
  - Green LED PD5 = Ready (idle)
  - Red LED   PD7 = Active (motion detected)
  Timer1 configured: Fast PWM, TOP = ICR1 -> 50 Hz PWM (20 ms)
  Pulse width for servo: ~1.0 ms (min) .. ~2.0 ms (max)
*/

#define F_CPU 16000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <stdbool.h>

/// Pin mapping (ATmega328P)
#define PIR_LEFT_PIN    PD2
#define PIR_CENTER_PIN  PD3
#define PIR_RIGHT_PIN   PD4

#define LED_GREEN_PIN   PD5
#define LED_RED_PIN     PD7

#define SERVO_DDR_BIT   PB1   // OC1A -> Arduino D9 (PB1)
#define SERVO_OC_REG    OCR1A

// Timing / PWM parameters (tune if necessary)
#define PRESCALER 8UL
// For 50Hz: TOP = F_CPU/(prescaler * 50) - 1 = 39999 for prescaler 8
#define TIMER1_TOP 39999UL

// Servo pulse widths in timer ticks (1ms..2ms => counts = ms * F_CPU / prescaler / 1000)
#define US_TO_COUNTS(us) ((uint16_t)((F_CPU / (PRESCALER * 1000UL)) * (us)))
#define SERVO_MIN_US 1000 // 1.0 ms
#define SERVO_CENTER_US 1500 // 1.5 ms
#define SERVO_MAX_US 2000 // 2.0 ms

// Convert to OCR counts
const uint16_t SERVO_MIN_COUNTS = (uint16_t)US_TO_COUNTS(SERVO_MIN_US);      // ~2000
const uint16_t SERVO_CENTER_COUNTS = (uint16_t)US_TO_COUNTS(SERVO_CENTER_US);// ~3000
const uint16_t SERVO_MAX_COUNTS = (uint16_t)US_TO_COUNTS(SERVO_MAX_US);      // ~4000

// How long to hold at detected position (ms)
#define HOLD_TIME_MS 5000UL

int main(void) {
  // --- Configure I/O ---
  // Set PIR pins as input (clear DDRD bits)
  DDRD &= ~(1 << PIR_LEFT_PIN);
  DDRD &= ~(1 << PIR_CENTER_PIN);
  DDRD &= ~(1 << PIR_RIGHT_PIN);

  // Note: AVR has internal pull-ups only. If PIR output requires pull-down,
  // use external resistor. If you want to enable pull-ups (active-low PIR),
  // use: PORTD |= (1<<PIR_LEFT_PIN); and invert logic later.

  // LEDs -> outputs
  DDRD |= (1 << LED_GREEN_PIN);
  DDRD |= (1 << LED_RED_PIN);

  // Servo pin PB1 (OC1A) -> output
  DDRB |= (1 << SERVO_DDR_BIT);

  // Set initial LED state: green ON (ready), red OFF
  PORTD |= (1 << LED_GREEN_PIN);
  PORTD &= ~(1 << LED_RED_PIN);

  // --- Configure Timer1: Fast PWM, TOP = ICR1, non-inverting OC1A ---
  // WGM13:WGM10 = 14 (Fast PWM with ICR1 as TOP): WGM13=1, WGM12=1, WGM11=1, WGM10=0
  // COM1A1:0 = 2 (non-inverting) -> OC1A clears on compare, sets at TOP
  ICR1 = (uint16_t)TIMER1_TOP;       // top for 50Hz
  OCR1A = SERVO_CENTER_COUNTS;       // default center position

  TCCR1A = (1 << COM1A1) | (1 << WGM11); // COM1A1=1 (non-inverting), WGM11=1
  TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11); // WGM13=1 WGM12=1, prescaler = clk/8 (CS11)

  // small startup delay
  _delay_ms(200);

  // --- Main loop ---
  while (1) {
    // Read PIR inputs
    bool left_detect  = (PIND & (1 << PIR_LEFT_PIN)) != 0;
    bool center_detect= (PIND & (1 << PIR_CENTER_PIN)) != 0;
    bool right_detect = (PIND & (1 << PIR_RIGHT_PIN)) != 0;

    if (left_detect) {
      // Left PIR triggered -> move servo left and indicate active
      OCR1A = SERVO_MIN_COUNTS; // tune to actual angle
      PORTD &= ~(1 << LED_GREEN_PIN);  // green off
      PORTD |=  (1 << LED_RED_PIN);    // red on
      // Hold for defined time while continuing to sample (simple blocking hold)
      // If you need fully non-blocking, implement millis-style timer.
      uint32_t start = 0;
      // blocking delay in chunks to remain somewhat responsive:
      uint32_t elapsed = 0;
      while (elapsed < HOLD_TIME_MS) {
        _delay_ms(50);
        // Could re-check sensors here to switch target if required
        elapsed += 50;
      }
    }
    else if (center_detect) {
      OCR1A = SERVO_CENTER_COUNTS;
      PORTD &= ~(1 << LED_GREEN_PIN);
      PORTD |=  (1 << LED_RED_PIN);
      uint32_t elapsed = 0;
      while (elapsed < HOLD_TIME_MS) {
        _delay_ms(50);
        elapsed += 50;
      }
    }
    else if (right_detect) {
      OCR1A = SERVO_MAX_COUNTS;
      PORTD &= ~(1 << LED_GREEN_PIN);
      PORTD |=  (1 << LED_RED_PIN);
      uint32_t elapsed = 0;
      while (elapsed < HOLD_TIME_MS) {
        _delay_ms(50);
        elapsed += 50;
      }
    }
    else {
      // No motion: return servo to center and set ready LED
      OCR1A = SERVO_CENTER_COUNTS;
      PORTD |=  (1 << LED_GREEN_PIN);
      PORTD &= ~(1 << LED_RED_PIN);
      // short sleep to avoid busy looping
      _delay_ms(50);
    }
  }

  return 0;
}