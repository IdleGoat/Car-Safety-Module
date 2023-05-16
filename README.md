# :car: CAR SAFETY MODULE  :car:

[![License](https://poser.pugx.org/pugx/badge-poser/license.svg)](https://github.com/IdleGoat/Car-Safety-Module/)

> This program is one of the requirements in fulfilling the task of Cyber Physical System for the Computer Engineering Department at the University of Indonesia.

![](https://hackmd.io/_uploads/HyLGZxbHn.png)

[TOC]

Made By Group B-10

1. Roy Oswaldha(2106731485)
2. Satya Ananda Sulistio (2106731226)
3. Najwa Fathiadisa (2106708463)
4. Rafie Amandio Fauzan (2106731232)

## Problems

## Solution

#### Introduction

This project aims to develop a comprehensive car safety module that enhances vehicle safety by integrating various functionalities. The module utilizes an ultrasonic sensor to measure distances between vehicles in real-time and provides immediate feedback to the driver through a clear display. It also incorporates throttle control, allowing drivers to adjust acceleration and speed accurately. An automatic braking system activates when the distance to the vehicle in front becomes critical, preventing rear-end collisions. Visual and auditory feedback mechanisms inform the driver when the vehicle stops due to distance-based braking. Additionally, an emergency brake activation system is included, enabling immediate braking in critical situations. Overall, this integrated safety module revolutionizes automobile safety by minimizing accidents caused by inadequate distance or driver error.

#### Main Features

##### Automatic Braking System

The module incorporates a responsive emergency brake system that detects imminent dangers using ultrasonic sensors .This rapid braking capability helps prevent collisions and reduces the severity of accidents.

##### Throttle Control

This car safety module offers precise control over the vehicle's throttle response. By integrating with the existing throttle mechanism, drivers can limit the speed or acceleration of their cars, especially in hazardous situations. This feature helps prevent accidents caused by sudden acceleration or excessive speed.

##### Object Detection

The car safety module includes an object detection feature that utilizes an ultrasonic sensor to measure the distance between the vehicle and surrounding objects. The ultrasonic sensor emits high-frequency sound waves and calculates the time it takes for the sound waves to bounce back after hitting an object. By analyzing the distance measurements, the system can identify potential obstacles in the vehicle's path.

## Hardware Design and Implementation

#### Hardware Specification

The Car Safety Module combines certain hardware components to provide robust and reliable safety features. The object detection feature of the module relies on an ultrasonic sensor. This sensor emits high-frequency sound waves and measures the time it takes for the sound waves to bounce back after hitting an object. It enables accurate distance measurements, allowing the module to detect potential obstacles in the vehicle's path and trigger appropriate responses. The module is designed to operate within the vehicle's power supply system. It can be powered directly from the vehicle's battery or through auxiliary power sources.

Component Used

- 2-Channel Relay 
- Arduino Uno R3 ATmega328P
- HC-SR04 Ultrasonic Sensor
- 10K **Ω** Linear Taper Rotary Potentiometer
- 9V Battery
- Breadboard
- Jumper Cable
- LED
- Buzzer
- MAX7219

#### Hardware Schematics

## Software Implementation

#### Software Used

- [Proteus](https://www.labcenter.com/)
- [Arduino IDE](https://support.arduino.cc/hc/en-us/articles/360019833020-Download-and-install-Arduino-IDE)

- [VS Code](https://code.visualstudio.com/)

#### Flowchart

![](https://hackmd.io/_uploads/HJ-sql-Hn.png)



This device operates through a sequential process that enables efficient control and safety measures. It begins by reading and storing the Analog to Digital Converter (ADC) value, which serves as a crucial input for subsequent operations. This value is then compared to predefined thresholds to determine the appropriate mode for motor operation, ensuring adaptive performance based on the prevailing conditions.

Once the motor mode is determined, the device sets the motor speed accordingly, allowing drivers to precisely control acceleration and speed. Simultaneously, it continuously collects distance measurements using an ultrasonic sensor. These measurements provide real-time feedback on the proximity of objects, enhancing driver awareness and enabling proactive decision-making.

To effectively transmit the distance measurements, the device utilizes the Serial Peripheral Interface (SPI) protocol to interface with the MAX 7219 display driver. This allows for clear and concise presentation of distance information on the display interface. The entire process, from ADC reading to motor control, distance measurement, and SPI transmission, operates in an iterative manner, ensuring consistent performance and promoting enhanced control and safety on the road.

## Test Result and Performance Evaluation

