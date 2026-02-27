import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/spectral_data_model.dart';
import 'database_service.dart';

class ApiService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ApiService() {
    fetchUsers();
  }

  // Fetch all users from database
  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _db.getAllUsers();
      _isLoading = false;
      notifyListeners();
      print('✅ Fetched ${_users.length} users from database');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error fetching users: $e');
    }
  }

  // Add a new user
  Future<int?> addUser(CreateUserRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = await _db.insertUser(request);
      await fetchUsers(); // Refresh list
      return userId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error adding user: $e');
      return null;
    }
  }

  // Save spectral reading for a user (handles duplicate prevention)
  Future<bool> saveSpectralReading(int userId, SpectralReading reading) async {
    try {
      final readingWithUser = SpectralReading(
        userId: userId,
        label: reading.label,
        deviceTimestamp: reading.deviceTimestamp,
        channelsRead: reading.channelsRead,
        channels: reading.channels,
        rawSpectralData: reading.rawSpectralData,
        readingTakenAt: reading.readingTakenAt,
      );

      // Use insertSpectralReadingSingle to prevent duplicate insertions
      // from multiple simultaneous MQTT messages
      await _db.insertSpectralReadingSingle(readingWithUser);
      await fetchUsers(); // Refresh to get updated latest reading
      return true;
    } catch (e) {
      print('❌ Error saving reading: $e');
      return false;
    }
  }

  // Get all readings for a user
  Future<List<SpectralReading>> getUserReadings(int userId, {int? limit}) async {
    try {
      return await _db.getAllReadingsForUser(userId, limit: limit);
    } catch (e) {
      print('❌ Error getting readings: $e');
      return [];
    }
  }

  // Delete a user
  Future<bool> deleteUser(int userId) async {
    try {
      await _db.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(int userId) async {
    return await _db.getUserById(userId);
  }

  // Search users
  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.bloodGroup.toLowerCase().contains(query.toLowerCase()) ||
          (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }

  // Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    return await _db.getDatabaseStats();
  }

  // Statistics
  Map<String, int> get signalStatusCounts {
    return {
      'Strong': _users.where((u) => u.signalStatus == 'Strong').length,
      'Good': _users.where((u) => u.signalStatus == 'Good').length,
      'Weak': _users.where((u) => u.signalStatus == 'Weak').length,
      'No Data': _users.where((u) => u.signalStatus == 'No Data').length,
    };
  }
}