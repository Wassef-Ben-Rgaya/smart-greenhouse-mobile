import firebase_admin
from firebase_admin import credentials, db
from influxdb import InfluxDBClient
import json
import os
import time

# ---------- Connexion à Firebase ----------
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred, {
    "databaseURL": "https://serre-intelligente-bac7c-default-rtdb.europe-west1.firebasedatabase.app/"
})

# ---------- Connexion à InfluxDB ----------
influx_client = InfluxDBClient(host='localhost', port=8086, database='serre_db')

# ---------- Chemin vers le fichier de file d'attente ----------
QUEUE_FILE = "firebase_queue.json"

# ---------- Sauvegarder dans la file locale ----------
def save_to_queue(data):
    if os.path.exists(QUEUE_FILE):
        with open(QUEUE_FILE, "r") as f:
            queue = json.load(f)
    else:
        queue = []

    queue.append(data)

    with open(QUEUE_FILE, "w") as f:
        json.dump(queue, f)
    print("💾 Donnée sauvegardée localement en attente de connexion Firebase.")

# ---------- Envoyer une donnée à Firebase ----------
def send_to_firebase(data):
    try:
        ref = db.reference("/serre_mesures")
        timestamp = data.get("time", str(time.time()))
        ref.child(timestamp).set(data)
        print(f"✅ Donnée envoyée à Firebase : {timestamp}")
        return True
    except Exception as e:
        print(f"❌ Erreur d'envoi Firebase : {e}")
        return False

# ---------- Envoyer les données en file d'attente ----------
def send_queued_data():
    if not os.path.exists(QUEUE_FILE):
        return

    with open(QUEUE_FILE, "r") as f:
        queue = json.load(f)

    new_queue = []
    for data in queue:
        success = send_to_firebase(data)
        if not success:
            new_queue.append(data)

    # Mise à jour de la file si certaines données n'ont pas été envoyées
    with open(QUEUE_FILE, "w") as f:
        json.dump(new_queue, f)

# ---------- Boucle en temps réel ----------
def listen_and_send():
    last_timestamp = None

    while True:
        try:
            result = influx_client.query('SELECT * FROM "Serre" ORDER BY time DESC LIMIT 1')
            points = list(result.get_points())
            if not points:
                continue

            latest = points[0]
            if latest["time"] != last_timestamp:
                last_timestamp = latest["time"]
                send_queued_data()  # Essayer d'abord d'envoyer les anciennes
                success = send_to_firebase(latest)
                if not success:
                    save_to_queue(latest)
            time.sleep(5)  # toutes les 5 secondes
        except Exception as e:
            print(f"Erreur dans la boucle principale : {e}")
            time.sleep(5)

# ---------- Lancer ----------
if __name__ == "__main__":
    listen_and_send()
