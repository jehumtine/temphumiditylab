import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'main.dart';

class DetailChartPage extends StatefulWidget {
  final List<SensorData> sensorData;

  const DetailChartPage({
    super.key,
    required this.sensorData,
  });

  @override
  State<DetailChartPage> createState() => _DetailChartPageState();
}

class _DetailChartPageState extends State<DetailChartPage> {
  late List<SensorData> _filteredData;
  String _timeRange = 'All';
  int _touchedIndex = -1;
  bool _showTemperature = true;
  bool _showHumidity = true;
  bool _isZoomed = false;
  double _minX = 0;
  double _maxX = 0;
  double _minY = 0;
  double _maxY = 100;

  @override
  void initState() {
    super.initState();
    _filteredData = List.from(widget.sensorData);
    _maxX = (_filteredData.length - 1).toDouble();
    _resetZoom();
  }

  void _resetZoom() {
    setState(() {
      _minX = 0;
      _maxX = (_filteredData.length - 1).toDouble();
      _minY = 0;
      _maxY = 100;
      _isZoomed = false;
    });
  }

  void _filterDataByTime(String range) {
    final now = DateTime.now();
    setState(() {
      _timeRange = range;
      switch (range) {
        case 'Last Hour':
          _filteredData = widget.sensorData
              .where((data) => data.timestamp.isAfter(now.subtract(const Duration(hours: 1))))
              .toList();
          break;
        case 'Last 24 Hours':
          _filteredData = widget.sensorData
              .where((data) => data.timestamp.isAfter(now.subtract(const Duration(days: 1))))
              .toList();
          break;
        case 'Last Week':
          _filteredData = widget.sensorData
              .where((data) => data.timestamp.isAfter(now.subtract(const Duration(days: 7))))
              .toList();
          break;
        default:
          _filteredData = List.from(widget.sensorData);
      }
      _maxX = (_filteredData.length - 1).toDouble();
      _resetZoom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Analytics'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isZoomed ? Icons.zoom_out : Icons.filter_list),
            onPressed: _isZoomed ? _resetZoom : () => _showFilterOptions(context),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Temperature & Humidity Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_timeRange',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildLegendItem(
                    color: Colors.orange,
                    text: 'Temperature',
                    isActive: _showTemperature,
                    onTap: () {
                      setState(() {
                        _showTemperature = !_showTemperature;
                      });
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildLegendItem(
                    color: const Color(0xFFCCFF00),
                    text: 'Humidity',
                    isActive: _showHumidity,
                    onTap: () {
                      setState(() {
                        _showHumidity = !_showHumidity;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _filteredData.isEmpty
                    ? const Center(
                  child: Text(
                    'No data available for the selected time range',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : _buildInteractiveChart(),
              ),
              const SizedBox(height: 16),
              _buildStatsCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChart() {
    if (_filteredData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade900.withOpacity(0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index < 0 || index >= _filteredData.length) {
                  return null;
                }

                final value = barSpot.y;
                final isTempLine = barSpot.barIndex == 0;
                final sensorType = isTempLine ? 'Temperature' : 'Humidity';
                final unit = isTempLine ? '°C' : '%';

                return LineTooltipItem(
                  '$sensorType: ${value.toStringAsFixed(1)}$unit\n${DateFormat('MM/dd HH:mm:ss').format(_filteredData[index].timestamp)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (event is FlPanEndEvent || event is FlTapUpEvent) {
              setState(() {
                _touchedIndex = -1;
              });
              return;
            }

            setState(() {
              if (touchResponse == null || touchResponse.lineBarSpots == null || touchResponse.lineBarSpots!.isEmpty) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = touchResponse.lineBarSpots!.first.x.toInt();
            });
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          if (_showTemperature)
            LineChartBarData(
              spots: _createSpots(_filteredData.map((data) => double.parse(data.temperature)).toList()),
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: index == _touchedIndex ? 6 : 3,
                  color: Colors.orange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          if (_showHumidity)
            LineChartBarData(
              spots: _createSpots(_filteredData.map((data) => double.parse(data.humidity)).toList()),
              isCurved: true,
              curveSmoothness: 0.3,
              color: const Color(0xFFCCFF00),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: index == _touchedIndex ? 6 : 3,
                  color: const Color(0xFFCCFF00),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFCCFF00).withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFCCFF00).withOpacity(0.3),
                    const Color(0xFFCCFF00).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
          verticalInterval: _getVerticalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade800,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade800,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:  AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles:  AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _getBottomTitlesInterval(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _filteredData.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getBottomTitle(index),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
        minX: _minX,
        maxX: _maxX,
        minY: _minY,
        maxY: _maxY,
        clipData: FlClipData.all(),
      ),
    );
  }

  List<FlSpot> _createSpots(List<double> values) {
    List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }
    return spots;
  }

  double _getVerticalInterval() {
    final dataLength = _filteredData.length;

    if (_isZoomed) {
      return 1.0;
    } else if (dataLength > 50) {
      return (dataLength / 5).ceil().toDouble();
    } else if (dataLength > 20) {
      return 5.0;
    } else {
      return 2.0;
    }
  }

  double _getBottomTitlesInterval() {
    final dataLength = _filteredData.length;

    if (_isZoomed) {
      return 1.0;
    } else if (dataLength > 50) {
      return (dataLength / 5).ceil().toDouble();
    } else if (dataLength > 20) {
      return 4.0;
    } else {
      return 2.0;
    }
  }

  String _getBottomTitle(int index) {
    final dateFormat = _getDateFormat();
    return dateFormat.format(_filteredData[index].timestamp);
  }

  DateFormat _getDateFormat() {
    switch (_timeRange) {
      case 'Last Hour':
        return DateFormat('HH:mm');
      case 'Last 24 Hours':
        return DateFormat('HH:mm');
      case 'Last Week':
        return DateFormat('MM/dd');
      default:
        return DateFormat('MM/dd HH:mm');
    }
  }

  Widget _buildStatsCards() {
    if (_filteredData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate stats
    double avgTemp = 0;
    double avgHum = 0;
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;
    double minHum = double.infinity;
    double maxHum = double.negativeInfinity;

    for (var data in _filteredData) {
      final temp = double.parse(data.temperature);
      final hum = double.parse(data.humidity);

      avgTemp += temp;
      avgHum += hum;

      if (temp < minTemp) minTemp = temp;
      if (temp > maxTemp) maxTemp = temp;
      if (hum < minHum) minHum = hum;
      if (hum > maxHum) maxHum = hum;
    }

    avgTemp /= _filteredData.length;
    avgHum /= _filteredData.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Data points: ${_filteredData.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temperature',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Avg', '${avgTemp.toStringAsFixed(1)}°C'),
                    _buildStatRow('Min', '${minTemp.toStringAsFixed(1)}°C'),
                    _buildStatRow('Max', '${maxTemp.toStringAsFixed(1)}°C'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Humidity',
                      style: TextStyle(
                        color: Color(0xFFCCFF00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Avg', '${avgHum.toStringAsFixed(1)}%'),
                    _buildStatRow('Min', '${minHum.toStringAsFixed(1)}%'),
                    _buildStatRow('Max', '${maxHum.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Time Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilterOption('All', _timeRange == 'All'),
              _buildFilterOption('Last Hour', _timeRange == 'Last Hour'),
              _buildFilterOption('Last 24 Hours', _timeRange == 'Last 24 Hours'),
              _buildFilterOption('Last Week', _timeRange == 'Last Week'),
              const Divider(color: Colors.grey),
              ListTile(
                title: const Text(
                  'View Latest Data',
                  style: TextStyle(color: Colors.white),
                ),
                leading: const Icon(
                  Icons.update,
                  color: Color(0xFFCCFF00),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Focus on the most recent data (last 10 points)
                  if (_filteredData.length > 10) {
                    setState(() {
                      _minX = _filteredData.length - 10.0;
                      _maxX = _filteredData.length - 1.0;
                      _isZoomed = true;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, bool isSelected) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFFCCFF00) : Colors.grey,
      ),
      onTap: () {
        Navigator.pop(context);
        _filterDataByTime(label);
      },
    );
  }
}