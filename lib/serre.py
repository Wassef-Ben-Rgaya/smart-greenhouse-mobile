import time
import board
import busio
import adafruit_tsl2561
import Adafruit_DHT
import RPi.GPIO as GPIO
from influxdb import InfluxDBClient
from datetime import datetime

# ---------- Initialisation des paramètres de capteurs et relais ----------
DHT_SENSOR = Adafruit_DHT.DHT22
DHT_PIN = 4
SOIL_SENSOR_PIN = 17
PUMP_RELAY_PIN = 22
FAN_RELAY_PIN = 27
HEATER_RELAY_PIN = 23
LAMP_RELAY_PIN = 24

# ---------- Seuils de température et luminosité ----------
THRESHOLD_TEMP_HIGH = 25
THRESHOLD_TEMP_LOW = 12
THRESHOLD_LUX_ON = 800
THRESHOLD_LUX_OFF = 2500
HYSTERESIS_TEMP = 1

# ---------- Gestion du temps de lumière (7h - 19h) ----------
start_light_time = datetime.utcnow().replace(hour=6, minute=0, second=0, microsecond=0)
end_light_time = datetime.utcnow().replace(hour=18, minute=0, second=0, microsecond=0)

SECONDS_PER_HOUR = 3600

# ---------- Configuration des GPIO ----------
GPIO.setmode(GPIO.BCM)
GPIO.setup(SOIL_SENSOR_PIN, GPIO.IN)
GPIO.setup(PUMP_RELAY_PIN, GPIO.OUT)
GPIO.setup(FAN_RELAY_PIN, GPIO.OUT)
GPIO.setup(HEATER_RELAY_PIN, GPIO.OUT)
GPIO.setup(LAMP_RELAY_PIN, GPIO.OUT)

# ---------- Initialisation des relais ----------
GPIO.output(PUMP_RELAY_PIN, GPIO.HIGH)
GPIO.output(FAN_RELAY_PIN, GPIO.HIGH)
GPIO.output(HEATER_RELAY_PIN, GPIO.HIGH)
GPIO.output(LAMP_RELAY_PIN, GPIO.HIGH)

# ---------- Initialisation du capteur de luminosité ----------
i2c = busio.I2C(board.SCL, board.SDA)
sensor_tsl = adafruit_tsl2561.TSL2561(i2c)
sensor_tsl.enabled = True
sensor_tsl.gain = 0
sensor_tsl.integration_time = 1

# ---------- Connexion à la base de données InfluxDB locale ----------
client_influx_local = InfluxDBClient(host='localhost', port=8086, database='serre_db')

# ---------- Variables de suivi des états ----------
last_time_temp_hum = 0
last_time_light = 0
last_time_soil = 0
fan_state = 0
heater_state = 0

# ---------- Variables pour stocker les dernières valeurs ----------
last_temperature = None
last_humidity = None
last_soil_moisture = None
last_lux = None

# ---------- État initial de la lampe et temps d'éclairage ----------
total_light_on_time = 0
lamp_on_start = None  
start_time = time.time()

# ---------- Fonction d'envoi de données à la base locale ----------
def send_data_to_influx_local(data):
    try:
        client_influx_local.write_points(data)
        return True
    except Exception as e:
        print(f"Erreur d'envoi des données à la base locale : {e}")
        return False

# ---------- Fonction pour récupérer l'état précédent depuis la base de données ----------
def get_previous_state():
    try:
        result = client_influx_local.query('SELECT * FROM "serre" ORDER BY time DESC LIMIT 1')
        points = list(result.get_points())
        if points:
            last_point = points[0]
            return {
                'temperature': last_point.get('Température'),
                'humidity': last_point.get('Humidité'),
                'soil_moisture': last_point.get('Humidité du sol'),
                'lux': last_point.get('Luminosité'),
                'lamp_state': last_point.get('Lampe'),
                'light_on_time': last_point.get('Temps Lumière', 0)
            }
        else:
            return {
                'temperature': None,
                'humidity': None,
                'soil_moisture': None,
                'lux': None,
                'lamp_state': False,
                'light_on_time': 0
            }
    except Exception as e:
        print(f"Erreur lors de la récupération de l'état précédent : {e}")
        return {
            'temperature': None,
            'humidity': None,
            'soil_moisture': None,
            'lux': None,
            'lamp_state': False,
            'light_on_time': 0
        }

# ---------- Récupération de l'état précédent ----------
previous_state = get_previous_state()

last_temperature = previous_state['temperature']
last_humidity = previous_state['humidity']
last_soil_moisture = previous_state['soil_moisture']
last_lux = previous_state['lux']
lamp_state = previous_state['lamp_state']
light_on_time = previous_state['light_on_time']

# ---------- Boucle principale du programme ----------
try:
    while True:
        current_time = time.time()
        timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        # ---------- Mise à jour de la température et de l'humidité toutes les 10 secondes ----------
        if current_time - last_time_temp_hum >= 10:
            last_time_temp_hum = current_time
            humidity, temperature = Adafruit_DHT.read_retry(DHT_SENSOR, DHT_PIN)

            if temperature is not None and humidity is not None:
                last_temperature, last_humidity = temperature, humidity
                
                if temperature > THRESHOLD_TEMP_HIGH :
                    fan_state ="ON"
                    GPIO.output(FAN_RELAY_PIN, GPIO.LOW)
                elif temperature < (THRESHOLD_TEMP_HIGH  - HYSTERESIS_TEMP):
                     fan_state ="OFF"
                     GPIO.output(FAN_RELAY_PIN, GPIO.HIGH)
                if temperature < THRESHOLD_TEMP_LOW :
                    heater_state ="ON"
                    GPIO.output(HEATER_RELAY_PIN, GPIO.LOW )
                elif temperature > (THRESHOLD_TEMP_LOW - HYSTERESIS_TEMP):
                     heater_state = "OFF"
                     GPIO.output(HEATER_RELAY_PIN, GPIO.HIGH )

        # ---------- Mise à jour de la luminosité toutes les 5 secondes et gestion entre 7h et 19h  ----------
        if current_time - last_time_light >= 5:
            last_time_light = current_time
            lux = sensor_tsl.lux or last_lux
            last_lux = lux
            now = datetime.utcnow()

            if start_light_time <= now <= end_light_time:
                if lux < THRESHOLD_LUX_ON:
                        GPIO.output(LAMP_RELAY_PIN, GPIO.LOW)
                        lamp_state = True

                elif lux >= THRESHOLD_LUX_OFF and lamp_state:
                    GPIO.output(LAMP_RELAY_PIN, GPIO.HIGH)
                    lamp_state = False
            else:
                if lamp_state:
                    GPIO.output(LAMP_RELAY_PIN, GPIO.HIGH)
                    lamp_state = False

        # ---------- Remise à zéro du compteur de lumière à 00h00:00 UTC ----------
        now = datetime.utcnow()
        if now.hour == 0 and now.minute == 0 and now.second == 0:
            total_light_on_time = 0

        # ---------- Mise à jour de l'humidité du sol toutes les 60 secondes ----------
        if current_time - last_time_soil >= 60:
            last_time_soil = current_time
            soil_moisture = "SEC" if GPIO.input(SOIL_SENSOR_PIN) else "HUMIDE"
            last_soil_moisture = soil_moisture

            GPIO.output(PUMP_RELAY_PIN, GPIO.LOW if soil_moisture == "SEC" else GPIO.HIGH)

        # ---------- Envoi des données à la base de données ----------
        if any([last_temperature, last_humidity, last_soil_moisture, last_lux]):
            data = [
                {
                    "measurement": "Serre",
                    "time": timestamp,
                    "fields": {
                        "Température": last_temperature,
                        "Humidité": last_humidity,
                        "Humidité du sol":1 if last_soil_moisture == "HUMIDE" else 0 ,
                        "Luminosité": float(last_lux),
                        "Pompe": 1 if last_soil_moisture == "SEC" else 0,
                        "Ventilateur": 1 if fan_state == "ON" else 0,
                        "Chauffage": 1 if heater_state == "ON" else 0,
                        "Lampe": 1 if lamp_state else 0
                    }
                }
            ]
            send_data_to_influx_local(data)

        # ---------- Calcul et affichage des états des composants ----------
        pump_state = "ON" if last_soil_moisture == "SEC" else "OFF"
        fan_state = "ON" if last_temperature >= THRESHOLD_TEMP_HIGH else "OFF"
        heater_state = "ON" if last_temperature < THRESHOLD_TEMP_LOW else "OFF"
        lamp_state_str = "ON" if lamp_state else "OFF"
        
        print(f"{timestamp} | Temp: {last_temperature:.1f}°C | Hum: {last_humidity:.1f}% | Sol: {last_soil_moisture} | Lux: {last_lux:.1f} | "
              f"Pompe: {pump_state} | Ventilateur: {fan_state} | Chauffage: {heater_state} | Lampe: {lamp_state_str}")

        time.sleep(1)

except KeyboardInterrupt:
    print("Programme arrêté par l'utilisateur.")
finally:
    GPIO.cleanup()
