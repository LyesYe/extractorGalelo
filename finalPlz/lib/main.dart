import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:raw_gnss/gnss_measurement_model.dart';
import 'package:raw_gnss/gnss_status_model.dart';
import 'package:raw_gnss/raw_gnss.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNSS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GNSSHomeScreen(),
    );
  }
}

class GNSSHomeScreen extends StatefulWidget {
  @override
  _GNSSHomeScreenState createState() => _GNSSHomeScreenState();
}

class _GNSSHomeScreenState extends State<GNSSHomeScreen> {
  bool _hasPermissions = false;
  late RawGnss _gnss;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<GnssStatusModel>? _gnssStatusStreamSubscription;

  @override
  void initState() {
    super.initState();
    _gnss = RawGnss();
    _requestLocationPermission();
    _startPositionUpdates();
    _startGnssStatusUpdates();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _gnssStatusStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final permissionStatus = await Geolocator.requestPermission();
    setState(() {
      _hasPermissions = permissionStatus == LocationPermission.always ||
          permissionStatus == LocationPermission.whileInUse;
    });

    if (_hasPermissions) {
      _startPositionUpdates();
    }
  }

  void _startPositionUpdates() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
          // Handle position updates here
          print('Position update: $position');
        });
  }

  void _startGnssStatusUpdates() {
    _gnssStatusStreamSubscription =
        _gnss.gnssStatusEvents.listen((GnssStatusModel gnssStatus) {
          final jsonData = gnssStatusModelToJson(gnssStatus);
          _sendData(jsonData);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GNSS Data'),
      ),
      body: _hasPermissions
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StreamBuilder<GnssMeasurementModel>(
              stream: _gnss.gnssMeasurementEvents,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final measurementData = snapshot.data!;
                  final measurementJsonData =
                  gnssMeasurementModelToJson(measurementData);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GNSS Measurement Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        child: Text(
                          measurementJsonData,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<GnssStatusModel>(
              stream: _gnss.gnssStatusEvents,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final statusData = snapshot.data!;
                  final statusJsonData =
                  gnssStatusModelToJson(statusData);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GNSS Status Data',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      SingleChildScrollView(
                        child: Text(
                          statusJsonData,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      )
          : Center(
        child: Text('Location permission not granted!'),
      ),
    );
  }

  Future<void> _sendData(String jsonData) async {
    final response = await http.post(
      Uri.parse('https://example.com/api/endpoint'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonData,
    );

    if (response.statusCode == 200) {
      print('Data sent successfully');
    } else {
      print('Failed to send data. Error code: ${response.statusCode}');
    }
  }
}

String gnssStatusModelToJson(GnssStatusModel data) =>
    json.encode(data.toJson());
