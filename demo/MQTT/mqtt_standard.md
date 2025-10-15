# MQTT Publish/Subscribe Standard for LUMINSim
By Andrew Mattson
Derived from [Symergy](https://github.com/acmattson3/SymergyGodot)'s MQTT standard by Anand Egan, Andrew Mattson, Kylie Lambries, and Rylan Clavell


# **1. Overview**
This document defines the standard MQTT topic structure and data format for automation systems interfacing with LUMINSim-based robots. MQTT is chosen for structured, asynchronous, real-time data exchange. This document follows [RFC2119](https://datatracker.ietf.org/doc/html/rfc2119) keyword requirements.


# **2. Discovery & Infrastructure**
LUMINSim must publish available robots to the `luminsim/infrastructure` topic in the format defined below.

## **2.1 Infrastructure Definition**
- The structure must use a JSON-formatted payload.
- This message must be **retained** so that clients receive the latest structure upon connection.
- The key for each infrastructure must indicate the infrastructure's type (e.g., robot, tower, station, etc.).

### Robots
Each listed robot in the structure must be listed under the "robots" key, and must have at least the following attributes:
- **id (string):** An identifier for this robot. Must be unique.
- **model (string):** The model, which should pertain to the robot's model (e.g., astra, excahauler, etc.).
- **name (string):** The component’s display name. Uniqueness not required.

### Other Infrastructure
The structure is contained within a dictionary so the standard may be extended to include information on towers, satellites, and other infrastructure.

## 2.2 Example Infratructure Payload (JSON):

	{
	  "robots": [
	    {
	      "id": "astra1",
	      "model": "astra",
	      "name": "Andrew's Astra",
	    },
	    {
	      "id": "excahauler1",
	      "model": "excahauler",
	      "name": "Dr. Lawlor's Excahauler",
	    },
	    {
	      "id": "astra2",
	      "model": "astra",
	      "name": "Elliott's Astra",
	    }
	  ]
	}


# **3. MQTT Topic Structure**
**Definitions of following terminologies:**
- **Component:** An element within the LUMINSim infrastructure.
- **Incoming:** Refers to data to be received by infrastructure.
- **Outgoing:** Refers to data published by infrastructure.

Each component must publish outgoing data under the following topic format:

	luminsim/components/{type}/{id}/outgoing/{metric_category}

Outgoing metric categories should be telemetry, including but not limited to status, power, and sensor data. 

Each component must subscribe to incoming data under the following topic format:

	luminsim/components/{type}/{id}/incoming/{metric_category}

Incoming metric categories should be commands, including but not limited to drive values and arm position values.

## **3.1 Example Topics**

	luminsim/components/robots/astra1/outgoing/status

	luminsim/components/robots/excahauler1/incoming/drive-values

	luminsim/components/satellites/lunanet-sat-1/status

## **3.2 Expected Topic Message Format**
Data published to these topics must be JSON formatted. Data may have string keys `value` and `unit`. All values of the key `unit` must be strings. A topic payload may look like the following:

	{
	  "value": 5.4,
	  "unit": "kW"
	}


# **4. Data Subscriptions and Publications**
This MQTT standard’s goal is to make data transfer and manipulation as easy as possible. Using wildcards, minimal parsing will be required for most data manipulation tasks. For example:

- `luminsim/components/#` → Receive all live infrastructure data.

- `luminsim/components/+/+/+/power` → Subscribe to all power-related data.

- `luminsim/components/satellite/#` → Subscribe to all satellite data.

- `luminsim/components/robots/+/outgoing/#` → Subscribe to all outgoing robot data.

- `luminsim/components/towers/+/outgoing/status` → Subscribe to all status data from towers.

All data should use **QoS 1** (at least once delivery) to ensure reliability without unnecessary retransmissions. QoS 0 and 2 should not be used due to potential message loss or performance overhead.
