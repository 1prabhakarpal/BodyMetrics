import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Error handling setup
  FlutterError.onError = (details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  runZonedGuarded(() {
    runApp(WeightTrack());
  }, (error, stackTrace) {
    debugPrint('Dart error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class WeightTrack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight & BMI Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialSetup();
  }

  _checkInitialSetup() async {
    try {
      debugPrint('Checking initial setup...');
      final dbHelper = DatabaseHelper();
      await dbHelper.initialize();
      final userProfile = await dbHelper.getUserProfile();

      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      if (userProfile == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => InitialSetupScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error in _checkInitialSetup: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InitialSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Weight & BMI Tracker',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialSetupScreen extends StatefulWidget {
  @override
  _InitialSetupScreenState createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _dobController = TextEditingController();
  String _heightUnit = 'cm';
  DateTime? _selectedDate;
  String? _gender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Initial Setup'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 80, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  'Let\'s set up your profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _heightUnit,
                      items: ['cm', 'ft'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _heightUnit = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your date of birth';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _gender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        double height = double.parse(_heightController.text);

        if (_heightUnit == 'ft') {
          height = height * 30.48;
        }

        final dbHelper = DatabaseHelper();
        await dbHelper.insertUserProfile(
          UserProfile(
            height: height,
            dateOfBirth: _selectedDate!,
            gender: _gender!,
            createdAt: DateTime.now(),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        debugPrint('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile. Please try again.')),
        );
      }
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weightController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<WeightEntry> _recentEntries = [];
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadData();
  }

  _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dbHelper = DatabaseHelper();
      final profile = await dbHelper.getUserProfile();
      final entries = await dbHelper.getRecentWeightEntries(10);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _recentEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data. Please try again.')),
        );
      }
    }
  }

  int _calculateAge(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  _calculateBMI(double weight) {
    if (_userProfile != null) {
      double heightInMeters = _userProfile!.height / 100;
      return weight / (heightInMeters * heightInMeters);
    }
    return 0.0;
  }

  _addWeight() async {
    if (_weightController.text.isNotEmpty) {
      try {
        double weight = double.parse(_weightController.text);
        double bmi = _calculateBMI(weight);

        final dbHelper = DatabaseHelper();
        await dbHelper.insertWeightEntry(
          WeightEntry(weight: weight, bmi: bmi, date: _selectedDate),
        );

        _weightController.clear();
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weight entry added successfully!')),
        );
      } catch (e) {
        debugPrint('Error adding weight: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding weight. Please try again.')),
        );
      }
    }
  }

  _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight & BMI Tracker'),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              } else if (value == 'reset') {
                _showResetDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'export', child: Text('Export Data')),
                PopupMenuItem(value: 'reset', child: Text('Reset Data')),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Weight Entry',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: _selectDate,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addWeight,
                            child: Text('Add Weight'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Entries',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (_recentEntries.isEmpty)
                            Text('No entries yet. Add your first weight entry!')
                          else
                            Column(
                              children: _recentEntries.map((entry) {
                                return ListTile(
                                  leading: Icon(Icons.monitor_weight),
                                  title: Text(
                                    '${entry.weight.toStringAsFixed(1)} kg',
                                  ),
                                  subtitle: Text(
                                    'BMI: ${entry.bmi.toStringAsFixed(1)} | ${DateFormat('MMM dd, yyyy').format(entry.date)}',
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChartsScreen()),
                      );
                    },
                    child: Text('View Charts'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HealthInfoScreen()),
                      );
                    },
                    child: Text('Health Information'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  _exportData() async {
    try {
      final dbHelper = DatabaseHelper();
      final entries = await dbHelper.getAllWeightEntries();
      final profile = await dbHelper.getUserProfile();

      List<List<dynamic>> csvData = [
        ['Date', 'Weight (kg)', 'BMI', 'Height (cm)', 'Age', 'Gender'],
      ];

      for (var entry in entries) {
        csvData.add([
          DateFormat('yyyy-MM-dd').format(entry.date),
          entry.weight.toStringAsFixed(1),
          entry.bmi.toStringAsFixed(1),
          profile?.height.toStringAsFixed(1) ?? '',
          profile != null ? _calculateAge(profile.dateOfBirth).toString() : '',
          profile?.gender ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/weight_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Weight & BMI Data Export');
    } catch (e) {
      debugPrint('Error exporting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting data. Please try again.')),
      );
    }
  }

  _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Data'),
        content: Text(
          'Are you sure you want to reset all data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetData();
            },
            child: Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  _resetData() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.resetAllData();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InitialSetupScreen()),
      );
    } catch (e) {
      debugPrint('Error resetting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting data. Please try again.')),
      );
    }
  }
}

class ChartsScreen extends StatefulWidget {
  @override
  _ChartsScreenState createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  List<WeightEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dbHelper = DatabaseHelper();
      final entries = await dbHelper.getAllWeightEntries();

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chart data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading chart data. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight & BMI Charts'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(child: Text('No data to display'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weight Trend',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() <
                                                _entries.length) {
                                              return Text(
                                                DateFormat('MM/dd').format(
                                                  _entries[value.toInt()].date,
                                                ),
                                                style: TextStyle(fontSize: 10),
                                              );
                                            }
                                            return Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toStringAsFixed(0),
                                              style: TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _entries
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return FlSpot(
                                            entry.key.toDouble(),
                                            entry.value.weight,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BMI Trend',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() <
                                                _entries.length) {
                                              return Text(
                                                DateFormat('MM/dd').format(
                                                  _entries[value.toInt()].date,
                                                ),
                                                style: TextStyle(fontSize: 10),
                                              );
                                            }
                                            return Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toStringAsFixed(1),
                                              style: TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _entries
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return FlSpot(
                                            entry.key.toDouble(),
                                            entry.value.bmi,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 3,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.green.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class HealthInfoScreen extends StatefulWidget {
  @override
  _HealthInfoScreenState createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  UserProfile? _userProfile;
  List<WeightEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final dbHelper = DatabaseHelper();
      final profile = await dbHelper.getUserProfile();
      final entries = await dbHelper.getAllWeightEntries();

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading health info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading health info. Please try again.')),
        );
      }
    }
  }

  int _calculateAge(DateTime dob) {
    DateTime now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  List<double> _calculateIdealWeightRange() {
    if (_userProfile == null) return [0, 0];

    double heightInMeters = _userProfile!.height / 100;
    double lowerBMI = 18.5;
    double upperBMI = 24.9;

    double lowerWeight = lowerBMI * (heightInMeters * heightInMeters);
    double upperWeight = upperBMI * (heightInMeters * heightInMeters);

    return [lowerWeight, upperWeight];
  }

  @override
  Widget build(BuildContext context) {
    final idealWeightRange = _calculateIdealWeightRange();
    final currentBMI = _entries.isNotEmpty ? _entries.last.bmi : 0;
    final bmiCategory =
        _entries.isNotEmpty ? _getBMICategory(currentBMI as double) : 'N/A';
    final age =
        _userProfile != null ? _calculateAge(_userProfile!.dateOfBirth) : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Health Information'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? Center(child: Text('No profile information available'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ListTile(
                                leading: Icon(Icons.height),
                                title: Text('Height'),
                                subtitle: Text(
                                    '${_userProfile!.height.toStringAsFixed(1)} cm'),
                              ),
                              ListTile(
                                leading: Icon(Icons.cake),
                                title: Text('Age'),
                                subtitle: Text('$age years'),
                              ),
                              ListTile(
                                leading: Icon(Icons.person),
                                title: Text('Gender'),
                                subtitle: Text(_userProfile!.gender),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Metrics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ListTile(
                                leading: Icon(Icons.monitor_weight),
                                title: Text('Ideal Weight Range'),
                                subtitle: Text(
                                    '${idealWeightRange[0].toStringAsFixed(1)} - ${idealWeightRange[1].toStringAsFixed(1)} kg'),
                              ),
                              ListTile(
                                leading: Icon(Icons.health_and_safety),
                                title: Text('Healthy BMI Range'),
                                subtitle: Text('18.5 - 24.9'),
                              ),
                              if (_entries.isNotEmpty) ...[
                                Divider(),
                                ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text('Current BMI'),
                                  subtitle: Text(
                                      '${currentBMI.toStringAsFixed(1)} ($bmiCategory)'),
                                  trailing: _getBMIIcon(currentBMI as double),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _getBMIIcon(double bmi) {
    if (bmi < 18.5) return Icon(Icons.warning, color: Colors.orange);
    if (bmi < 25) return Icon(Icons.check_circle, color: Colors.green);
    if (bmi < 30) return Icon(Icons.warning, color: Colors.orange);
    return Icon(Icons.error, color: Colors.red);
  }
}

class DatabaseHelper {
  static Database? _database;
  static const int _databaseVersion = 3; // Incremented version

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final pathToDb = path.join(dbPath, 'weight_tracker.db');

      return await openDatabase(
        pathToDb,
        version: _databaseVersion,
        onCreate: _createDb,
        onUpgrade: _upgradeDb,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        height REAL NOT NULL,
        date_of_birth TEXT NOT NULL,
        gender TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        bmi REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE user_profile ADD COLUMN date_of_birth TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN gender TEXT');
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE user_profile DROP COLUMN age');
      } catch (e) {
        debugPrint('No age column to drop: $e');
      }
    }
  }

  Future<int> insertUserProfile(UserProfile profile) async {
    try {
      final db = await database;
      return await db.insert('user_profile', profile.toMap());
    } catch (e) {
      debugPrint('Error inserting user profile: $e');
      rethrow;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('user_profile');
      if (maps.isNotEmpty) {
        return UserProfile.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }

  Future<int> insertWeightEntry(WeightEntry entry) async {
    try {
      final db = await database;
      return await db.insert('weight_entries', entry.toMap());
    } catch (e) {
      debugPrint('Error inserting weight entry: $e');
      rethrow;
    }
  }

  Future<List<WeightEntry>> getRecentWeightEntries(int limit) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_entries',
        orderBy: 'date DESC',
        limit: limit,
      );
      return List.generate(maps.length, (i) => WeightEntry.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting recent weight entries: $e');
      rethrow;
    }
  }

  Future<List<WeightEntry>> getAllWeightEntries() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'weight_entries',
        orderBy: 'date ASC',
      );
      return List.generate(maps.length, (i) => WeightEntry.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Error getting all weight entries: $e');
      rethrow;
    }
  }

  Future<void> resetAllData() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('user_profile');
        await txn.delete('weight_entries');
      });
    } catch (e) {
      debugPrint('Error resetting data: $e');
      rethrow;
    }
  }
}

class UserProfile {
  final int? id;
  final double height;
  final DateTime dateOfBirth;
  final String gender;
  final DateTime createdAt;

  UserProfile({
    this.id,
    required this.height,
    required this.dateOfBirth,
    required this.gender,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height': height,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      height: map['height'],
      dateOfBirth: DateTime.parse(map['date_of_birth']),
      gender: map['gender'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class WeightEntry {
  final int? id;
  final double weight;
  final double bmi;
  final DateTime date;

  WeightEntry({
    this.id,
    required this.weight,
    required this.bmi,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'bmi': bmi,
      'date': date.toIso8601String(),
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'],
      weight: map['weight'],
      bmi: map['bmi'],
      date: DateTime.parse(map['date']),
    );
  }
}
