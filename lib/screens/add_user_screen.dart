import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';
import '../models/user_model.dart';
import '../models/spectral_data_model.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = 'O+';
  bool _isSubmitting = false;

  // Sensor capture state
  int _capturedCount = 0;
  SpectralReading? _lastCapturedReading;
  List<SpectralReading> _capturedReadings = [];

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information', Icons.person),
              const SizedBox(height: 12),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildAgeAndGenderRow(),
              const SizedBox(height: 24),

              // Medical Information Section
              _buildSectionHeader('Medical Information', Icons.medical_information),
              const SizedBox(height: 12),
              _buildBloodGroupField(),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information (Optional)', Icons.contact_phone),
              const SizedBox(height: 12),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 24),

              // Sensor Capture Section
              _buildSectionHeader('Sensor Reading (Optional)', Icons.sensors),
              const SizedBox(height: 12),
              _buildSensorCaptureCard(),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildResetButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.person_add,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register New Patient',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Fill in details and optionally capture sensor reading',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name *',
        hintText: 'Enter full name',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAgeAndGenderRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              labelText: 'Age *',
              hintText: 'Years',
              prefixIcon: const Icon(Icons.cake_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 1 || age > 150) {
                return 'Invalid age';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender *',
              prefixIcon: const Icon(Icons.wc),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _genders
                .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedGender = value ?? 'Male');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupField() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      decoration: InputDecoration(
        labelText: 'Blood Group *',
        prefixIcon: const Icon(Icons.bloodtype),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _bloodGroups.map((bloodGroup) {
        return DropdownMenuItem(
          value: bloodGroup,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              bloodGroup,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedBloodGroup = value ?? 'O+');
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'example@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '+1234567890',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
        LengthLimitingTextInputFormatter(15),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes',
        hintText: 'Any additional notes...',
        prefixIcon: const Icon(Icons.notes_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSensorCaptureCard() {
    return Consumer<MqttService>(
      builder: (context, mqtt, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mqtt.isConnected
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        mqtt.isConnected ? Icons.sensors : Icons.sensors_off,
                        color: mqtt.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mqtt.isConnected ? 'Sensor Connected' : 'Sensor Offline',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            mqtt.isConnected
                                ? 'Ready to capture readings'
                                : 'Connect sensor to capture data',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (mqtt.isConnected) ...[
                  const SizedBox(height: 16),

                  // Capture controls
                  if (!mqtt.isCapturing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startCapturing,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Capturing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Capturing indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Capturing... ${_capturedCount} readings',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stop button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _stopCapturing,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Capturing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Latest captured reading preview
                  if (_lastCapturedReading != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Latest Captured Reading:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMiniChip('NIR', _lastCapturedReading!.channels.nir.toString()),
                          _buildMiniChip('Red', _lastCapturedReading!.channels.f7_630nm.toString()),
                          _buildMiniChip('Clear', _lastCapturedReading!.channels.clearChannel.toString()),
                        ],
                      ),
                    ),
                  ],

                  // Captured readings count
                  if (_capturedReadings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_capturedReadings.length} readings will be saved with this user',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _clearCapturedReadings,
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startCapturing() {
    final mqtt = context.read<MqttService>();

    setState(() {
      _capturedCount = 0;
      _lastCapturedReading = null;
    });

    mqtt.startCapturing(
      onData: (reading) {
        setState(() {
          _capturedCount++;
          _lastCapturedReading = reading;
        });
      },
    );
  }

  void _stopCapturing() {
    final mqtt = context.read<MqttService>();
    final readings = mqtt.stopCapturing();

    setState(() {
      _capturedReadings = readings;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Captured ${readings.length} readings'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearCapturedReadings() {
    setState(() {
      _capturedReadings = [];
      _capturedCount = 0;
      _lastCapturedReading = null;
    });
    context.read<MqttService>().clearCapturedReadings();
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add),
            const SizedBox(width: 8),
            Text(
              _capturedReadings.isNotEmpty
                  ? 'Add User with ${_capturedReadings.length} Readings'
                  : 'Add User',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton(
      onPressed: _isSubmitting ? null : _resetForm,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Reset Form'),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Stop capturing if still active
    final mqtt = context.read<MqttService>();
    if (mqtt.isCapturing) {
      _capturedReadings = mqtt.stopCapturing();
    }

    setState(() => _isSubmitting = true);

    final request = CreateUserRequest(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      email: _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
    );

    final apiService = context.read<ApiService>();
    final userId = await apiService.addUser(request);

    if (userId != null && _capturedReadings.isNotEmpty) {
      // Save only the latest reading (even if MQTT sent multiple simultaneously)
      // The database service will also prevent duplicates within 2 seconds
      final latestReading = _capturedReadings.last;
      await apiService.saveSpectralReading(userId, latestReading);
    }

    setState(() => _isSubmitting = false);

    if (userId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${_nameController.text} added${_capturedReadings.isNotEmpty ? ' with ${_capturedReadings.length} readings' : ''}!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _resetForm();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add user: ${apiService.error}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();

    setState(() {
      _selectedGender = 'Male';
      _selectedBloodGroup = 'O+';
      _capturedReadings = [];
      _capturedCount = 0;
      _lastCapturedReading = null;
    });

    context.read<MqttService>().clearCapturedReadings();
  }
}