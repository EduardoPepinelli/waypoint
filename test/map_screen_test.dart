import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rota_mapa/main.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  late MockClient mockClient;

  setUp(() {
    // Configura o MockClient para interceptar requisições
    mockClient = MockClient((request) async {
      if (request.url.toString().contains("route")) {
        return http.Response(
          json.encode({
            "routes": [
              {
                "geometry": {
                  "coordinates": [
                    [-98.35, 39.5],
                    [-97.75, 38.9],
                    [-97.0, 38.5]
                  ]
                }
              }
            ]
          }),
          200,
        );
      } else if (request.url.toString().contains("search")) {
        return http.Response(
          json.encode([
            {"lat": "39.5", "lon": "-98.35"}
          ]),
          200,
        );
      }
      return http.Response('Error', 404);
    });
  });

  testWidgets('Teste de busca e definição de ponto A', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final searchFieldA = find.bySemanticsLabel('Buscar Ponto A');
    final searchButtonA = find.widgetWithIcon(IconButton, Icons.search);

    await tester.enterText(searchFieldA, 'Teste Local A');
    await tester.tap(searchButtonA);
    await tester.pump();

    // Verifica se o ponto A foi atualizado corretamente
    expect((tester.firstState(find.byType(MapScreen)) as MapScreenState).pointA, LatLng(39.5, -98.35));
  });

  testWidgets('Teste de busca e definição de ponto B', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final searchFieldB = find.bySemanticsLabel('Buscar Ponto B');
    final searchButtonB = find.widgetWithIcon(IconButton, Icons.search);

    await tester.enterText(searchFieldB, 'Teste Local B');
    await tester.tap(searchButtonB);
    await tester.pump();

    // Verifica se o ponto B foi atualizado corretamente
    expect((tester.firstState(find.byType(MapScreen)) as MapScreenState).pointB, LatLng(39.5, -98.35));
  });

  testWidgets('Teste de cálculo de rota entre ponto A e B', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final state = tester.firstState(find.byType(MapScreen)) as MapScreenState;
    state.pointA = LatLng(39.5, -98.35);
    state.pointB = LatLng(38.5, -97.0);

    await state.getRoute();
    await tester.pump();

    // Verifica se a rota foi calculada certo
    expect(state.routePoints.length, greaterThan(1));
  });
}
