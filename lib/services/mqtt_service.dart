import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class SensorData {
  final double spectroscopy;
  final double ppg;
  final DateTime timestamp;

  SensorData({required this.spectroscopy, required this.ppg, required this.timestamp});

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      spectroscopy: json['Spectrscopy data']?.toDouble() ?? 0.0,
      ppg: json['PPG Data ']?.toDouble() ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }
}

class MqttService extends ChangeNotifier {
  late MqttServerClient _client;
  List<SensorData> _dataHistory = [];
  SensorData? _latestData;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionError;
  Timer? _retryTimer;
  int _messageCount = 0;

  List<SensorData> get dataHistory => _dataHistory;
  SensorData? get latestData => _latestData;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectionError => _connectionError;
  int get messageCount => _messageCount;

  final String _username = 'emqx';
  final String _password = 'public';
  final String _broker = 'broker.emqx.io';
  final int _port = 1883;
  final String _topic = 'emqx/esp8266/major';  // Centralized topic

  MqttService() {
    print('═══════════════════════════════════════');
    print('   MQTT Service Initializing');
    print('═══════════════════════════════════════');
    print('Broker: $_broker:$_port');
    print('Topic: $_topic');
    print('Username: $_username');
    print('═══════════════════════════════════════\n');

    _initializeClient();
    connect();
  }

  void _initializeClient() {
    final clientId = 'FlutterClient-${DateTime.now().millisecondsSinceEpoch}';
    print('🔧 Initializing MQTT Client: $clientId');

    _client = MqttServerClient.withPort(_broker, clientId, _port);

    // CRITICAL FIX: Set secure to false for plain MQTT
    _client.secure = false;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;  // Reduced from 60
    _client.connectTimeoutPeriod = 10000;  // Increased to 10 seconds
    _client.autoReconnect = false;

    // Set the protocol to V3.1.1 (more compatible)
    _client.setProtocolV311();

    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atMostOnce)  // Changed from atLeastOnce
        .keepAliveFor(20);  // Match keepAlivePeriod

    _client.pongCallback = () {
      print('🏓 PING response received (connection alive)');
    };

    print('✓ Client initialized successfully\n');
  }

  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      print('⚠️  Already ${_isConnecting ? "connecting" : "connected"}');
      return;
    }

    _isConnecting = true;
    _connectionError = null;
    notifyListeners();

    print('🔌 Connecting to MQTT broker...');
    print('   Host: $_broker:$_port');
    print('   Username: $_username');

    try {
      if (_client.connectionStatus?.state == MqttConnectionState.disconnected) {
        print('🔄 Reinitializing client (was disconnected)...');
        _initializeClient();
      }

      final connStatus = await _client.connect(_username, _password);

      print('📊 Connection attempt result:');
      print('   State: ${connStatus?.state}');
      print('   Return Code: ${connStatus?.returnCode}');

      if (connStatus?.state == MqttConnectionState.connected) {
        print('✅ CONNECTION SUCCESSFUL!\n');
      } else {
        final errorMsg = 'Connection failed - State: ${connStatus?.state}, Code: ${connStatus?.returnCode}';
        print('❌ $errorMsg\n');
        throw Exception(errorMsg);
      }
    } on TimeoutException catch (e) {
      _connectionError = 'Connection timeout - Check network/broker availability';
      _isConnecting = false;
      notifyListeners();
      print('❌ TIMEOUT: $e\n');
      _scheduleRetry();
    } on SocketException catch (e) {
      _connectionError = 'Network error - ${e.message}';
      _isConnecting = false;
      notifyListeners();
      print('❌ SOCKET ERROR: $e\n');
      _scheduleRetry();
    } on NoConnectionException catch (e) {
      _connectionError = 'No connection exception - ${e.toString()}';
      _isConnecting = false;
      notifyListeners();
      print('❌ NO CONNECTION: $e\n');
      _scheduleRetry();
    } catch (e) {
      _connectionError = 'Connection failed: ${e.toString()}';
      _isConnecting = false;
      notifyListeners();
      print('❌ ERROR: $e\n');
      _scheduleRetry();
    }
  }

  void _onConnected() {
    print('═══════════════════════════════════════');
    print('   ✅ MQTT CONNECTED!');
    print('═══════════════════════════════════════');

    _isConnected = true;
    _isConnecting = false;
    _connectionError = null;
    _retryTimer?.cancel();

    print('📡 Subscribing to topic: $_topic');
    _client.subscribe(_topic, MqttQos.atLeastOnce);

    print('👂 Setting up message listener...');
    _client.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage>>? c) {
        _handleIncomingMessage(c);
      },
      onError: (error) {
        print('❌ Listener error: $error');
      },
      onDone: () {
        print('⚠️  Listener closed');
      },
    );

    print('✓ Ready to receive messages!\n');
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('═══════════════════════════════════════');
    print('   ✅ SUBSCRIBED to: $topic');
    print('═══════════════════════════════════════');
    print('Waiting for messages from ESP32...\n');
  }

  void _onDisconnected() {
    print('═══════════════════════════════════════');
    print('   ❌ MQTT DISCONNECTED!');
    print('═══════════════════════════════════════\n');

    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleRetry();
  }

  void _handleIncomingMessage(List<MqttReceivedMessage<MqttMessage>>? c) {
    if (c == null || c.isEmpty) {
      print('⚠️  Received empty message list');
      return;
    }

    try {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _messageCount++;

      print('═══════════════════════════════════════');
      print('   📨 MESSAGE #$_messageCount RECEIVED');
      print('═══════════════════════════════════════');
      print('Topic: ${c[0].topic}');
      print('Payload: $payload');
      print('Size: ${payload.length} characters');

      _parseAndUpdateData(payload);

      print('═══════════════════════════════════════\n');
    } catch (e) {
      print('❌ Error handling message: $e\n');
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    print('⏰ Scheduling reconnection in 10 seconds...\n');
    _retryTimer = Timer(const Duration(seconds: 10), () {
      print('🔄 Retry timer triggered - attempting reconnection...\n');
      connect();
    });
  }

  void _parseAndUpdateData(String jsonString) {
    try {
      print('🔍 Parsing JSON...');
      final jsonData = jsonDecode(jsonString);
      print('   Raw JSON: $jsonData');

      final data = SensorData.fromJson(jsonData);
      _latestData = data;
      _dataHistory.add(data);

      if (_dataHistory.length > 50) {
        _dataHistory.removeAt(0);
      }

      notifyListeners();

      print('✅ Data parsed successfully:');
      print('   Spectroscopy: ${data.spectroscopy}');
      print('   PPG: ${data.ppg}');
      print('   Timestamp: ${data.timestamp}');
      print('   History size: ${_dataHistory.length}');
    } catch (e) {
      print('❌ JSON PARSE ERROR: $e');
      print('   Raw data: $jsonString');
      print('   Length: ${jsonString.length} characters');

      // Try to show what went wrong
      try {
        final decoded = jsonDecode(jsonString);
        print('   Decoded structure: ${decoded.runtimeType}');
        print('   Keys: ${decoded is Map ? decoded.keys.toList() : "Not a map"}');
      } catch (e2) {
        print('   Could not decode at all: $e2');
      }
    }
  }

  void disconnect() {
    print('🔌 Manual disconnect requested');
    _retryTimer?.cancel();
    _client.disconnect();
  }

  @override
  void dispose() {
    print('🗑️  Disposing MQTT service');
    _retryTimer?.cancel();
    _client.disconnect();
    super.dispose();
  }
}