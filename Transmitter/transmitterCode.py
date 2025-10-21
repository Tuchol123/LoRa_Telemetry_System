import time
import serial
import board
import busio
import adafruit_adxl34x
import subprocess

# Ustawienia portu szeregowego dla LoRa
PORT = '/dev/ttyUSB0'
BAUD_RATE = 9600

# Ustawienia portu szeregowego dla GPS
GPS_PORT = '/dev/ttyS0'
GPS_BAUD_RATE = 9600

# Inicjalizacja I2C i ADXL345
i2c = busio.I2C(board.SCL, board.SDA)
accelerometer = adafruit_adxl34x.ADXL345(i2c)

# Funkcja generująca dane HEX dla akcelerometru
def generate_accel_hex(ax, ay, az):
    ax_int = int(ax * 100)
    ay_int = int(ay * 100)
    az_int = int(az * 100)
    hex_value = f"{ax_int & 0xFFFF:04X}{ay_int & 0xFFFF:04X}{az_int & 0xFFFF:04X}"
    return hex_value

# Funkcja wysyłająca komendę AT
def send_at_command(command, ser):
    ser.write((command + '\r\n').encode())
    time.sleep(0.2)
    response = b''
    while ser.in_waiting > 0:
        response += ser.read(ser.in_waiting)
    try:
        print(response.decode('utf-8'), end='')
    except UnicodeDecodeError:
        print(f"Odpowiedź w surowych danych: {response}")

# Funkcja wysyłająca komendy NMEA do konfiguracji GPS
def configure_gps(gps_serial):
    # Zmień baud rate na 57600
    gps_serial.write(b'$PCAS01,4*18\r\n')
    time.sleep(0.5)

    # Ustaw częstotliwość aktualizacji na 5 Hz
    gps_serial.write(b'$PCAS02,200*1D\r\n')
    time.sleep(0.5)
    
    # Zmień baud rate na 57600 w programie
    gps_serial.baudrate = 57600
    print("GPS: Baud rate ustawiony na 57600, częstotliwość na 5 Hz")

# Inicjalizacja LoRa
def lora_setup():
    ser = serial.Serial(PORT, BAUD_RATE, timeout=1)
    time.sleep(0.2)
    send_at_command("AT+MODE=TEST", ser)
    return ser

# Funkcja przetwarzająca wiadomości GNVTG z GPS
def process_gnvtg_message(message):
    fields = message.split(',')
    try:
        speed_kmh = float(fields[7]) if fields[7] else None
        return speed_kmh
    except (ValueError, IndexError):
        print('Błąd przetwarzania wiadomości GNVTG.')
        return None

# Funkcja przetwarzająca wiadomości GNGGA z GPS
def process_gngga_message(message):
    fields = message.split(',')
    try:
        lat_raw = fields[2]
        lat_dir = fields[3]
        lon_raw = fields[4]
        lon_dir = fields[5]

        latitude = convert_to_decimal(lat_raw, lat_dir)
        longitude = convert_to_decimal(lon_raw, lon_dir)
        return latitude, longitude
    except (ValueError, IndexError):
        print('Błąd przetwarzania wiadomości GNGGA.')
        return None, None

# Konwersja współrzędnych do formatu dziesiętnego
def convert_to_decimal(raw, direction):
    if raw:
        raw = str(float(raw))
        degrees = int(raw[:2])
        minutes = float(raw[2:])
        decimal = degrees + minutes / 60
        if direction in ['S', 'W']:
            decimal = -decimal
        return decimal
    return None

# Funkcja generująca dane HEX ze współrzędnych
def generate_gps_hex(latitude, longitude):
    lat_int = int(latitude * 10000)
    lon_int = int(longitude * 10000)
    lat_hex = f"{lat_int & 0xFFFFF:04X}"
    lon_hex = f"{lon_int & 0xFFFFF:04X}"
    return lat_hex + lon_hex

# Główna pętla programu
def loop(ser, gps_serial):
    previous_time = time.time()
    interval = 0.3

    while True:
        current_time = time.time()

        # Odczyt danych z GPS
        if gps_serial.in_waiting > 0:
            gps_message = gps_serial.readline().decode('ascii', errors='replace').strip()
            if '$GNVTG' in gps_message:
                speed_kmh = process_gnvtg_message(gps_message)
                if speed_kmh is not None:
                    speed_hex = f"{int(speed_kmh * 100):04X}"
                    command = f"AT+TEST=TXLRPKT,\"{speed_hex}\""
                    send_at_command(command, ser)
                    print(f"Wysłano prędkość: {speed_kmh:.2f} km/h jako HEX: {speed_hex}")

            elif '$GNGGA' in gps_message:
                latitude, longitude = process_gngga_message(gps_message)
                if latitude is not None and longitude is not None:
                    gps_hex = generate_gps_hex(latitude, longitude)
                    command = f"AT+TEST=TXLRPKT,\"{gps_hex}\""
                    send_at_command(command, ser)
                    print(f"Wysłano współrzędne: Lat={latitude:.5f}, Lon={longitude:.5f} jako HEX: {gps_hex}")

        # Interwał do wysyłania danych z akcelerometru
        if (current_time - previous_time) >= interval:
            previous_time = current_time
            ax, ay, az = accelerometer.acceleration
            print(f"Akcelerometr: X={ax:.2f} m/s² | Y={ay:.2f} m/s² | Z={az:.2f} m/s²")
            hex_value = generate_accel_hex(ax, ay, az)
            command = f"AT+TEST=TXLRPKT,\"{hex_value}\""
            send_at_command(command, ser)

        # Odbieranie wiadomości
        if ser.in_waiting > 0:
            incoming_data = ser.read(ser.in_waiting).decode()
            print(f"Odebrano: {incoming_data}")

if __name__ == "__main__":
    try:
        print("Zatrzymanie aplikacji blokujących port.")
        subprocess.run(["sudo", "systemctl", "stop", "serial-getty@ttyS0.service"], check=True)
        print("KOnfiguracja modułu LoRa.")
        serial_obj = lora_setup()
        print("Moduł LoRa skonfigurowany.")
        print("Oczekiwanie 40 sekund na połączenie modułu MULTI-GNSS.")
        time.sleep(40)
        print("Konfiguracja modułu MULTI-GNSS.")        
        gps_serial = serial.Serial(GPS_PORT, GPS_BAUD_RATE, timeout=1)
        configure_gps(gps_serial)  
        gps_serial.close()
        gps_serial = serial.Serial(GPS_PORT, 57600, timeout=1) 
        print("Moduł MULTI-GNSS skonfigurowany.")        
        print('Odbieranie danych...')
        
        while True:
            loop(serial_obj, gps_serial)

    except KeyboardInterrupt:
        print("Program zatrzymany przez użytkownika.")
    except serial.SerialException as e:
        print(f'Błąd otwarcia portu GPS: {e}')
    finally:
        gps_serial.close()
