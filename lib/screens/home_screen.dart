import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // For mapIndexed
import '../services/mqtt_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Monitor'),
        actions: [
          Consumer<MqttService>(
            builder: (context, service, child) => Icon(
              service.isConnected ? Icons.wifi : Icons.wifi_off,
              color: service.isConnected ? Colors.green : AppTheme.accent,
            ),
          ),
        ],
      ),
      body: Consumer<MqttService>(
        builder: (context, service, child) {
          print('UI: Building Consumer - isConnected: ${service.isConnected}, isConnecting: ${service.isConnecting}, error: ${service.connectionError}'); // Debug (optional, remove if not needed)

          final bool isOffline = service.isConnecting || service.connectionError != null || !service.isConnected;

          // Default data when offline
          final double defaultSpectroscopy = 25.0;
          final double defaultPpg = 50.0;
          final DateTime defaultTimestamp = DateTime.now();
          final List<SensorData> defaultHistory = List.generate(
            10,
                (index) => SensorData(spectroscopy: 25.0 + index * 0.5, ppg: 50.0 + index * 0.5, timestamp: defaultTimestamp),
          ); // Simulated history for chart

          return RefreshIndicator(
            onRefresh: service.connect, // Pull-to-refresh triggers reconnect
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Latest Data Cards (use real or default)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDataCard(
                                context,
                                'Spectroscopy',
                                isOffline ? defaultSpectroscopy : (service.latestData?.spectroscopy ?? 0),
                                Icons.analytics,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDataCard(
                                context,
                                'PPG',
                                isOffline ? defaultPpg : (service.latestData?.ppg ?? 0),
                                Icons.favorite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Timestamp (use real or default)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: AppTheme.secondary),
                            title: Text(
                              'Last Update: ${DateFormat('HH:mm:ss').format(isOffline ? defaultTimestamp : (service.latestData?.timestamp ?? DateTime.now()))}',
                            ),
                          ),
                        ),
                      ),
                      // Charts (use real or default history)
                      SizedBox(
                        height: 300,
                        child: _buildLineChart(isOffline ? defaultHistory : service.dataHistory),
                      ),
                      // Real-Time Data Table
                      _buildDataTable(context, isOffline ? defaultHistory : service.dataHistory),
                      if (service.connectionError != null) // Show error details if any
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            service.connectionError!,
                            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (!service.isConnected && service.connectionError == null) // Disconnected retry button
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: service.connect,
                            child: const Text('Retry Connection'),
                          ),
                        ),
                    ],
                  ),
                ),
                // Offline Banner (shown on top if offline)
                if (isOffline) _buildOfflineBanner(context, service.isConnecting),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, String title, double value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.secondary),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<SensorData> dataHistory) {
    final spots = dataHistory.mapIndexed((index, data) => FlSpot(index.toDouble(), data.ppg)).toList(); // Use PPG for chart
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.secondary,
            barWidth: 3,
            belowBarData: BarAreaData(show: true, color: AppTheme.supporting.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  // NEW: Real-time data table
  Widget _buildDataTable(BuildContext context, List<SensorData> dataHistory) {
    if (dataHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No data available')),
      );
    }

    // Show latest 10 readings in reverse order (newest first)
    final displayData = dataHistory.reversed.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Real-Time Data Stream',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppTheme.secondary.withOpacity(0.1)),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Time',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Spectroscopy',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PPG',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                ],
                rows: displayData.map((data) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(DateFormat('HH:mm:ss').format(data.timestamp)),
                      ),
                      DataCell(
                        Text(
                          data.spectroscopy.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                      DataCell(
                        Text(
                          data.ppg.toStringAsFixed(2),
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Showing latest ${displayData.length} readings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Offline Banner
  Widget _buildOfflineBanner(BuildContext context, bool isConnecting) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: AppTheme.accent.withOpacity(0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConnecting) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 8),
            Text(
              isConnecting ? 'Connecting... (Showing Default Data)' : 'Offline - Showing Default Data',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}