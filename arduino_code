#include <Servo.h>

// ----- Pin configuration -----
// PIR inputs
const uint8_t PIR_LEFT_PIN   = 2;   // left sensor
const uint8_t PIR_CENTER_PIN = 3;   // center sensor
const uint8_t PIR_RIGHT_PIN  = 4;   // right sensor

// Outputs
const uint8_t INDICATOR_LED_PIN = 13; // indicator LED (on when idle or when active as you prefer)
const uint8_t BUZZER_PIN        = 8;  // optional buzzer (active HIGH) - set to 255 if unused

// Servo
const uint8_t SERVO_PIN = 9;
Servo lightServo;

// ----- Behaviour parameters -----
const int LEFT_ANGLE   = 20;   // servo angle for left sensor (tune for your mount)
const int CENTER_ANGLE = 90;   // center
const int RIGHT_ANGLE  = 160;  // right
const unsigned long HOLD_TIME_MS = 5000UL; // how long to hold at detected position
const unsigned long DEBOUNCE_MS  = 300UL;  // simple debounce between triggers
const uint8_t SMOOTH_STEP_DELAY = 8;       // ms between 1-degree servo steps when moving

// ----- State tracking -----
int currentAngle = CENTER_ANGLE;
unsigned long lastTriggerMillis = 0;
unsigned long lastMoveMillis = 0;
int lastDetectedZone = -1; // -1 none, 0 left, 1 center, 2 right

void setup() {
  // Inputs
  pinMode(PIR_LEFT_PIN, INPUT);
  pinMode(PIR_CENTER_PIN, INPUT);
  pinMode(PIR_RIGHT_PIN, INPUT);

  // Outputs
  pinMode(INDICATOR_LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(INDICATOR_LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW); // keep buzzer off by default

  // Attach servo and move to center
  lightServo.attach(SERVO_PIN);
  moveServoSmooth(currentAngle, CENTER_ANGLE);
  currentAngle = CENTER_ANGLE;
}

void loop() {
  // Read PIRs
  bool left  = digitalRead(PIR_LEFT_PIN) == HIGH;
  bool center= digitalRead(PIR_CENTER_PIN) == HIGH;
  bool right = digitalRead(PIR_RIGHT_PIN) == HIGH;

  unsigned long now = millis();

  int detectedZone = -1;
  if (left) detectedZone = 0;
  else if (center) detectedZone = 1;
  else if (right) detectedZone = 2;

  if (detectedZone != -1) {
    // Debounce: avoid reacting to sensor chatter too fast
    if ((now - lastTriggerMillis) > DEBOUNCE_MS) {
      lastTriggerMillis = now;

      // If a new zone detected or was previously idle, move servo and start hold timer
      if (detectedZone != lastDetectedZone) {
        lastDetectedZone = detectedZone;
        unsigned long holdStart = now;
        int targetAngle = angleForZone(detectedZone);

        // Move servo smoothly to target angle
        moveServoSmooth(currentAngle, targetAngle);
        currentAngle = targetAngle;
        lastMoveMillis = now;

        // Indicate active
        digitalWrite(INDICATOR_LED_PIN, HIGH);
        // Optional: beep
        // beep(1, 80);

        // Wait for HOLD_TIME_MS while still reading sensors (non-blocking)
        while (millis() - holdStart < HOLD_TIME_MS) {
          // You could implement tracking logic here to re-target if a different PIR triggers while holding
          delay(10); // short sleep to yield; keep small so it's responsive
        }

        // After hold time, return to center
        moveServoSmooth(currentAngle, CENTER_ANGLE);
        currentAngle = CENTER_ANGLE;
        lastDetectedZone = -1;
        digitalWrite(INDICATOR_LED_PIN, LOW);
      }
    }
  }

  // small non-blocking idle delay to avoid busy-loop
  delay(20);
}

// Returns servo angle for a zone index
int angleForZone(int zone) {
  switch(zone) {
    case 0: return LEFT_ANGLE;
    case 1: return CENTER_ANGLE;
    case 2: return RIGHT_ANGLE;
    default: return CENTER_ANGLE;
  }
}

// Smoothly move servo from fromAngle to toAngle in single-degree steps
void moveServoSmooth(int fromAngle, int toAngle) {
  if (fromAngle == toAngle) return;
  if (fromAngle < toAngle) {
    for (int a = fromAngle; a <= toAngle; ++a) {
      lightServo.write(a);
      delay(SMOOTH_STEP_DELAY);
    }
  } else {
    for (int a = fromAngle; a >= toAngle; --a) {
      lightServo.write(a);
      delay(SMOOTH_STEP_DELAY);
    }
  }
}

// Simple beep helper (optional)
void beep(uint8_t times, uint16_t msOn) {
  for (uint8_t i=0; i<times; ++i) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(msOn);
    digitalWrite(BUZZER_PIN, LOW);
    delay(msOn);
  }
}
