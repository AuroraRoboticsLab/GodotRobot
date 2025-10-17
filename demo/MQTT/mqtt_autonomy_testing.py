#!/usr/bin/env python3
"""
LUMINSim Mass Drive Script (Case-Sensitive IDs + Autonomy Enable)
- Discovers robots from retained 'luminsim/infrastructure'
- Enables autonomy via 'incoming/status' -> {"autonomous": true}
- Repeats: forward 1s, wait 1s, right 1s, wait 1s
- QoS 1 everywhere (per standard)
"""

import json
import time
import paho.mqtt.client as mqtt

BROKER = "localhost"
INFRA_TOPIC = "luminsim/infrastructure"
DRIVE_TOPIC_FMT = "luminsim/components/robots/{}/incoming/drive-values"
STATUS_TOPIC_FMT = "luminsim/components/robots/{}/incoming/status"

AUTONOMY_HEARTBEAT_SEC = 10  # re-assert autonomy periodically

robots = {}
_last_autonomy_ts = 0.0

# ---- MQTT Callbacks ----
def on_connect(client, userdata, flags, rc):
    print("Connected with result code", rc)
    client.subscribe(INFRA_TOPIC, qos=1)

def on_message(client, userdata, msg):
    if msg.topic == INFRA_TOPIC:
        try:
            payload = json.loads(msg.payload.decode())
        except Exception as e:
            print("Bad infrastructure payload:", e)
            return
        if "robots" in payload and isinstance(payload["robots"], dict):
            userdata["robots"].clear()
            for rid, info in payload["robots"].items():
                userdata["robots"][rid] = info
            print(f"Discovered robots: {list(userdata['robots'].keys())}")
            enable_autonomy_all(client)  # ensure new arrivals get autonomy

# ---- Helpers ----
def drive_all(client, x=0.0, y=0.0, z=0.0):
    """Send drive-values to all robots (case-sensitive IDs)."""
    payload = json.dumps({"x": x, "y": y, "z": z})
    for rid in list(robots.keys()):
        topic = DRIVE_TOPIC_FMT.format(rid)
        client.publish(topic, payload, qos=1)
        print(f"→ {topic}: {payload}")

def enable_autonomy_all(client):
    """Publish {'autonomous': true} to each robot's incoming/status."""
    global _last_autonomy_ts
    payload = json.dumps({"autonomous": True})
    for rid in list(robots.keys()):
        topic = STATUS_TOPIC_FMT.format(rid)
        client.publish(topic, payload, qos=1)
        print(f"→ {topic}: {payload}")
    _last_autonomy_ts = time.time()

def disable_autonomy_all(client):
    """Publish {'autonomous': false} to each robot's incoming/status."""
    global _last_autonomy_ts
    payload = json.dumps({"autonomous": False})
    for rid in list(robots.keys()):
        topic = STATUS_TOPIC_FMT.format(rid)
        client.publish(topic, payload, qos=1)
        print(f"→ {topic}: {payload}")
    _last_autonomy_ts = time.time()

# ---- Main ----
def main():
    client = mqtt.Client(userdata={"robots": robots})
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(BROKER)
    client.loop_start()

    print("Waiting for infrastructure discovery...")
    while not robots:
        time.sleep(0.25)

    print("Robots ready:", robots)
    enable_autonomy_all(client)

    try:
        while True:
            # Re-assert autonomy periodically (helps after robot restarts)
            if time.time() - _last_autonomy_ts >= AUTONOMY_HEARTBEAT_SEC:
                enable_autonomy_all(client)

            # Drive forward 1s
            drive_all(client, z=-1.0)
            time.sleep(1)

            # Stop 1s
            drive_all(client, x=0.0, y=0.0, z=0.0)
            time.sleep(1)

            # Turn right 1s
            drive_all(client, x=1.0)
            time.sleep(1)

            # Stop 1s
            drive_all(client, x=0.0, y=0.0, z=0.0)
            time.sleep(1)

    except KeyboardInterrupt:
        print("\nStopping...")
        disable_autonomy_all(client)
    finally:
        client.loop_stop()
        client.disconnect()

if __name__ == "__main__":
    main()
