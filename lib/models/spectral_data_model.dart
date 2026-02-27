import 'package:flutter/material.dart';

class SpectralChannels {
  final int fz;
  final int fy;
  final int fxl;
  final int nir;
  final int f1_415nm;
  final int f2_445nm;
  final int f3_480nm;
  final int f4_515nm;
  final int f5_555nm;
  final int f6_590nm;
  final int f7_630nm;
  final int f8_680nm;
  final int f1_415nm_2;
  final int f2_445nm_2;
  final int f3_480nm_2;
  final int f4_515nm_2;
  final int f5_555nm_2;
  final int clearChannel;

  SpectralChannels({
    this.fz = 0,
    this.fy = 0,
    this.fxl = 0,
    this.nir = 0,
    this.f1_415nm = 0,
    this.f2_445nm = 0,
    this.f3_480nm = 0,
    this.f4_515nm = 0,
    this.f5_555nm = 0,
    this.f6_590nm = 0,
    this.f7_630nm = 0,
    this.f8_680nm = 0,
    this.f1_415nm_2 = 0,
    this.f2_445nm_2 = 0,
    this.f3_480nm_2 = 0,
    this.f4_515nm_2 = 0,
    this.f5_555nm_2 = 0,
    this.clearChannel = 0,
  });

  factory SpectralChannels.fromJson(Map<String, dynamic> json) {
    return SpectralChannels(
      fz: json['FZ'] ?? 0,
      fy: json['FY'] ?? 0,
      fxl: json['FXL'] ?? 0,
      nir: json['NIR'] ?? 0,
      f1_415nm: json['F1_415nm'] ?? 0,
      f2_445nm: json['F2_445nm'] ?? 0,
      f3_480nm: json['F3_480nm'] ?? 0,
      f4_515nm: json['F4_515nm'] ?? 0,
      f5_555nm: json['F5_555nm'] ?? 0,
      f6_590nm: json['F6_590nm'] ?? 0,
      f7_630nm: json['F7_630nm'] ?? 0,
      f8_680nm: json['F8_680nm'] ?? 0,
      f1_415nm_2: json['F1_415nm_2'] ?? 0,
      f2_445nm_2: json['F2_445nm_2'] ?? 0,
      f3_480nm_2: json['F3_480nm_2'] ?? 0,
      f4_515nm_2: json['F4_515nm_2'] ?? 0,
      f5_555nm_2: json['F5_555nm_2'] ?? 0,
      clearChannel: json['Clear'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FZ': fz,
      'FY': fy,
      'FXL': fxl,
      'NIR': nir,
      'F1_415nm': f1_415nm,
      'F2_445nm': f2_445nm,
      'F3_480nm': f3_480nm,
      'F4_515nm': f4_515nm,
      'F5_555nm': f5_555nm,
      'F6_590nm': f6_590nm,
      'F7_630nm': f7_630nm,
      'F8_680nm': f8_680nm,
      'F1_415nm_2': f1_415nm_2,
      'F2_445nm_2': f2_445nm_2,
      'F3_480nm_2': f3_480nm_2,
      'F4_515nm_2': f4_515nm_2,
      'F5_555nm_2': f5_555nm_2,
      'Clear': clearChannel,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'fz': fz,
      'fy': fy,
      'fxl': fxl,
      'nir': nir,
      'f1_415nm': f1_415nm,
      'f2_445nm': f2_445nm,
      'f3_480nm': f3_480nm,
      'f4_515nm': f4_515nm,
      'f5_555nm': f5_555nm,
      'f6_590nm': f6_590nm,
      'f7_630nm': f7_630nm,
      'f8_680nm': f8_680nm,
      'f1_415nm_2': f1_415nm_2,
      'f2_445nm_2': f2_445nm_2,
      'f3_480nm_2': f3_480nm_2,
      'f4_515nm_2': f4_515nm_2,
      'f5_555nm_2': f5_555nm_2,
      'clear_channel': clearChannel,
    };
  }

  factory SpectralChannels.fromDbMap(Map<String, dynamic> map) {
    return SpectralChannels(
      fz: map['fz'] ?? 0,
      fy: map['fy'] ?? 0,
      fxl: map['fxl'] ?? 0,
      nir: map['nir'] ?? 0,
      f1_415nm: map['f1_415nm'] ?? 0,
      f2_445nm: map['f2_445nm'] ?? 0,
      f3_480nm: map['f3_480nm'] ?? 0,
      f4_515nm: map['f4_515nm'] ?? 0,
      f5_555nm: map['f5_555nm'] ?? 0,
      f6_590nm: map['f6_590nm'] ?? 0,
      f7_630nm: map['f7_630nm'] ?? 0,
      f8_680nm: map['f8_680nm'] ?? 0,
      f1_415nm_2: map['f1_415nm_2'] ?? 0,
      f2_445nm_2: map['f2_445nm_2'] ?? 0,
      f3_480nm_2: map['f3_480nm_2'] ?? 0,
      f4_515nm_2: map['f4_515nm_2'] ?? 0,
      f5_555nm_2: map['f5_555nm_2'] ?? 0,
      clearChannel: map['clear_channel'] ?? 0,
    );
  }

  // Get all channels as a list for visualization
  List<ChannelInfo> get allChannels {
    return [
      ChannelInfo('F1 (415nm)', f1_415nm, const Color(0xFF7B1FA2), 415),
      ChannelInfo('F2 (445nm)', f2_445nm, const Color(0xFF303F9F), 445),
      ChannelInfo('F3 (480nm)', f3_480nm, const Color(0xFF0288D1), 480),
      ChannelInfo('F4 (515nm)', f4_515nm, const Color(0xFF388E3C), 515),
      ChannelInfo('F5 (555nm)', f5_555nm, const Color(0xFF689F38), 555),
      ChannelInfo('F6 (590nm)', f6_590nm, const Color(0xFFFFA000), 590),
      ChannelInfo('F7 (630nm)', f7_630nm, const Color(0xFFE64A19), 630),
      ChannelInfo('F8 (680nm)', f8_680nm, const Color(0xFFC62828), 680),
      ChannelInfo('NIR', nir, const Color(0xFF880E4F), 850),
      ChannelInfo('Clear', clearChannel, const Color(0xFF455A64), 0),
      ChannelInfo('FZ', fz, const Color(0xFF37474F), 0),
      ChannelInfo('FY', fy, const Color(0xFF546E7A), 0),
      ChannelInfo('FXL', fxl, const Color(0xFF78909C), 0),
      ChannelInfo('F1 (415nm) #2', f1_415nm_2, const Color(0xFF9C27B0), 415),
      ChannelInfo('F2 (445nm) #2', f2_445nm_2, const Color(0xFF3F51B5), 445),
      ChannelInfo('F3 (480nm) #2', f3_480nm_2, const Color(0xFF03A9F4), 480),
      ChannelInfo('F4 (515nm) #2', f4_515nm_2, const Color(0xFF4CAF50), 515),
      ChannelInfo('F5 (555nm) #2', f5_555nm_2, const Color(0xFF8BC34A), 555),
    ];
  }

  // Get primary spectral channels (wavelength-based)
  List<ChannelInfo> get primaryChannels {
    return [
      ChannelInfo('F1 (415nm)', f1_415nm, const Color(0xFF7B1FA2), 415),
      ChannelInfo('F2 (445nm)', f2_445nm, const Color(0xFF303F9F), 445),
      ChannelInfo('F3 (480nm)', f3_480nm, const Color(0xFF0288D1), 480),
      ChannelInfo('F4 (515nm)', f4_515nm, const Color(0xFF388E3C), 515),
      ChannelInfo('F5 (555nm)', f5_555nm, const Color(0xFF689F38), 555),
      ChannelInfo('F6 (590nm)', f6_590nm, const Color(0xFFFFA000), 590),
      ChannelInfo('F7 (630nm)', f7_630nm, const Color(0xFFE64A19), 630),
      ChannelInfo('F8 (680nm)', f8_680nm, const Color(0xFFC62828), 680),
      ChannelInfo('NIR', nir, const Color(0xFF880E4F), 850),
    ];
  }
}

class ChannelInfo {
  final String name;
  final int value;
  final Color color;
  final int wavelength;

  ChannelInfo(this.name, this.value, this.color, this.wavelength);
}

class SpectralReading {
  final int? id;
  final int userId;
  final String label;
  final int deviceTimestamp;
  final int channelsRead;
  final SpectralChannels channels;
  final List<int> rawSpectralData;
  final DateTime readingTakenAt;

  SpectralReading({
    this.id,
    required this.userId,
    required this.label,
    required this.deviceTimestamp,
    required this.channelsRead,
    required this.channels,
    required this.rawSpectralData,
    required this.readingTakenAt,
  });

  factory SpectralReading.fromMqttJson(Map<String, dynamic> json, {int userId = 0}) {
    return SpectralReading(
      userId: userId,
      label: json['label'] ?? 'Unknown',
      deviceTimestamp: json['timestamp'] ?? 0,
      channelsRead: json['channels_read'] ?? 18,
      channels: json['channels'] != null
          ? SpectralChannels.fromJson(json['channels'])
          : SpectralChannels(),
      rawSpectralData: (json['spectral_data'] as List?)
          ?.map((e) => e as int)
          .toList() ?? [],
      readingTakenAt: DateTime.now(),
    );
  }

  factory SpectralReading.fromDbMap(Map<String, dynamic> map) {
    // Handle both SQLite (reading_taken_at) and MySQL (recorded_at) schemas
    final timestampField = map['recorded_at'] ?? map['reading_taken_at'];
    final deviceTimestampField = map['timestamp_sensor'] ?? map['device_timestamp'];
    final rawDataField = map['spectral_data_raw'] ?? map['raw_spectral_data'];
    
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    
    return SpectralReading(
      id: map['id'],
      userId: map['user_id'],
      label: map['label'] ?? 'Unknown',
      deviceTimestamp: deviceTimestampField ?? 0,
      channelsRead: map['channels_read'] ?? 18,
      channels: SpectralChannels.fromDbMap(map),
      rawSpectralData: rawDataField != null
          ? (rawDataField as String)
          .split(',')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList()
          : [],
      readingTakenAt: parseTimestamp(timestampField),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'user_id': userId,
      'label': label,
      'device_timestamp': deviceTimestamp,
      'channels_read': channelsRead,
      'raw_spectral_data': rawSpectralData.join(','),
      'reading_taken_at': readingTakenAt.toIso8601String(),
      ...channels.toDbMap(),
    };
  }
}