<!-- Repository Banner -->
<p align="center">
  <img src="img/banner.png" width="100%" alt="Project Banner" />
</p>

---

## 🔹 Overview

A microcontroller-based automation system that simulates the behaviour of a security light. The system detects motion using multiple PIR sensors and automatically rotates a servo-mounted light toward the direction of detected movement. Developed as part of an Embedded Systems module during the second year of undergraduate studies at SLIIT.
<p align="center">
  <img src="img/demo.gif" alt="water" width="1000px">
</p>
 
>Full system description referenced from project documentation.

---

## 🎥 Simulation & Hardware Preview

### 🔹 **Tinkercad Simulation**
![Simulation](image1.png)

### 🔹 **Real Hardware Prototype**
![Hardware Setup](image2.jpg)

---

## 🚀 Project Overview

This prototype uses **three PIR motion sensors** to detect movement from three different directions.  
When motion is detected, the system:

1. Identifies which PIR sensor triggered  
2. Rotates a **servo motor** to face the detected zone  
3. Activates a mounted LED/light toward that direction  
4. Returns to idle state after a delay  

The system runs on an **Atmega328p microcontroller** and is programmed using **C**.

---

## 🧠 Features

- Multi-directional motion detection (3 PIR sensors)
- Automatic servo rotation based on detection zone
- Light-tracking capability similar to a real security light
- Real-time sensor reading and actuator control
- Efficient C implementation for AVR microcontroller
- Breadboard prototype built with modular, testable wiring

---

## 🔧 Technologies & Components

### **Microcontroller**
- Atmega328p (AVR)

### **Sensors & Outputs**
- PIR motion sensors × 3  
- Servo motor (directional light control)  
- Indicator LED(s)

### **Software**
- C Programming Language  
- AVR-GCC / Atmel Studio / Arduino toolchain

### **Hardware Tools**
- Breadboard  
- 5V USB power supply  
- Jumper wires  
- Cardboard PIR mounts (custom-built)

---

## 🛠 System Architecture





















https://www.tinkercad.com/things/cMI0WKOE0Zd-project01/editel

<h2>CIRCUITS</h2>

<img width="1440" alt="Screenshot 2022-01-07 at 09 39 04" src="https://user-images.githubusercontent.com/76505825/148490137-92c16746-d0d7-46c2-bcd8-32ddb2d3af9c.png">

<img width="1440" alt="Screenshot 2022-01-07 at 09 36 26" src="https://user-images.githubusercontent.com/76505825/148490180-e10ecf73-2e23-4138-8912-06bc6c5be1c4.png">

<img width="1440" alt="Screenshot 2022-01-07 at 09 36 57" src="https://user-images.githubusercontent.com/76505825/148490218-53603a47-f471-4855-a44d-95aab9d09700.png">

