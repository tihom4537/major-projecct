import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../models/spectral_data_model.dart';

class MqttService extends ChangeNotifier {
  late MqttServerClient _client;
  List<SpectralReading> _dataHistory = [];
  SpectralReading? _latestData;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionError;
  Timer? _retryTimer;
  int _messageCount = 0;

  // Callback for when new data is received (for saving to user)
  Function(SpectralReading)? onDataReceived;

  // Capture mode state
  bool _isCapturing = false;
  List<SpectralReading> _capturedReadings = [];
  Function(SpectralReading)? _captureCallback;

  List<SpectralReading> get dataHistory => _dataHistory;
  SpectralReading? get latestData => _latestData;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isCapturing => _isCapturing;
  String? get connectionError => _connectionError;
  int get messageCount => _messageCount;

  final String _username = 'emqx';
  final String _password = 'public';
  final String _broker = 'broker.emqx.io';
  final int _port = 1883;
  final String _topic = 'emqx/esp8266/blood';

  MqttService() {
    print('═══════════════════════════════════════');
    print('   MQTT Service Initializing');
    print('═══════════════════════════════════════');
    print('Broker: $_broker:$_port');
    print('Topic: $_topic');
    print('═══════════════════════════════════════\n');

    _initializeClient();
    connect();
  }

  void _initializeClient() {
    final clientId = 'FlutterClient-${DateTime.now().millisecondsSinceEpoch}';
    print('🔧 Initializing MQTT Client: $clientId');

    _client = MqttServerClient.withPort(_broker, clientId, _port);

    _client.secure = false;
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 10000;
    _client.autoReconnect = false;

    _client.setProtocolV311();

    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atMostOnce)
        .keepAliveFor(20);

    _client.pongCallback = () {
      print('🏓 PING response received');
    };

    print('✓ Client initialized\n');
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

    try {
      if (_client.connectionStatus?.state == MqttConnectionState.disconnected) {
        _initializeClient();
      }

      final connStatus = await _client.connect(_username, _password);

      if (connStatus?.state == MqttConnectionState.connected) {
        print('✅ CONNECTION SUCCESSFUL!\n');
      } else {
        throw Exception('Connection failed - State: ${connStatus?.state}');
      }
    } on TimeoutException catch (e) {
      _connectionError = 'Connection timeout';
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
      _connectionError = 'No connection';
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
    print('✅ MQTT CONNECTED!');

    _isConnected = true;
    _isConnecting = false;
    _connectionError = null;
    _retryTimer?.cancel();

    _client.subscribe(_topic, MqttQos.atLeastOnce);

    _client.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage>>? c) {
        _handleIncomingMessage(c);
      },
      onError: (error) {
        print('❌ Listener error: $error');
      },
    );

    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('✅ SUBSCRIBED to: $topic');
  }

  void _onDisconnected() {
    print('❌ MQTT DISCONNECTED!');
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleRetry();
  }

  void _handleIncomingMessage(List<MqttReceivedMessage<MqttMessage>>? c) {
    if (c == null || c.isEmpty) return;

    try {
      final recMess = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _messageCount++;
      print('📨 Message #$_messageCount received');

      _parseAndUpdateData(payload);
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    print('⏰ Reconnecting in 10 seconds...');
    _retryTimer = Timer(const Duration(seconds: 10), () {
      connect();
    });
  }

  void _parseAndUpdateData(String jsonString) {
    try {
      final jsonData = jsonDecode(jsonString);
      final data = SpectralReading.fromMqttJson(jsonData);

      _latestData = data;
      _dataHistory.add(data);

      if (_dataHistory.length > 100) {
        _dataHistory.removeAt(0);
      }

      // Notify callback if set
      if (onDataReceived != null) {
        onDataReceived!(data);
      }

      // Handle capture mode
      if (_isCapturing) {
        _capturedReadings.add(data);
        if (_captureCallback != null) {
          _captureCallback!(data);
        }
      }

      notifyListeners();

      print('✅ Data parsed: Label=${data.label}, NIR=${data.channels.nir}');
    } catch (e) {
      print('❌ Parse error: $e');
      print('   Raw: $jsonString');
    }
  }

  // Get channel history for charts
  List<double> getChannelHistory(String channelName, {int maxPoints = 50}) {
    return _dataHistory.reversed.take(maxPoints).map((data) {
      final channels = data.channels;
      switch (channelName) {
        case 'NIR': return channels.nir.toDouble();
        case 'F7_630nm': return channels.f7_630nm.toDouble();
        case 'F8_680nm': return channels.f8_680nm.toDouble();
        case 'Clear': return channels.clearChannel.toDouble();
        default: return 0.0;
      }
    }).toList().reversed.toList();
  }

  void clearHistory() {
    _dataHistory.clear();
    _messageCount = 0;
    notifyListeners();
  }

  // Start capturing readings
  void startCapturing({Function(SpectralReading)? onData}) {
    _isCapturing = true;
    _capturedReadings.clear();
    _captureCallback = onData;
    notifyListeners();
    print('🎯 Started capturing readings');
  }

  // Stop capturing and return captured readings
  List<SpectralReading> stopCapturing() {
    _isCapturing = false;
    final readings = List<SpectralReading>.from(_capturedReadings);
    _captureCallback = null;
    notifyListeners();
    print('🛑 Stopped capturing. Total readings: ${readings.length}');
    return readings;
  }

  // Clear captured readings
  void clearCapturedReadings() {
    _capturedReadings.clear();
    notifyListeners();
  }

  void disconnect() {
    print('🔌 Disconnecting...');
    _retryTimer?.cancel();
    _client.disconnect();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _client.disconnect();
    super.dispose();
  }
}