extends Node

# MQTT client implementation in GDScript
# Loosely based on https://github.com/pycom/pycom-libraries/blob/master/lib/mqtt/mqtt.py
# and initial work by Alex J Lennon <ajlennon@dynamicdevices.co.uk>
# but then heavily rewritten to follow https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html
# Updated by Andrew C Mattson for use in LUMINSim, derived from work done on SymergyGodot/SymergySim:
# * https://github.com/acmattson3/SymergyGodot
# * https://github.com/acmattson3/SymergySim

## LUMINSim (Custom) Logic

func get_dict_from_json_string(json_string: String):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		if data_received is Dictionary:
			return data_received
		else:
			print("Unexpected incoming data (non-dictionary).")
			return null
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return null

func _on_received_message(topic: String, message) -> void:
	var topic_portions = topic.split('/')
	var incoming_structure = get_dict_from_json_string(message)
	match len(topic_portions):
		# Update to match expecting incoming topic lengths (from a standard)!
		_:
			pass

func _on_broker_connected(in_mqtt_host):
	print("Connected to the MQTT broker: ", in_mqtt_host)

func _on_broker_connection_failed(in_mqtt_host):
	print("Failed to connect to the MQTT broker: ", in_mqtt_host)

func is_connected_to_broker() -> bool:
	return broker_connect_mode == BCM_CONNECTED

func get_structure() -> Dictionary:
	return {}

func has_structure() -> bool:
	return false
	#if meter_structure.keys().size() > 0:
	#	return true
	#else:
	#	return false

func get_broker_hostname() -> String:
	return mqtt_host

## MQTT LOGIC
@export var client_id = ""
@export var verbose_level = 1  # 0 quiet, 1 connections and subscriptions, 2 all messages
@export var binary_messages = false
@export var ping_interval = 30

var socket = null
var sslsocket = null
var websocket = null

const BCM_NOCONNECTION = 0
const BCM_WAITING_WEBSOCKET_CONNECTION = 1
const BCM_WAITING_SOCKET_CONNECTION = 2
const BCM_WAITING_SSL_SOCKET_CONNECTION = 3
const BCM_FAILED_CONNECTION = 5
const BCM_WAITING_CONNMESSAGE = 10
const BCM_WAITING_CONNACK = 19
const BCM_CONNECTED = 20

var broker_connect_mode = BCM_NOCONNECTION

var regex_broker_url = RegEx.new()

const DEFAULTbroker_port_TCP = 1883
const DEFAULTbroker_port_SSL = 8886
const DEFAULTbroker_port_WS = 8080
const DEFAULTbroker_port_WSS = 8081

const CP_PINGREQ = 0xc0
const CP_PINGRESP = 0xd0
const CP_CONNACK = 0x20
const CP_CONNECT = 0x10
const CP_PUBLISH = 0x30
const CP_SUBSCRIBE = 0x82
const CP_UNSUBSCRIBE = 0xa2
const CP_PUBREC = 0x40
const CP_SUBACK = 0x90
const CP_UNSUBACK = 0xb0

var pid = 0
var user = null
var pswd = null
var keep_alive = 120
var lw_topic = null
var lw_msg = null
var lw_qos = 0
var lw_retain = false

signal received_message(topic, message)
signal broker_connected(mqtt_host: String)
signal broker_disconnected(mqtt_host: String)
signal broker_connection_failed(mqtt_host: String)
signal publish_acknowledge(pid)
signal published_messages(messages: Dictionary)

var received_buffer : PackedByteArray = PackedByteArray()

var common_name = null

func send_data(data):
	var E = 0
	if sslsocket != null:
		E = sslsocket.put_data(data)
	elif socket != null:
		E = socket.put_data(data)
	elif websocket != null:
		E = websocket.put_packet(data)
	if E != 0:
		print("bad send_data packet E=", E)
		
	
func receive_into_buffer():
	if sslsocket != null:
		var sslsocket_status = sslsocket.get_status()
		if sslsocket_status == StreamPeerTLS.STATUS_CONNECTED or sslsocket_status == StreamPeerTLS.STATUS_HANDSHAKING:
			var E = sslsocket.poll()
			if E != 0:
				printerr("Socket poll error: ", E)
				return E
			var n = sslsocket.get_available_bytes()
			if n == -1:
				printerr("get_available_bytes returned -1")
				return FAILED
			if n != 0:
				assert (n > 0)
				var sv = sslsocket.get_data(n)
				assert (sv[0] == 0)  # error code
				received_buffer.append_array(sv[1])
				
	elif socket != null and socket.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var E = socket.poll()
		if E != 0:
			printerr("Socket poll error: ", E)
			return E
		var n = socket.get_available_bytes()
		if n == -1:
			printerr("get_available_bytes returned -1")
			return FAILED
		if n != 0:
			assert (n > 0)
			var sv = socket.get_data(n)
			assert (sv[0] == 0)  # error code
			received_buffer.append_array(sv[1])
			
	elif websocket != null:
		websocket.poll()
		while websocket.get_available_packet_count() != 0:
			received_buffer.append_array(websocket.get_packet())
	
var ping_ticks_next_0 = 0

var buffered_messages := {}
func queue_message(topic: String, payload: String):
	buffered_messages[topic] = payload

func publish_buffered_messages():
	if buffered_messages == {}:
		return # Nothing to process!
	for topic in buffered_messages.keys():
		publish(topic, buffered_messages[topic])
	
	published_messages.emit(buffered_messages)
	
	buffered_messages = {}

func _network_process(_delta: float) -> void:
	publish_buffered_messages()

func _process(_delta: float):
	if broker_connect_mode == BCM_NOCONNECTION:
		pass
	elif broker_connect_mode == BCM_WAITING_WEBSOCKET_CONNECTION:
		websocket.poll()
		var websocket_state = websocket.get_ready_state()
		if websocket_state == WebSocketPeer.STATE_CLOSED:
			if verbose_level:
				print("WebSocket closed with code: %d, reason %s." % [websocket.get_close_code(), websocket.get_close_reason()])
			broker_connect_mode = BCM_FAILED_CONNECTION
			emit_signal("broker_connection_failed", mqtt_host)
		elif websocket_state == WebSocketPeer.STATE_OPEN:
			broker_connect_mode = BCM_WAITING_CONNMESSAGE
			if verbose_level:
				print("Websocket connection now open")
			
	elif broker_connect_mode == BCM_WAITING_SOCKET_CONNECTION:
		socket.poll()
		var socket_status = socket.get_status()
		if socket_status == StreamPeerTCP.STATUS_ERROR:
			if verbose_level:
				print("TCP socket error")
			broker_connect_mode = BCM_FAILED_CONNECTION
			emit_signal("broker_connection_failed", mqtt_host)
		if socket_status == StreamPeerTCP.STATUS_CONNECTED:
			broker_connect_mode = BCM_WAITING_CONNMESSAGE

	elif broker_connect_mode == BCM_WAITING_SSL_SOCKET_CONNECTION:
		socket.poll()
		var socket_status = socket.get_status()
		if socket_status == StreamPeerTCP.STATUS_ERROR:
			if verbose_level:
				print("TCP socket error before SSL")
			broker_connect_mode = BCM_FAILED_CONNECTION
			emit_signal("broker_connection_failed", mqtt_host)
		if socket_status == StreamPeerTCP.STATUS_CONNECTED:
			if sslsocket == null:
				sslsocket = StreamPeerTLS.new()
				if verbose_level:
					print("Connecting socket to SSL with common_name=", common_name)
				var E3 = sslsocket.connect_to_stream(socket, common_name)
				if E3 != 0:
					print("bad sslsocket.connect_to_stream E=", E3)
					broker_connect_mode = BCM_FAILED_CONNECTION
					emit_signal("broker_connection_failed", mqtt_host)
					sslsocket = null
			if sslsocket != null:
				sslsocket.poll()
				var sslsocket_status = sslsocket.get_status()
				if sslsocket_status == StreamPeerTLS.STATUS_CONNECTED:
					broker_connect_mode = BCM_WAITING_CONNMESSAGE
				elif sslsocket_status >= StreamPeerTLS.STATUS_ERROR:
					print("bad sslsocket.connect_to_stream")
					emit_signal("broker_connection_failed", mqtt_host)
				
	elif broker_connect_mode == BCM_WAITING_CONNMESSAGE:
		send_data(first_message_to_server())
		broker_connect_mode = BCM_WAITING_CONNACK
		
	elif broker_connect_mode == BCM_WAITING_CONNACK or broker_connect_mode == BCM_CONNECTED:
		receive_into_buffer()
		while wait_msg():
			pass
		if broker_connect_mode == BCM_CONNECTED and ping_ticks_next_0 < Time.get_ticks_msec():
			pingreq()
			ping_ticks_next_0 = Time.get_ticks_msec() + ping_interval*1000

	elif broker_connect_mode == BCM_FAILED_CONNECTION:
		cleanup_sockets()

var mqtt_host: String = ""
func _ready():
	process_mode=PROCESS_MODE_ALWAYS
	
	regex_broker_url.compile('^(tcp://|wss://|ws://|ssl://)?([^:\\s]+)(:\\d+)?(/\\S*)?$')
	if client_id == "":
		randomize()
		client_id = "rr%d" % randi()
	
	# Connect signals
	broker_connected.connect(_on_broker_connected)
	received_message.connect(_on_received_message)
	broker_connection_failed.connect(_on_broker_connection_failed)
	#broker_disconnected.connect(_on_broker_disconnected)
	GameManager.network_process.connect(_network_process)
	
	var mqtt_user = ""
	var mqtt_pass = ""
	
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--mqtt-host" and i + 1 < args.size():
			mqtt_host = args[i + 1]
		elif args[i] == "--mqtt-user" and i + 1 < args.size():
			mqtt_user = args[i + 1]
		elif args[i] == "--mqtt-pass" and i + 1 < args.size():
			mqtt_pass = args[i + 1]
	print("Username is: "+mqtt_user if mqtt_user != "" else "WARN: Username is empty string!")
	print("Password is not empty." if mqtt_pass != "" else "WARN: Password is empty string!")
	MQTTHandler.set_user_pass(mqtt_user, mqtt_pass)
	
	if mqtt_host != "":
		MQTTHandler.connect_to_broker(mqtt_host)

func set_last_will(s_topic, s_msg, retain=false, qos=0):
	assert((0 <= qos) and (qos <= 2))
	assert(s_topic)
	self.lw_topic = s_topic.to_ascii_buffer()
	self.lw_msg = s_msg if binary_messages else s_msg.to_ascii_buffer()
	self.lw_qos = qos
	self.lw_retain = retain
	if verbose_level:
		print("LASTWILL%s topic=%s msg=%s" % [ " <retain>" if retain else "", s_topic, s_msg])

func set_user_pass(suser, spswd):
	if suser != null:
		self.user = suser.to_ascii_buffer()
		self.pswd = spswd.to_ascii_buffer()
	else:
		self.user = null
		self.pswd = null


static func encode_remaining_length(pkt, sz):
	assert(sz < 2097152)
	var i = 1
	while sz > 0x7f:
		pkt[i] = (sz & 0x7f) | 0x80
		sz >>= 7
		i += 1
		if i + 1 > len(pkt):
			pkt.append(0x00);
	pkt[i] = sz

static func encode_short_int(pkt, n):
	assert (n >= 0 and n < 65536)
	pkt.append((n >> 8) & 0xFF)
	pkt.append(n & 0xFF)

static func encode_var_str(pkt, bs):
	encode_short_int(pkt, len(bs))
	pkt.append_array(bs)

func first_message_to_server():
	var clean_session = true
	var pkt = PackedByteArray()
	pkt.append(CP_CONNECT);
	pkt.append(0x00);
	var sz = 10 + (2+len(self.client_id)) + \
			(2+len(self.user)+2+len(self.pswd) if self.user != null else 0) + \
			(2+len(self.lw_topic)+2+len(self.lw_msg) if self.lw_topic else 0)
	encode_remaining_length(pkt, sz)
	var remstartpos = len(pkt)
	encode_var_str(pkt, [0x4D, 0x51, 0x54, 0x54]); # "MQTT".to_ascii_buffer()
	var protocol_level = 0x04  # MQTT v3.1.1
	var connect_flags = (0xC0 if self.user != null else 0) | \
					   (0x20 if self.lw_retain else 0) | \
					   (self.lw_qos << 3) | \
					   (0x04 if self.lw_topic else 0) | \
					   (0x02 if clean_session else 0)
	pkt.append(protocol_level);
	pkt.append(connect_flags);
	encode_short_int(pkt, self.keep_alive)
	encode_var_str(pkt, self.client_id.to_ascii_buffer())
	if self.lw_topic:
		encode_var_str(pkt, self.lw_topic)
		encode_var_str(pkt, self.lw_msg)
	if self.user != null:
		encode_var_str(pkt, self.user)
		encode_var_str(pkt, self.pswd)
	assert (len(pkt) - remstartpos == sz)
	return pkt

func cleanup_sockets(retval=false):
	if verbose_level:
		print("cleanup_sockets")
	if socket:
		if sslsocket:
			sslsocket = null
		socket.disconnect_from_host()
		socket = null
	else:
		assert (sslsocket == null)

	if websocket:
		websocket.close()
		websocket = null
	broker_connect_mode = BCM_NOCONNECTION
	return retval

func connect_to_broker(brokerurl):
	assert (broker_connect_mode == BCM_NOCONNECTION)
	var broker_match = regex_broker_url.search(brokerurl)
	if broker_match == null:
		print("ERROR: unrecognized brokerurl pattern:", brokerurl)
		return cleanup_sockets(false)
	var broker_components = broker_match.strings
	var broker_protocol = broker_components[1]
	var broker_server = broker_components[2]
	var is_web_socket = (broker_protocol == "ws://" or broker_protocol == "wss://")
	var is_ssl = (broker_protocol == "ssl://" or broker_protocol == "wss://")
	var broker_port = ((DEFAULTbroker_port_WSS if is_ssl else DEFAULTbroker_port_WS) if is_web_socket else (DEFAULTbroker_port_SSL if is_ssl else DEFAULTbroker_port_TCP))
	if broker_components[3]:
		broker_port = int(broker_components[3].substr(1)) 
	var broker_path = broker_components[4] if broker_components[4] else ""
	
	common_name = null	
	if is_web_socket:
		websocket = WebSocketPeer.new()
		websocket.supported_protocols = PackedStringArray(["mqttv3.1"])
		var websocket_url = ("wss://" if is_ssl else "ws://") + broker_server + ":" + str(broker_port) + broker_path
		if verbose_level:
			print("Connecting to websocket_url: ", websocket_url)
		var E = websocket.connect_to_url(websocket_url)
		if E != 0:
			print("ERROR: websocketclient.connect_to_url Err: ", E)
			return cleanup_sockets(false)
		print("Websocket get_requested_url ", websocket.get_requested_url())
		broker_connect_mode = BCM_WAITING_WEBSOCKET_CONNECTION

	else:
		socket = StreamPeerTCP.new()
		if verbose_level:
			print("Connecting to %s:%s" % [broker_server, broker_port])
		var E = socket.connect_to_host(broker_server, broker_port)
		if E != 0:
			print("ERROR: socketclient.connect_to_url Err: ", E)
			return cleanup_sockets(false)
		if is_ssl:
			broker_connect_mode = BCM_WAITING_SSL_SOCKET_CONNECTION
			common_name = broker_server
		else:
			broker_connect_mode = BCM_WAITING_SOCKET_CONNECTION
	
	mqtt_host = brokerurl
	return true


func disconnect_from_server():
	if broker_connect_mode == BCM_CONNECTED:
		send_data(PackedByteArray([0xE0, 0x00]))
		emit_signal("broker_disconnected", mqtt_host)
	cleanup_sockets()
	

func publish(stopic, smsg, retain=false, qos=0):
	var msg = smsg.to_ascii_buffer() if not binary_messages else smsg
	var topic = stopic.to_ascii_buffer()
	
	var pkt = PackedByteArray()
	pkt.append(CP_PUBLISH | (2 if qos else 0) | (1 if retain else 0));
	pkt.append(0x00);
	var sz = 2 + len(topic) + len(msg) + (2 if qos > 0 else 0)
	encode_remaining_length(pkt, sz)
	var remstartpos = len(pkt)
	encode_var_str(pkt, topic)
	if qos > 0:
		pid += 1
		encode_short_int(pkt, pid)
	pkt.append_array(msg)
	assert (len(pkt) - remstartpos == sz)
	send_data(pkt)
	if verbose_level >= 2:
		print("CP_PUBLISH%s%s topic=%s msg=%s" % [ "[%d]"%pid if qos else "", " <retain>" if retain else "", stopic, smsg])
	return pid

func subscribe(stopic, qos=0):
	pid += 1
	var topic = stopic.to_ascii_buffer()
	var sz = 2 + 2 + len(topic) + 1
	var pkt = PackedByteArray()
	pkt.append(CP_SUBSCRIBE);
	pkt.append(0x00);
	encode_remaining_length(pkt, sz)
	var remstartpos = len(pkt)
	encode_short_int(pkt, pid)
	encode_var_str(pkt, topic)
	pkt.append(qos);
	assert (len(pkt) - remstartpos == sz)
	if verbose_level:
		print("SUBSCRIBE[%d] topic=%s" % [pid, stopic])
	send_data(pkt)

func pingreq():
	if verbose_level >= 2:
		print("PINGREQ")
	send_data(PackedByteArray([CP_PINGREQ, 0x00]))

func unsubscribe(stopic):
	pid += 1
	var topic = stopic.to_ascii_buffer()
	var sz = 2 + 2 + len(topic)
	var pkt = PackedByteArray()
	pkt.append(CP_UNSUBSCRIBE);
	pkt.append(0x00)
	encode_remaining_length(pkt, sz)
	var remstartpos = len(pkt)
	encode_short_int(pkt, pid)
	encode_var_str(pkt, topic)
	if verbose_level:
		print("UNSUBSCRIBE[%d] topic=%s" % [pid, stopic])
	assert (len(pkt) - remstartpos == sz)
	send_data(pkt)

func wait_msg():
	var n = received_buffer.size()
	if n < 2:
		return false
	var op = received_buffer[0]
	var i = 1
	var sz = received_buffer[i] & 0x7f
	while (received_buffer[i] & 0x80):
		i += 1
		if i == n:
			return false
		sz += (received_buffer[i] & 0x7f) << ((i-1)*7)
	i += 1
	if n < i + sz:
		return false
		
	if op == CP_PINGRESP:
		assert (sz == 0)
		if verbose_level >= 2:
			print("PINGRESP")
			
	elif op & 0xf0 == 0x30:
		var topic_len = (received_buffer[i]<<8) + received_buffer[i+1]
		var im = i + 2
		var topic = received_buffer.slice(im, im + topic_len).get_string_from_ascii()
		im += topic_len
		var pid1 = 0
		if op & 6:
			pid1 = (received_buffer[im]<<8) + received_buffer[im+1]
			im += 2
		var data = received_buffer.slice(im, i + sz)
		var msg = data if binary_messages else data.get_string_from_ascii()
		
		if verbose_level >= 2:
			print("received topic=", topic, " msg=", msg)
		emit_signal("received_message", topic, msg)
		
		if op & 6 == 2:
			send_data(PackedByteArray([0x40, 0x02, (pid1 >> 8), (pid1 & 0xFF)]))
		elif op & 6 == 4:
			assert(0)

	elif op == CP_CONNACK:
		assert (sz == 2)
		var retcode = received_buffer[i+1]
		if verbose_level:
			print("CONNACK ret=%02x" % retcode)
		if retcode == 0x00:
			broker_connect_mode = BCM_CONNECTED
			emit_signal("broker_connected", mqtt_host)
		else:
			if verbose_level:
				print("Bad connection retcode=", retcode) # see https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html
			emit_signal("broker_connection_failed", mqtt_host)

	elif op == CP_PUBREC:
		assert (sz == 2)
		var apid = (received_buffer[i]<<8) + received_buffer[i+1]
		if verbose_level >= 2:
			print("PUBACK[%d]" % apid)
		emit_signal("publish_acknowledgewait_msg", apid)

	elif op == CP_SUBACK:
		assert (sz == 3)
		var apid = (received_buffer[i]<<8) + received_buffer[i+1]
		if verbose_level:
			print("SUBACK[%d] ret=%02x" % [apid, received_buffer[i+2]])
		#if received_buffer[i+2] == 0x80:
		#	E = FAILED

	elif op == CP_UNSUBACK:
		assert (sz == 2)
		var apid = (received_buffer[i]<<8) + received_buffer[i+1]
		if verbose_level:
			print("UNSUBACK[%d]" % apid)

	else:
		if verbose_level:
			print("Unknown MQTT opcode op=%x" % op)

	trimreceived_buffer(i + sz)
	return true

func trimreceived_buffer(n):
	if n == received_buffer.size():
		received_buffer = PackedByteArray()
	else:
		assert (n <= received_buffer.size())
		received_buffer = received_buffer.slice(n)
