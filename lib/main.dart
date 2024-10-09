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
  TextEditingController searchControllerA = TextEditingController();
  TextEditingController searchControllerB = TextEditingController();

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

  Future<LatLng?> _searchLocation(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      } else {
        print('Nenhum resultado encontrado.');
        return null;
      }
    } else {
      print('Erro ao buscar local: ${response.reasonPhrase}');
      return null;
    }
  }

  void _searchAndSetPointA() async {
    final result = await _searchLocation(searchControllerA.text);
    if (result != null) {
      setState(() {
        pointA = result;
        if (pointB != null) {
          _getRoute();
        }
      });
    }
  }

  void _searchAndSetPointB() async {
    final result = await _searchLocation(searchControllerB.text);
    if (result != null) {
      setState(() {
        pointB = result;
        if (pointA != null) {
          _getRoute();
        }
      });
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
        title: Text('Mapa de Roteamento com Busca'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchControllerA,
                    decoration: InputDecoration(
                      labelText: 'Buscar Ponto A',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchAndSetPointA,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchControllerB,
                    decoration: InputDecoration(
                      labelText: 'Buscar Ponto B',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchAndSetPointB,
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
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
          ),
        ],
      ),
    );
  }
}
