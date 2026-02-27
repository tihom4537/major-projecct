import 'package:mysql1/mysql1.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/spectral_data_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySqlConnection? _connection;
  bool _isConnecting = false;



  // Database credentials
  final String _host = 'mysql-3bc62078-mkt453712-01a3.j.aivencloud.com';
  final int _port = 19663;
  final String _user = 'avnadmin';
  final String _password = 'AVNS_CcdMstVpR8qjpgqekmN';
  final String _database = 'data';

  Future<MySqlConnection> get connection async {
    if (_connection != null) {
      try {
        await _connection!.query('SELECT 1');
        return _connection!;
      } catch (e) {
        _connection = null;
      }
    }
    return await _connect();
  }

  Future<MySqlConnection> _connect() async {
    if (_isConnecting) {
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_connection != null) {
        try {
          await _connection!.query('SELECT 1');
          return _connection!;
        } catch (e) {
          _connection = null;
        }
      }
    }

    _isConnecting = true;
    try {
      final settings = ConnectionSettings(
        host: _host,
        port: _port,
        user: _user,
        password: _password,
        db: _database,
        timeout: const Duration(seconds: 10),
      );

      _connection = await MySqlConnection.connect(settings);
      print('✅ Connected to MySQL database');
      _isConnecting = false;
      return _connection!;
    } catch (e) {
      _isConnecting = false;
      print('❌ Error connecting to MySQL: $e');
      rethrow;
    }
  }

  // Helper method to convert Blob to String
  String? _blobToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Blob) {
      try {
        return utf8.decode(value.toBytes());
      } catch (e) {
        print('⚠️ Error decoding Blob: $e');
        return null;
      }
    }
    if (value is Uint8List) {
      try {
        return utf8.decode(value);
      } catch (e) {
        print('⚠️ Error decoding Uint8List: $e');
        return null;
      }
    }
    return value.toString();
  }

  // Helper method to safely convert field map
  Map<String, dynamic> _convertFieldMap(Map<String, dynamic> fields) {
    final converted = <String, dynamic>{};
    fields.forEach((key, value) {
      if (value is Blob) {
        converted[key] = _blobToString(value);
      } else {
        converted[key] = value;
      }
    });
    return converted;
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      final conn = await connection;
      await conn.query('SELECT 1');
      return true;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<int> insertUser(CreateUserRequest user) async {
    final conn = await connection;
    final result = await conn.query(
      '''
      INSERT INTO users (name, age, gender, blood_group, email, phone, created_at)
      VALUES (?, ?, ?, ?, ?, ?, NOW())
      ''',
      [
        user.name,
        user.age,
        user.gender,
        user.bloodGroup,
        user.email,
        user.phone,
      ],
    );
    final userId = result.insertId;
    print('✅ User inserted with ID: $userId');
    return userId as int;
  }

  Future<List<UserModel>> getAllUsers() async {
    final conn = await connection;
    final results = await conn.query(
      '''
      SELECT * FROM users ORDER BY created_at DESC
      ''',
    );

    List<UserModel> users = [];
    for (var row in results) {
      final userMap = _convertFieldMap(row.fields);
      final latestReading = await getLatestReadingForUser(userMap['id'] as int);
      users.add(UserModel.fromDbMap(userMap, latestReading: latestReading));
    }

    return users;
  }

  Future<UserModel?> getUserById(int id) async {
    final conn = await connection;
    final results = await conn.query(
      '''
      SELECT * FROM users WHERE id = ?
      ''',
      [id],
    );

    if (results.isEmpty) return null;

    final userMap = _convertFieldMap(results.first.fields);
    final latestReading = await getLatestReadingForUser(id);
    return UserModel.fromDbMap(userMap, latestReading: latestReading);
  }

  Future<int> updateUser(int id, Map<String, dynamic> updates) async {
    final conn = await connection;
    final setClause = updates.keys.map((k) => '$k = ?').join(', ');
    final values = updates.values.toList()..add(id);

    final result = await conn.query(
      '''
      UPDATE users SET $setClause, updated_at = NOW() WHERE id = ?
      ''',
      values,
    );
    return result.affectedRows?.toInt() ?? 0;
  }

  Future<int> deleteUser(int id) async {
    final conn = await connection;
    final result = await conn.query(
      '''
      DELETE FROM users WHERE id = ?
      ''',
      [id],
    );
    return result.affectedRows?.toInt() ?? 0;
  }

  // ==================== SPECTRAL READING OPERATIONS ====================

  Future<int> insertSpectralReading(SpectralReading reading) async {
    final conn = await connection;

    final spectralDataJson = reading.rawSpectralData.isEmpty
        ? null
        : reading.rawSpectralData.join(',');

    final result = await conn.query(
      '''
      INSERT INTO spectral_readings (
        user_id, label, timestamp_sensor, channels_read,
        fz, fy, fxl, nir,
        f1_415nm, f2_445nm, f3_480nm, f4_515nm, f5_555nm,
        f6_590nm, f7_630nm, f8_680nm,
        f1_415nm_2, f2_445nm_2, f3_480nm_2, f4_515nm_2, f5_555nm_2,
        clear_channel,
        spectral_data_raw, recorded_at
      ) VALUES (
        ?, ?, ?, ?,
        ?, ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?,
        ?, NOW()
      )
      ''',
      [
        reading.userId,
        reading.label,
        reading.deviceTimestamp,
        reading.channelsRead,
        reading.channels.fz,
        reading.channels.fy,
        reading.channels.fxl,
        reading.channels.nir,
        reading.channels.f1_415nm,
        reading.channels.f2_445nm,
        reading.channels.f3_480nm,
        reading.channels.f4_515nm,
        reading.channels.f5_555nm,
        reading.channels.f6_590nm,
        reading.channels.f7_630nm,
        reading.channels.f8_680nm,
        reading.channels.f1_415nm_2,
        reading.channels.f2_445nm_2,
        reading.channels.f3_480nm_2,
        reading.channels.f4_515nm_2,
        reading.channels.f5_555nm_2,
        reading.channels.clearChannel,
        spectralDataJson,
      ],
    );

    final readingId = result.insertId;
    print('✅ Spectral reading inserted with ID: $readingId for User: ${reading.userId}');
    return readingId as int;
  }

  Future<int> insertSpectralReadingSingle(SpectralReading reading) async {
    final conn = await connection;

    final recentReadings = await conn.query(
      '''
      SELECT id FROM spectral_readings 
      WHERE user_id = ? AND recorded_at > DATE_SUB(NOW(), INTERVAL 2 SECOND)
      ORDER BY recorded_at DESC LIMIT 1
      ''',
      [reading.userId],
    );

    if (recentReadings.isNotEmpty) {
      print('⚠️ Skipping duplicate reading for user ${reading.userId} (recent reading exists)');
      return recentReadings.first.fields['id'] as int;
    }

    return await insertSpectralReading(reading);
  }

  Future<SpectralReading?> getLatestReadingForUser(int userId) async {
    final conn = await connection;
    final results = await conn.query(
      '''
      SELECT * FROM spectral_readings 
      WHERE user_id = ? 
      ORDER BY recorded_at DESC 
      LIMIT 1
      ''',
      [userId],
    );

    if (results.isEmpty) return null;
    final convertedMap = _convertFieldMap(results.first.fields);
    return SpectralReading.fromDbMap(convertedMap);
  }

  Future<List<SpectralReading>> getAllReadingsForUser(int userId, {int? limit}) async {
    final conn = await connection;
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final results = await conn.query(
      '''
      SELECT * FROM spectral_readings 
      WHERE user_id = ? 
      ORDER BY recorded_at DESC 
      $limitClause
      ''',
      [userId],
    );

    return results.map((row) {
      final convertedMap = _convertFieldMap(row.fields);
      return SpectralReading.fromDbMap(convertedMap);
    }).toList();
  }

  Future<int> deleteReadingsForUser(int userId) async {
    final conn = await connection;
    final result = await conn.query(
      '''
      DELETE FROM spectral_readings WHERE user_id = ?
      ''',
      [userId],
    );
    return result.affectedRows?.toInt() ?? 0;
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getDatabaseStats() async {
    final conn = await connection;

    final userCountResult = await conn.query('SELECT COUNT(*) as count FROM users');
    final userCount = (userCountResult.first.fields['count'] as int?) ?? 0;

    final readingCountResult = await conn.query('SELECT COUNT(*) as count FROM spectral_readings');
    final readingCount = (readingCountResult.first.fields['count'] as int?) ?? 0;

    final usersWithReadingsResult = await conn.query(
        'SELECT COUNT(DISTINCT user_id) as count FROM spectral_readings'
    );
    final usersWithReadings = (usersWithReadingsResult.first.fields['count'] as int?) ?? 0;

    return {
      'totalUsers': userCount,
      'totalReadings': readingCount,
      'usersWithReadings': usersWithReadings,
    };
  }

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
    print('✅ Database connection closed');
  }

  Future<void> clearAllData() async {
    final conn = await connection;
    await conn.query('DELETE FROM spectral_readings');
    await conn.query('DELETE FROM users');
    print('⚠️ All data cleared');
  }
}