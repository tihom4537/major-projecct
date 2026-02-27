import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';
import '../models/spectral_data_model.dart';

class SensorScreen extends StatelessWidget {
  const SensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Sensor Data'),
        actions: [
          Consumer<MqttService>(
            builder: (context, mqtt, child) {
              return Row(
                children: [
                  _buildConnectionBadge(mqtt),
                  IconButton(
                    icon: Icon(
                      mqtt.isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: mqtt.isConnected ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      if (mqtt.isConnected) {
                        mqtt.disconnect();
                      } else {
                        mqtt.connect();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<MqttService>(
        builder: (context, mqtt, child) {
          return RefreshIndicator(
            onRefresh: () async {
              if (!mqtt.isConnected) mqtt.connect();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildConnectionCard(mqtt),
                  const SizedBox(height: 16),
                  _buildLatestReadingInfo(mqtt),
                  const SizedBox(height: 16),
                  _buildPrimaryChannelsGrid(mqtt),
                  const SizedBox(height: 16),
                  _buildSpectralChart(mqtt),
                  const SizedBox(height: 16),
                  _buildAllChannelsCard(mqtt),
                  const SizedBox(height: 16),
                  _buildRawDataCard(mqtt),
                  const SizedBox(height: 16),
                  _buildStatisticsCard(mqtt),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionBadge(MqttService mqtt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: mqtt.isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: mqtt.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            mqtt.isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 12,
              color: mqtt.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(MqttService mqtt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              mqtt.isConnected
                  ? Icons.sensors
                  : mqtt.isConnecting
                  ? Icons.sync
                  : Icons.sensors_off,
              color: mqtt.isConnected
                  ? Colors.green
                  : mqtt.isConnecting
                  ? Colors.orange
                  : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mqtt.isConnected
                        ? 'Receiving 18-Channel Data'
                        : mqtt.isConnecting
                        ? 'Connecting...'
                        : 'Disconnected',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    mqtt.isConnected
                        ? 'Messages: ${mqtt.messageCount}'
                        : mqtt.connectionError ?? 'Tap to reconnect',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!mqtt.isConnected && !mqtt.isConnecting)
              ElevatedButton.icon(
                onPressed: () => mqtt.connect(),
                icon: const Icon(Icons.refresh),
                label: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestReadingInfo(MqttService mqtt) {
    final data = mqtt.latestData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Latest Reading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (data != null)
                  Text(
                    _formatTime(data.readingTakenAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (data != null)
              Row(
                children: [
                  _buildInfoChip('Label', data.label, Colors.blue),
                  const SizedBox(width: 8),
                  _buildInfoChip('Channels', '${data.channelsRead}', Colors.purple),
                  const SizedBox(width: 8),
                  _buildInfoChip('Timestamp', '${data.deviceTimestamp}', Colors.grey),
                ],
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No data received yet', style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildPrimaryChannelsGrid(MqttService mqtt) {
    final data = mqtt.latestData;
    if (data == null) return const SizedBox.shrink();

    final primaryChannels = data.channels.primaryChannels;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wb_sunny, size: 20),
                SizedBox(width: 8),
                Text(
                  'Primary Spectral Channels',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: primaryChannels.length,
              itemBuilder: (context, index) {
                final channel = primaryChannels[index];
                return _buildChannelCard(channel);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(ChannelInfo channel) {
    return Container(
      decoration: BoxDecoration(
        color: channel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: channel.color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${channel.value}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: channel.color,
            ),
          ),
          Text(
            channel.name,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          if (channel.wavelength > 0)
            Text(
              '${channel.wavelength}nm',
              style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildSpectralChart(MqttService mqtt) {
    final data = mqtt.latestData;
    if (data == null) return const SizedBox.shrink();

    final primaryChannels = data.channels.primaryChannels
        .where((c) => c.wavelength > 0)
        .toList();

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
                  maxY: primaryChannels.map((c) => c.value.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
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

  Widget _buildAllChannelsCard(MqttService mqtt) {
    final data = mqtt.latestData;
    if (data == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, size: 20),
                SizedBox(width: 8),
                Text(
                  'All 18 Channels',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.channels.allChannels.map((channel) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: channel.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: channel.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${channel.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: channel.color,
                        ),
                      ),
                      Text(channel.name, style: const TextStyle(fontSize: 8)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataCard(MqttService mqtt) {
    final data = mqtt.latestData;
    if (data == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.data_array, size: 20),
                SizedBox(width: 8),
                Text(
                  'Raw Spectral Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data.rawSpectralData.join(', '),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(MqttService mqtt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, size: 20),
                SizedBox(width: 8),
                Text(
                  'Session Statistics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Messages', mqtt.messageCount.toString()),
                _buildStatItem('History', '${mqtt.dataHistory.length}'),
                _buildStatItem('Status', mqtt.isConnected ? 'Active' : 'Inactive'),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => mqtt.clearHistory(),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}