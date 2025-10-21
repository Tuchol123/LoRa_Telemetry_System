Vehicle Telemetry System – Speed and Braking Monitoring
Author: Adam Tuchowski
Supervisor: Dr inż. Artur Szczęsny
Institution: Lodz University of Technology, Institute of Electrical Engineering Systems (I26)
Year: 2025

Project Overview
This repository contains the source code, hardware schematics, and documentation for a telemetry system designed to monitor vehicle parameters such as speed and acceleration/braking. 
The system was developed as part of an engineering thesis and is based on LoRa, GPS, and accelerometer technologies.

The goal of the project was to create a low-cost, wireless telemetry system that enables free long-range data transmission without dependence on GSM networks or external infrastructure.

System Architecture
The telemetry system consists of the following main components:
- Raspberry Pi 4B – central unit for data collection and processing
- Multi-GNSS L76K – GPS module for vehicle speed and position measurement
- ADXL345 – 3-axis accelerometer for acceleration and braking analysis
- LoRa Wio-E5 (STM32WLE5JC) – wireless data transmission module operating at 868 MHz
- PC Station (Receiver) – receives, processes, and visualizes data using a custom MATLAB app
- Li-Pol Battery (4000 mAh) – provides portable power
- TP4056 Charger & S13V30F5 Converter – charging and power stabilization

Software
1. Raspberry Pi (Python)
The main script (kod_wszystko.py) performs:
- Initialization of sensors (GPS, accelerometer)
- Data acquisition and conversion to hexadecimal
- LoRa transmission using AT commands
- Error handling and connection monitoring

2. Receiver Application (MATLAB)
The MATLAB application includes:
- Serial communication setup with LoRa receiver
- Data conversion from HEX to physical values (speed, acceleration, coordinates)
- Real-time visualization (speed, acceleration, GPS path)
- Data saving to .csv files and plots export

LoRa Configuration
Both LoRa modules are configured in P2P mode with the following parameters:
AT+MODE=TEST
AT+TEST=RFCFG,F:868300000,SF7,BW125K,TXPR:8,RXPR:8,POW:14,CRC:ON,IQ:OFF,NET:OFF

Key Settings:
- Frequency: 868.3 MHz (EU868 band)
- Spreading Factor: SF7
- Bandwidth: 125 kHz
- Power: 14 dBm
- CRC: Enabled

MATLAB App Features
The graphical interface includes:
- Dropdowns for COM port and baud rate selection
- Buttons for system control:
  - START – begins data acquisition
  - STOP – stops transmission
  - DRAW – plots acceleration and speed
  - SAVE – saves data to timestamped folders
- Text area displaying system messages:
  - “Udane połączenie szeregowe” (Successful serial connection)
  - “Rysowanie wykresów” (Drawing plots)
  - “Zapis danych do folderu” (Saving data to folder)

System Testing
Tests were conducted in two environments:
- Urban area – stable data transmission up to ~550 m
- Open field – reliable communication up to ~1.3 km

Additional results:
- Operating time: ~1h 45min on a 4000 mAh battery
- Average current draw: ~2.28 A
- Charging time: ~4h 40min (5 V / 1 A)

Key Features
- Real-time wireless telemetry
- Data visualization and export
- Long-range LoRa communication (up to 1.3 km)
- Modular and scalable architecture
- Low power consumption and compact design

Repository Structure
telemetry-system/
 ┣ src/
 ┃ ┣ kod_wszystko.py          # Raspberry Pi data acquisition script
 ┃ ┗ matlab_app.mlapp         # MATLAB receiver and visualization app
 ┣ schematics/
 ┃ ┣ wiring_diagram.png       # System wiring
 ┃ ┗ pcb_design.kicad_pcb     # PCB layout
 ┣ data/
 ┃ ┗ example_output.csv       # Sample telemetry data
 ┣ README.md
 ┗ LICENSE

Hardware Summary
Component | Model | Function
Raspberry Pi | 4B | Main controller
GPS Module | L76K | Speed & coordinates
Accelerometer | ADXL345 | Acceleration & braking
LoRa Module | Wio-E5 STM32WLE5JC | Wireless transmission
Battery | Li-Pol 3.7V 4000 mAh | Power supply
Charger | TP4056 | Charging protection
Converter | S13V30F5 | Voltage regulation

License
This project is released under the MIT License. You are free to use, modify, and distribute this project with proper attribution.

Author
Adam Tuchowski
Student of Mechatronics, Lodz University of Technology
Member of Lodz Solar Team & Lodz Racing Team
