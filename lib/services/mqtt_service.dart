import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  final String broker = 'broker.emqx.io';
  final int port = 1883;

  // Topik sesuai dengan ESP32
  final String topicGas = 'project_pantau/sensor/lpg';
  final String topicTemp = 'project_pantau/sensor/suhu';
  final String topicAlert = 'project_pantau/status/bahaya';
  final String topicFanSpeed = 'project_pantau/sensor/fan_speed';
  final String topicFanControl = 'project_pantau/control/fan';
  final String topicHumidity = 'project_pantau/sensor/humidity';

  // Stream Controllers untuk broadcast data
  final StreamController<double> _gasController =
      StreamController<double>.broadcast();
  final StreamController<double> _tempController =
      StreamController<double>.broadcast();
  final StreamController<String> _alertController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<int> _fanSpeedController =
      StreamController<int>.broadcast();
  final StreamController<double> _humidityController =
      StreamController<double>.broadcast();

  Stream<double> get gasStream => _gasController.stream;
  Stream<double> get tempStream => _tempController.stream;
  Stream<String> get alertStream => _alertController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<int> get fanSpeedStream => _fanSpeedController.stream;
  Stream<double> get humidityStream => _humidityController.stream;

  double _currentGas = 0.0;
  double _currentTemp = 0.0;
  String _currentStatus = 'AMAN';
  int _currentFanSpeed = 0;
  double _currentHumidity = 0.0;
  bool _manualMode = false;

  double get currentGas => _currentGas;
  double get currentTemp => _currentTemp;
  String get currentStatus => _currentStatus;
  int get currentFanSpeed => _currentFanSpeed;
  double get currentHumidity => _currentHumidity;
  bool get manualMode => _manualMode;

  Future<void> connect() async {
    client = MqttServerClient.withPort(
      broker,
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        )
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      print('Client exception: $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('Socket exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT Connected');
      _subscribe();
    } else {
      print('Connection failed - disconnecting');
      client.disconnect();
    }
  }

  void _subscribe() {
    client.subscribe(topicGas, MqttQos.atLeastOnce);
    client.subscribe(topicTemp, MqttQos.atLeastOnce);
    client.subscribe(topicAlert, MqttQos.atLeastOnce);
    client.subscribe(topicFanSpeed, MqttQos.atLeastOnce);
    client.subscribe(topicHumidity, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        message.payload.message,
      );
      final topic = c[0].topic;

      if (topic == topicGas) {
        _currentGas = double.tryParse(payload) ?? 0.0;
        _gasController.add(_currentGas);
      } else if (topic == topicTemp) {
        _currentTemp = double.tryParse(payload) ?? 0.0;
        _tempController.add(_currentTemp);
      } else if (topic == topicAlert) {
        _currentStatus = payload;
        _alertController.add(_currentStatus);
      } else if (topic == topicFanSpeed) {
        _currentFanSpeed = int.tryParse(payload) ?? 0;
        _fanSpeedController.add(_currentFanSpeed);
      } else if (topic == topicHumidity) {
        _currentHumidity = double.tryParse(payload) ?? 0.0;
        _humidityController.add(_currentHumidity);
      }
    });
  }

  void setFanSpeed(int speed) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(speed.toString());
      client.publishMessage(
        topicFanControl,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }
  }

  void setManualMode(bool manual) {
    _manualMode = manual;
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(manual ? 'MANUAL' : 'AUTO');
      client.publishMessage(
        'project_pantau/control/mode',
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    }
  }

  void _onConnected() {
    print('Connected to MQTT Broker');
    _connectionController.add(true);
  }

  void _onDisconnected() {
    print('Disconnected from MQTT Broker');
    _connectionController.add(false);
  }

  void disconnect() {
    client.disconnect();
  }

  void dispose() {
    _gasController.close();
    _tempController.close();
    _alertController.close();
    _connectionController.close();
    _fanSpeedController.close();
    _humidityController.close();
  }
}
