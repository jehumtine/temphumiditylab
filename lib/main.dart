import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature and Humidity Dashboard',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<SensorData> sensorData = [];
  bool isLoading = true;
  String errorMessage = '';
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchData();

    // Set up timer to refresh data every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
      });


      final response = await http.get(Uri.parse('http://192.168.246.193:5000/api/data'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<SensorData> data = jsonData.map((item) => SensorData.fromJson(item)).toList();

        // Sort data by timestamp
        data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        setState(() {
          sensorData = data;
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  SensorData? get latestData {
    return sensorData.isNotEmpty ? sensorData.last : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text('Jehu Mtine N',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(' - ', style: TextStyle(color: Colors.grey)),
            Text('2021510697', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: isLoading && sensorData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main chart card
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade800),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperature and Humidity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: sensorData.isEmpty
                        ? const Center(child: Text('No data available'))
                        : SimpleChartWidget(sensorData: sensorData),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 4,
                            color: const Color(0xFFCCFF00), // Lime green for humidity
                          ),
                          const SizedBox(width: 8),
                          const Text('Humidity Sensor'),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 4,
                            color: Colors.orange, // Orange for temperature
                          ),
                          const SizedBox(width: 8),
                          const Text('Temperature Sensor'),
                        ],
                      ),
                    ],
                  ),
                  if (latestData != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Last updated: ${formatTimestamp(latestData!.timestamp)}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Gauges row
            Row(
              children: [
                // Temperature gauge
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Temperature in Celcius',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        latestData != null
                            ? CircularPercentIndicator(
                          radius: 80,
                          lineWidth: 15,
                          percent: double.parse(latestData!.temperature) / 100,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                latestData!.temperature,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'C°',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          progressColor: const Color(0xFFCCFF00), // Lime green
                          backgroundColor: Colors.grey.shade800,
                          circularStrokeCap: CircularStrokeCap.round,
                          startAngle: 150,
                          animation: true,
                          animationDuration: 1000,
                        )
                            : const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('0'),
                            Text('100'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Humidity gauge
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Relative Humidity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        latestData != null
                            ? CircularPercentIndicator(
                          radius: 80,
                          lineWidth: 15,
                          percent: double.parse(latestData!.humidity) / 100,
                          center: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                latestData!.humidity,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                '% Humidity',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          progressColor: const Color(0xFFCCFF00), // Lime green
                          backgroundColor: Colors.grey.shade800,
                          circularStrokeCap: CircularStrokeCap.round,
                          startAngle: 150,
                          animation: true,
                          animationDuration: 1000,
                        )
                            : const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('0'),
                            Text('100'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(DateTime timestamp) {
    final formatter = DateFormat('MMM d, yyyy HH:mm:ss');
    return formatter.format(timestamp);
  }
}

class SensorData {
  final int id;
  final String temperature;
  final String humidity;
  final DateTime timestamp;

  SensorData({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      temperature: json['temperature'],
      humidity: json['humidity'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class SimpleChartWidget extends StatelessWidget {
  final List<SensorData> sensorData;

  const SimpleChartWidget({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    // Use only the last 20 data points for the chart to avoid overcrowding
    final displayData = sensorData.length > 20
        ? sensorData.sublist(sensorData.length - 20)
        : sensorData;

    return CustomPaint(
      size: Size.infinite,
      painter: ChartPainter(sensorData: displayData),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<SensorData> sensorData;

  ChartPainter({
    required this.sensorData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sensorData.isEmpty) return;

    // Find min and max values to scale the chart properly
    double minTemp = 100.0;
    double maxTemp = 0.0;
    double minHum = 100.0;
    double maxHum = 0.0;

    for (var data in sensorData) {
      final temp = double.parse(data.temperature);
      final hum = double.parse(data.humidity);

      if (temp < minTemp) minTemp = temp;
      if (temp > maxTemp) maxTemp = temp;
      if (hum < minHum) minHum = hum;
      if (hum > maxHum) maxHum = hum;
    }

    // Add a small buffer for better visualization
    minTemp = (minTemp - 2).clamp(0, 100);
    maxTemp = (maxTemp + 2).clamp(0, 100);
    minHum = (minHum - 5).clamp(0, 100);
    maxHum = (maxHum + 5).clamp(0, 100);

    // Draw grid background
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 1;

    // Horizontal grid lines
    double gridHeight = size.height / 5;
    for (int i = 0; i <= 5; i++) {
      double y = i * gridHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    int numPoints = sensorData.length;
    for (int i = 0; i <= numPoints; i++) {
      double x = i * size.width / numPoints;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw temperature line
    final tempPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final tempPath = Path();
    for (int i = 0; i < sensorData.length; i++) {
      double x = i * size.width / (sensorData.length - 1);
      double tempValue = double.parse(sensorData[i].temperature);

      // Scale temperature value to fit chart
      double normalizedTemp = (tempValue - minTemp) / (maxTemp - minTemp).clamp(0.1, 100);
      double y = size.height - (normalizedTemp * size.height);

      if (i == 0) {
        tempPath.moveTo(x, y);
      } else {
        tempPath.lineTo(x, y);
      }
    }

    canvas.drawPath(tempPath, tempPaint);

    // Draw humidity line
    final humidityPaint = Paint()
      ..color = Color(0xFFCCFF00)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final humidityPath = Path();
    for (int i = 0; i < sensorData.length; i++) {
      double x = i * size.width / (sensorData.length - 1);
      double humValue = double.parse(sensorData[i].humidity);

      // Scale humidity value to fit chart
      double normalizedHum = (humValue - minHum) / (maxHum - minHum).clamp(0.1, 100);
      double y = size.height - (normalizedHum * size.height);

      if (i == 0) {
        humidityPath.moveTo(x, y);
      } else {
        humidityPath.lineTo(x, y);
      }
    }

    canvas.drawPath(humidityPath, humidityPaint);

    // Draw labels
    const textStyle = TextStyle(color: Colors.grey, fontSize: 10);
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Y-axis temperature labels
    textPainter.text = TextSpan(
      text: "${maxTemp.toStringAsFixed(1)}°C",
      style: const TextStyle(color: Colors.orange, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 5));

    textPainter.text = TextSpan(
      text: "${minTemp.toStringAsFixed(1)}°C",
      style: const TextStyle(color: Colors.orange, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, size.height - textPainter.height - 5));

    // Y-axis humidity labels
    textPainter.text = TextSpan(
      text: "${maxHum.toStringAsFixed(1)}%",
      style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 5, 5));

    textPainter.text = TextSpan(
      text: "${minHum.toStringAsFixed(1)}%",
      style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 5, size.height - textPainter.height - 5));

    // X-axis time labels (show only a few for readability)
    if (sensorData.length > 1) {
      final timeFormat = DateFormat('HH:mm');

      // Show first timestamp
      textPainter.text = TextSpan(
        text: timeFormat.format(sensorData.first.timestamp),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, size.height - textPainter.height));

      // Show middle timestamp
      int middleIndex = sensorData.length ~/ 2;
      textPainter.text = TextSpan(
        text: timeFormat.format(sensorData[middleIndex].timestamp),
        style: textStyle,
      );
      textPainter.layout();
      double middleX = middleIndex * size.width / (sensorData.length - 1);
      textPainter.paint(canvas, Offset(middleX - textPainter.width / 2, size.height - textPainter.height));

      // Show last timestamp
      textPainter.text = TextSpan(
        text: timeFormat.format(sensorData.last.timestamp),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width, size.height - textPainter.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}