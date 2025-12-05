	.syntax unified
	.cpu    atmega328p
	.fpu    soft
	.include "m328pdef.inc"

; --------------------------
; Configuration constants
; --------------------------
	.equ F_CPU = 16000000
	.equ PRESCALER = 8

; Pins
	.equ PIR_LEFT    = PD2
	.equ PIR_CENTER  = PD3
	.equ PIR_RIGHT   = PD4
	.equ LED_GREEN   = PD5
	.equ LED_RED     = PD7
	.equ SERVO_BIT   = PB1   ; OC1A (Arduino D9)

; Timer1 parameters for 50 Hz (TOP = ICR1)
	.equ TIMER1_TOP = 39999      ; (F_CPU / (PRESCALER * 50)) - 1

; Servo pulse widths (microseconds) -> counts (with prescaler 8, 16MHz: 2 counts per us)
	.equ SERVO_MIN_COUNTS    = 2000   ; ~1.0 ms
	.equ SERVO_CENTER_COUNTS = 3000   ; ~1.5 ms
	.equ SERVO_MAX_COUNTS    = 4000   ; ~2.0 ms

; Hold time -> approx 5000 ms. Timer0 overflow with prescaler=64 -> ~1.024 ms per overflow
; HOLD_OVF = round(5000 / 1.024) ≈ 4883
	.equ HOLD_OVF = 4883

; --------------------------
; Start
; --------------------------
	.section .text
	.global main
main:
	; --- Configure DDR / PORT ---
	; DDRD: set PD5 (green) and PD7 (red) as outputs; PD2/3/4 inputs (clear) 
	in   r16, DDRD
	sbr  r16, (1<<LED_GREEN)
	sbr  r16, (1<<LED_RED)
	cbr  r16, (1<<PIR_LEFT)|(1<<PIR_CENTER)|(1<<PIR_RIGHT)
	out  DDRD, r16

	; Disable internal pull-ups on PIR pins (expect PIR modules to drive outputs)
	in   r16, PORTD
	cbr  r16, (1<<PIR_LEFT)|(1<<PIR_CENTER)|(1<<PIR_RIGHT)
	out  PORTD, r16

	; Set servo pin PB1 as output
	in   r16, DDRB
	sbr  r16, (1<<SERVO_BIT)
	out  DDRB, r16

	; Initial LED states: green ON, red OFF
	in   r16, PORTD
	sbr  r16, (1<<LED_GREEN)
	cbr  r16, (1<<LED_RED)
	out  PORTD, r16

	; Small startup delay
	rcall delay_50ms

	; --- Timer1: Fast PWM, TOP = ICR1, non-inverting OC1A ---
	; ICR1 = TIMER1_TOP
	ldi  r16, lo8(TIMER1_TOP)
	out  ICR1L, r16
	ldi  r16, hi8(TIMER1_TOP)
	out  ICR1H, r16

	; OCR1A = center
	ldi  r16, lo8(SERVO_CENTER_COUNTS)
	out  OCR1AL, r16
	ldi  r16, hi8(SERVO_CENTER_COUNTS)
	out  OCR1AH, r16

	; TCCR1A: COM1A1=1 (non-inverting), WGM11=1
	ldi  r16, (1<<COM1A1)|(1<<WGM11)
	out  TCCR1A, r16

	; TCCR1B: WGM13=1, WGM12=1, CS11=1 (prescaler = 8)
	ldi  r16, (1<<WGM13)|(1<<WGM12)|(1<<CS11)
	out  TCCR1B, r16

	; --- Timer0: normal mode, prescaler = 64 (CS02:0 = 011) ---
	ldi  r16, (1<<CS01)|(1<<CS00)   ; CS00=1, CS01=1 -> prescaler 64
	out  TCCR0B, r16

	; Clear Timer0 counter and any pending flags
	ldi  r16, 0
	out  TCNT0, r16
	ldi  r16, (1<<TOV0)
	out  TIFR0, r16

main_loop:
	; Read PIND
	in   r16, PIND

	; Check left PIR
	sbrc r16, PIR_LEFT      ; skip next if bit is clear? sbrc skips if bit is set - we want branch if set
	 rjmp handle_left_check_center
	; If bit clear -> fall through to center check
	; Wait: using sbrc, when bit is set it skips next instruction (rjmp). We'll rearrange flow to be explicit

	; Re-read simpler approach: test left bit directly by using SBRS (skip if set) logic inverted
	in   r16, PIND
	sbis r16, PIR_LEFT      ; skip next if bit in r16 is set -> if set, skip rjmp to center
	 rjmp check_center
	; left is set -> fall through to handle_left
	rjmp handle_left

check_center:
	in   r16, PIND
	sbis r16, PIR_CENTER
	 rjmp check_right
	rjmp handle_center

check_right:
	in   r16, PIND
	sbis r16, PIR_RIGHT
	 rjmp no_detection
	rjmp handle_right

; --------------------------
; Handlers
; --------------------------
handle_left:
	; Set servo to left (OCR1A = SERVO_MIN_COUNTS)
	ldi  r16, lo8(SERVO_MIN_COUNTS)
	out  OCR1AL, r16
	ldi  r16, hi8(SERVO_MIN_COUNTS)
	out  OCR1AH, r16

	; LED: red ON, green OFF
	in   r16, PORTD
	cbr  r16, (1<<LED_GREEN)
	sbr  r16, (1<<LED_RED)
	out  PORTD, r16

	; Wait HOLD_OVF Timer0 overflows
	ldi  r24, lo8(HOLD_OVF)
	ldi  r25, hi8(HOLD_OVF)
	rcall wait_overflow16
	rjmp main_loop

handle_center:
	ldi  r16, lo8(SERVO_CENTER_COUNTS)
	out  OCR1AL, r16
	ldi  r16, hi8(SERVO_CENTER_COUNTS)
	out  OCR1AH, r16

	in   r16, PORTD
	cbr  r16, (1<<LED_GREEN)
	sbr  r16, (1<<LED_RED)
	out  PORTD, r16

	ldi  r24, lo8(HOLD_OVF)
	ldi  r25, hi8(HOLD_OVF)
	rcall wait_overflow16
	rjmp main_loop

handle_right:
	ldi  r16, lo8(SERVO_MAX_COUNTS)
	out  OCR1AL, r16
	ldi  r16, hi8(SERVO_MAX_COUNTS)
	out  OCR1AH, r16

	in   r16, PORTD
	cbr  r16, (1<<LED_GREEN)
	sbr  r16, (1<<LED_RED)
	out  PORTD, r16

	ldi  r24, lo8(HOLD_OVF)
	ldi  r25, hi8(HOLD_OVF)
	rcall wait_overflow16
	rjmp main_loop

no_detection:
	; Return to center, green ON, red OFF
	ldi  r16, lo8(SERVO_CENTER_COUNTS)
	out  OCR1AL, r16
	ldi  r16, hi8(SERVO_CENTER_COUNTS)
	out  OCR1AH, r16

	in   r16, PORTD
	sbr  r16, (1<<LED_GREEN)
	cbr  r16, (1<<LED_RED)
	out  PORTD, r16

	rcall delay_20ms
	rjmp main_loop

; -----------------------------------------------------------------
; wait_overflow16: waits for r25:r24 overflows of Timer0
; inputs: r25 = high byte, r24 = low byte (16-bit counter)
; clobbers: r16,r17,r18,r19
; -----------------------------------------------------------------
wait_overflow16:
	; branch to loop start
wait_loop:
	; poll TIFR0 TOV0 bit
	in   r18, TIFR0
	sbrc r18, TOV0     ; if TOV0 set, skip next instruction (rjmp)
	 rjmp wait_loop
	; clear TOV0 by writing 1
	ldi  r18, (1<<TOV0)
	out  TIFR0, r18

	; decrement 16-bit counter r25:r24
	subi r24, 1
	sbci r25, 0
	; if both zero -> return
	or   r16, r16     ; r16 is zero? we use r24/r25 check
	tst  r24
	brne wait_loop
	tst  r25
	brne wait_loop
	ret

; -----------------------------------------------------------------
; short delay routines (blocking, for small waits)
; -----------------------------------------------------------------
delay_50ms:
	ldi  r20, 50
d50_loop:
	ldi  r21, 200
d50_loop2:
	nop
	dec  r21
	brne d50_loop2
	dec  r20
	brne d50_loop
	ret

delay_20ms:
	ldi  r20, 20
d20_loop:
	ldi  r21, 200
d20_loop2:
	nop
	dec  r21
	brne d20_loop2
	dec  r20
	brne d20_loop
	ret

	.section .eeprom
