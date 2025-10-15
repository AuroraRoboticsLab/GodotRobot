### ****![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXe5FqY4UMQWdXdD3zBoAs6u4yaZ_Kgxmb1iM6qMjnDqiYm177-MhHAGF1wRaUrY46JYHpmzfuha_T3nOxouPQW_cmoY2iifIbNuMqMvy1vIgoh-I0F3I29qjE6wBgS8SWLZ8dqsNQ?key=_KnYEL3z81KoJNWCSyr4dUnM)****

**MQTT Publish/Subscribe Standard for LUMINSim**

By Andrew Mattson
Derived from [Symergy](https://github.com/acmattson3/SymergyGodot)'s MQTT standard by Anand Egan, Andrew Mattson, Kylie Lambries, and Rylan Clavell


# **1. Overview**

This document defines the standard MQTT topic structure and data format for microgrid components interfacing with Symergy systems. The system uses MQTT for structured, real-time data exchange. This document follows [RFC2119](https://datatracker.ietf.org/doc/html/rfc2119) keyword requirements.


# **2. Discovery & Component Structure**

All components in the microgrid must be published to the `symergygrid/meterstructure` in the format defined below.


## **2.1 Meter Structure Definition**

- The meter structure must use a JSON-formatted payload.

- This message must be **retained** so that clients receive the latest microgrid structure upon connection.

- Each listed component in the meter structure must have only the following attributes:

  - **id (string):** An identifier for this component. Must be unique.

  - **type (string):** The type, which should pertain to the component’s purpose (e.g., source, load, meter, line, etc.).

  - **category (string):** The category, which should be a sub-classification of the component’s type (e.g., a source may be solar, wind, hydro, diesel; a load may be commercial, residential, municipal, etc.).

  - **name (string):** The component’s display name. Uniqueness not required.

  - **coordinates (dictionary):**  The geographic location of the component. Must use the string keys `lat`, `lon`, and `alt`, each with floating-point values

  - **connections** **(array):** An array of ids representing physically connected components (see [**Note 5.1**](#51-bidirectional-connections) for more information about how connections are defined). 

**Example Meter Structure Payload (JSON):**

	{
	  "components": [
	    {
	      "id": "panel1",
	      "type": "source",
	      “category”: “solar”,
	      "name": "Panasonic Monocrystalline 300W",
	      "coordinates": {"lat": 64.8378, "lon": -147.7164, "alt": 200.5},
	      "connections": ["generator1", "panel1"]
	    },
	    {
	      "id": "generator1",
	      "type": "source",
	      “category”: “diesel”,
	      "name": "Backup Generator 5kW",
	      "coordinates": {"lat": 64.8370, "lon": -147.7175, "alt": 202.0},
	      "connections": [""]
	    },
	    {
	      "id": "lumbermill",
	      "type": "load",
	      “category”: “commercial”,
	      "name": "Northland Wood Lumbermill",
	      "coordinates": {"lat": 64.8380, "lon": -147.7160, "alt": 204.0}
	      "connections": ["generator1"]
	    }
	  ]
	}


## **2.2 GeoJSON Definition**

Symergy systems may publish a rendered representation of the meterstructure as a GeoJSON FeatureCollection for integration with external visualization or mapping tools. If this is done, the `symergygrid/geojson` topic must be used. This message must be retained.

**Payload Format**:\
&#x20;The payload must be a valid GeoJSON `FeatureCollection` containing:

- One `Point` feature per component in the meterstructure.

- Optional `LineString` features connecting components as defined by their `connections`.

Each `Feature` must include a `properties` object with at least the following keys:

- `id`: Unique identifier of the component.

- `type`: Component type (e.g., source, load, meter).

- `category`: Sub-classification of the component (e.g., solar, diesel).

- `name`: Human-readable name.

- `connections`: List of connected component IDs.

**Example GeoJSON Feature (Point)**:

	{
	  "type": "Feature",
	  "geometry": {
	    "type": "Point",
	    "coordinates": [-147.7164, 64.8378, 200.5]
	  },
	  "properties": {
	    "id": "panel1",
	    "type": "source",
	    "category": "solar",
	    "name": "Panasonic Monocrystalline 300W",
	    "connections": ["generator1"]
	  }
	}

**Example GeoJSON Feature (LineString)**:

	{
	  "type": "Feature",
	  "geometry": {
	    "type": "LineString",
	    "coordinates": [
	      [-147.7164, 64.8378, 200.5],
	      [-147.7175, 64.8370, 202.0]
	    ]
	  },
	  "properties": {
	    "from": "panel1",
	    "to": "generator1"
	  }
	}


# **3. MQTT Topic Structure**

Each component must publish its real-time data under the following topic format:

	symergygrid/components/{type}/{id}/{metric_category}

Metric categories may include demand, power, voltage, energy, and status. Metric categories are built to be extendable as needed by future developers. See [Note 5.2](#52-fully-defined-metrics) for information about a useful extension to this topic structure.


## **3.1 Example Topics**

	symergygrid/components/meters/meter1/demand

	symergygrid/components/meters/meter1/voltage

	symergygrid/components/meters/meter1/power

	symergygrid/components/sources/generator1/status


## **3.2 Expected Topic Message Format**

Data published to these topics must be JSON formatted and have, at minimum, string keys `value` and `unit`. All values of the key `unit` must be strings. A topic payload may look like the following:

	{
	  "value": 5.4,
	  "unit": "kW"
	}


# **4. Data Subscriptions and Publications**

This MQTT standard’s goal is to make data manipulation as easy as possible. Using wildcards, minimal parsing will be required for most data manipulation tasks. For example:

- `symergygrid/components/#` → Receive all microgrid data.

- `symergygrid/components/+/+/power` → Subscribe to all power-related data.

- `symergygrid/components/meters/#` → Subscribe to all meter data.

- `symergygrid/components/sources/+/#` → Subscribe to all incoming source metrics.

- `symergygrid/components/loads/+/voltage` → Subscribe to all voltage data from loads.

All published data should use **QoS 1** (at least once delivery) to ensure reliability without unnecessary retransmissions. QoS 0 and 2 should not be used due to potential message loss or performance overhead.


# **5. Notes**

## **5.1 Bidirectional Connections**

All connections are currently bidirectional. By consequence, only one component is required to define a connection for a connection to be made between them. For example, in the [example meterstructure](https://docs.google.com/document/d/1sOlkPuIQlRntyyuqI_vdXFFqEj5DYwl9rU5BN2eNDlU/edit?tab=t.0#heading=h.d5keuighiocd), `generator1` is connected to both `lumbermill` and `panel1`, despite listing no connections itself, since `lumbermill` and `panel1` define the connections. There will be no difference if both components define the same connection.

Some microgrids may require unidirectional connections for more advanced modeling. Future developers should implement explicit directional connection handling if such behavior is necessary for their use case.


## **5.2 Fully Defined Metrics**

Metrics are for handling lower-level information, important to microgrid developers. For simplicity, the original Symergy systems development team did not use metrics. Future Symergy system developers may want to implement metrics. In that case, the topic structure should be changed to the following:

	symergygrid/components/{type}/{id}/{metric_category}/{metric}

Here are some example metrics for metric categories:

|                     |                                            |
| :-----------------: | :----------------------------------------: |
| **Metric Category** |                 **Metrics**                |
|     `Demand (A)`    |    `phaseA`, `phaseB`, `phaseC`, `peak`    |
|     `Power (kW)`    |        `kW`, `kVA`, `kVAR`, `factor`       |
|    `Voltage (V)`    | `L-L`, `L-N`, `phaseA`, `phaseB`, `phaseC` |
|    `Energy (kWh)`   |   `kWh_forward`, `kWh_net`, `kWh_reverse`  |
|   `Status (bool)`   |      `online`, `fault`, `temperature`      |

Full topics that include metrics may be:

	symergygrid/components/meters/meter1/demand/phaseA

	symergygrid/components/meters/meter1/demand/phaseB

	symergygrid/components/meters/meter1/voltage/L-N

	symergygrid/components/meters/meter1/power/kW

	symergygrid/components/sources/generator1/status/online
