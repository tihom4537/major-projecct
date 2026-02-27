import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../models/user_model.dart';
import '../models/spectral_data_model.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  List<SpectralReading> _readings = [];
  bool _isLoading = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final apiService = context.read<ApiService>();
    _user = await apiService.getUserById(widget.userId);
    _readings = await apiService.getUserReadings(widget.userId, limit: 50);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfoCard(),
            const SizedBox(height: 16),
            _buildCaptureNewReadingCard(),
            const SizedBox(height: 16),
            if (_user!.latestReading != null) ...[
              _buildLatestReadingCard(),
              const SizedBox(height: 16),
              _buildSpectralChart(),
              const SizedBox(height: 16),
            ],
            _buildReadingsHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _user!.statusColor.withOpacity(0.2),
              child: Text(
                _user!.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  color: _user!.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _user!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoChip(Icons.cake, '${_user!.age} years'),
                _buildInfoChip(
                  _user!.gender == 'Male' ? Icons.male : Icons.female,
                  _user!.gender,
                ),
                _buildInfoChip(Icons.bloodtype, _user!.bloodGroup, color: Colors.red),
              ],
            ),
            if (_user!.email != null || _user!.phone != null) ...[
              const Divider(height: 24),
              if (_user!.email != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_user!.email!, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              if (_user!.phone != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(_user!.phone!, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color ?? Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildCaptureNewReadingCard() {
    final mqtt = context.watch<MqttService>();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: mqtt.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  mqtt.isConnected ? 'Sensor Connected' : 'Sensor Disconnected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mqtt.isConnected && !_isCapturing ? _captureNewReading : null,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(_isCapturing ? 'Capturing...' : 'Capture New Reading'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureNewReading() async {
    setState(() => _isCapturing = true);

    // Wait for a reading
    await Future.delayed(const Duration(seconds: 3));

    final mqtt = context.read<MqttService>();
    final reading = mqtt.latestData;

    if (reading != null) {
      final apiService = context.read<ApiService>();
      final success = await apiService.saveSpectralReading(widget.userId, reading);

      if (success) {
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reading captured successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No sensor data available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isCapturing = false);
  }

  Widget _buildLatestReadingCard() {
    final reading = _user!.latestReading!;
    final channels = reading.channels;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics),
                const SizedBox(width: 8),
                const Text(
                  'Latest Reading',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy HH:mm').format(reading.readingTakenAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildChannelValue('NIR', channels.nir, Colors.purple),
                _buildChannelValue('F7 (630nm)', channels.f7_630nm, Colors.orange),
                _buildChannelValue('F8 (680nm)', channels.f8_680nm, Colors.red),
                _buildChannelValue('Clear', channels.clearChannel, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelValue(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectralChart() {
    final reading = _user!.latestReading!;
    final primaryChannels = reading.channels.primaryChannels
        .where((c) => c.wavelength > 0)
        .toList();

    if (primaryChannels.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = primaryChannels.map((c) => c.value.toDouble()).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, size: 20),
                SizedBox(width: 8),
                Text(
                  'Spectral Response Curve',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final channel = primaryChannels[group.x.toInt()];
                        return BarTooltipItem(
                          '${channel.name}\n${channel.value}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < primaryChannels.length) {
                            final channel = primaryChannels[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${channel.wavelength}',
                                style: const TextStyle(fontSize: 8),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: primaryChannels.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: entry.value.color,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Wavelength (nm)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history),
                SizedBox(width: 8),
                Text(
                  'Reading History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_readings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No readings available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _readings.length > 10 ? 10 : _readings.length,
                itemBuilder: (context, index) {
                  final reading = _readings[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      DateFormat('MMM d, yyyy HH:mm').format(reading.readingTakenAt),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'NIR: ${reading.channels.nir} | F7: ${reading.channels.f7_630nm} | F8: ${reading.channels.f8_680nm}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                    onTap: () {
                      // Could navigate to reading detail screen if needed
                    },
                  );
                },
              ),
            if (_readings.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Showing latest 10 of ${_readings.length} readings',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
