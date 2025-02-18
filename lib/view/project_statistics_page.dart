import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

class ProjectStatisticsPage extends StatefulWidget {
  final String uid;
  final String projectId;

  const ProjectStatisticsPage({
    Key? key,
    required this.uid,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ProjectStatisticsPage> createState() => _ProjectStatisticsPageState();
}

class _ProjectStatisticsPageState extends State<ProjectStatisticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> statisticsData = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      var snapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .doc(widget.projectId)
          .collection('statistics')
          .orderBy('date')
          .get();

      setState(() {
        statisticsData = snapshot.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });
    } catch (e) {
      print('İstatistik yüklenirken hata: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje İstatistikleri'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : statisticsData.isEmpty
              ? const Center(
                  child: Text('Henüz istatistik verisi bulunmamaktadır.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < statisticsData.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    DateFormat('dd/MM')
                                        .format((statisticsData[value.toInt()]
                                                ['date'] as Timestamp)
                                            .toDate()),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        _createLineChartBarData('todo', Colors.red),
                        _createLineChartBarData('doing', Colors.orange),
                        _createLineChartBarData('done', Colors.green),
                        _createLineChartBarData('verify', Colors.blue),
                      ],
                    ),
                  ),
                ),
    );
  }

  LineChartBarData _createLineChartBarData(String status, Color color) {
    List<FlSpot> spots = [];
    for (int i = 0; i < statisticsData.length; i++) {
      spots.add(FlSpot(
          i.toDouble(), (statisticsData[i][status] ?? 0).toDouble()));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
    );
  }
} 