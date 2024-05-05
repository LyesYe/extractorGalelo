import 'package:flutter/material.dart';
import 'package:raw_gnss/gnss_status_model.dart';
import 'package:raw_gnss/raw_gnss.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GNSS Data Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GNSSDataScreen(),
    );
  }
}

class GNSSDataScreen extends StatefulWidget {
  @override
  _GNSSDataScreenState createState() => _GNSSDataScreenState();
}

class _GNSSDataScreenState extends State<GNSSDataScreen> {
  late RawGnss _gnss;
  Position? _currentPosition;
  List<String> _gnssDataList = ['Fetching GNSS Data...']; // List to store all GNSS data

  @override
  void initState() {
    super.initState();
    _initializeGNSS();
  }

  void _initializeGNSS() {
    _gnss = RawGnss();
    _startGNSSListener();
    _getCurrentLocation();
  }

  void _startGNSSListener() {
    _gnss.gnssStatusEvents.listen((GnssStatusModel event) {
      // Print GNSS data to terminal
      print(event.toJson());
      // Add each GNSS data point to the list
      _gnssDataList.add(event.toJson().toString());
    });
  }

  void _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      print("Error: $e");
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GNSS Data Viewer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GNSS Data:',
              style: TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _gnssDataList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_gnssDataList[index]),
                  );
                },
              ),
            ),
            Text(
              'Current Position: ${_currentPosition != null ? _currentPosition!.latitude.toString() + ', ' + _currentPosition!.longitude.toString() : 'Fetching...'}',
              style: TextStyle(fontSize: 20.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
