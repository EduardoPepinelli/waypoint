import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Map Routing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? pointA;
  LatLng? pointB;
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getRoute() async {
    if (pointA == null || pointB == null) return;

    final url =
        'http://router.project-osrm.org/route/v1/driving/${pointA!.longitude},${pointA!.latitude};${pointB!.longitude},${pointB!.latitude}?geometries=geojson';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0]['geometry']['coordinates'];
      final List<LatLng> points = route
          .map<LatLng>((point) => LatLng(point[1], point[0]))
          .toList();

      setState(() {
        routePoints = points;
      });
    } else {
      print('Erro ao obter rota: ${response.reasonPhrase}');
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      if (pointA == null) {
        pointA = latlng;
      } else if (pointB == null) {
        pointB = latlng;
        _getRoute();
      } else {
        pointA = latlng;
        pointB = null;
        routePoints.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Roteamento Personalizado'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(39.5, -98.35),
          initialZoom: 4,
          onTap: _onMapTap,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              if (pointA != null)
                Marker(
                  point: pointA!,
                  width: 80.0,
                  height: 80.0,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              if (pointB != null)
                Marker(
                  point: pointB!,
                  width: 80.0,
                  height: 80.0,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
