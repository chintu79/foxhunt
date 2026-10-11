import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'data/scanner_repository.dart';
import 'domain/target_matcher.dart';
import 'domain/rssi_processor.dart';
import 'domain/signal_state_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const FoxhuntApp());
}

class FoxhuntApp extends StatelessWidget {
  const FoxhuntApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foxhunt',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FOXHUNT',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4.0),
            ),
            const SizedBox(height: 32),
            const Text('Find the hidden\ntransmitters.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Your phone will scan\nnearby Bluetooth beacons.', textAlign: TextAlign.center),
            const SizedBox(height: 64),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PermissionScreen()),
                );
              },
              child: const Text('START HUNT', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _checking = false;

  Future<void> _requestPermissions() async {
    setState(() => _checking = true);
    
    if (await FlutterBluePlus.isSupported == false) {
      setState(() => _checking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth is not supported on this device.')),
        );
      }
      return;
    }

    if (Platform.isAndroid) {
      bool serviceEnabled = await Permission.location.serviceStatus.isEnabled;
      if (!serviceEnabled) {
        setState(() => _checking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable global Location Services (GPS) in your phone settings.')),
          );
        }
        return;
      }
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    bool granted = true;
    if (Platform.isAndroid) {
      granted = statuses[Permission.location]!.isGranted && 
                statuses[Permission.bluetoothScan]!.isGranted;
    }

    if (granted) {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        if (Platform.isAndroid) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            setState(() => _checking = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please turn on Bluetooth to hunt.')),
              );
            }
            return;
          }
        } else {
          setState(() => _checking = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please turn on Bluetooth in Settings to hunt.')),
            );
          }
          return;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FoxSelectionScreen()),
        );
      }
    } else {
      setState(() => _checking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location and Bluetooth permissions are strictly required.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'READY TO SCAN',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text('Bluetooth scanning needs permission/settings on your phone.'),
            const SizedBox(height: 32),
            const Text('✓ Bluetooth\n✓ Location Permission'),
            const SizedBox(height: 64),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _checking ? null : _requestPermissions,
              child: const Text('ENABLE SCANNING', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

class FoxSelectionScreen extends StatefulWidget {
  const FoxSelectionScreen({super.key});

  @override
  State<FoxSelectionScreen> createState() => _FoxSelectionScreenState();
}

class _FoxSelectionScreenState extends State<FoxSelectionScreen> {
  final ScannerRepository _repository = ScannerRepository();
  
  // The 4 Foxes we are looking for
  final List<String> _targetNames = [
    'FOXHUNT_01',
    'FOXHUNT_02',
    'FOXHUNT_03',
    'FOXHUNT_04'
  ];

  // Map to store availability status of each fox individually
  final Map<String, bool> _availability = {};
  
  // Map to store scanning status of each fox individually
  final Map<String, bool> _isScanning = {};

  @override
  void initState() {
    super.initState();
    for (var name in _targetNames) {
      _availability[name] = false;
      _isScanning[name] = false;
    }
  }

  void _scanForDevice(String targetName) async {
    // Prevent multiple scans at the same time
    if (_isScanning.values.any((isScanning) => isScanning)) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('A scan is already in progress.')),
         );
       }
       return;
    }

    setState(() {
      _isScanning[targetName] = true;
      // Reset ONLY this target's availability before scanning
      _availability[targetName] = false;
    });

    // Listen to results and update availability for ONLY the requested target
    final subscription = _repository.scanResultsStream.listen((results) {
      if (!mounted) return;
      setState(() {
        for (var result in results) {
          final name = result.ssid.trim().toUpperCase();
          if (name == targetName) {
            _availability[targetName] = true;
          }
        }
      });
    });

    await _repository.startScan(timeout: const Duration(seconds: 4));
    await Future.delayed(const Duration(seconds: 4));
    await subscription.cancel();
    
    if (mounted) {
      setState(() {
        _isScanning[targetName] = false;
      });
    }
  }

  void _startHunting(String targetName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HuntingScreen(targetName: targetName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SELECT A TARGET', style: TextStyle(letterSpacing: 2.0, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView.builder(
          itemCount: _targetNames.length,
          itemBuilder: (context, index) {
            final name = _targetNames[index];
            final isAvailable = _availability[name] ?? false;
            final isCurrentlyScanning = _isScanning[name] ?? false;
            
            return Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(
                  isCurrentlyScanning ? 'Scanning...' : (isAvailable ? 'Available - In Range' : 'Status Unknown'),
                  style: TextStyle(
                    color: isCurrentlyScanning ? Colors.orangeAccent : (isAvailable ? Colors.greenAccent : Colors.grey),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAvailable && !isCurrentlyScanning)
                      const Icon(Icons.radar, color: Colors.greenAccent)
                    else if (!isCurrentlyScanning)
                      const Icon(Icons.signal_wifi_off, color: Colors.grey),
                    
                    const SizedBox(width: 16),
                    
                    isCurrentlyScanning
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2)
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => _scanForDevice(name),
                          tooltip: 'Check Availability',
                        ),
                  ],
                ),
                onTap: isAvailable && !isCurrentlyScanning ? () => _startHunting(name) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

class HuntingScreen extends StatefulWidget {
  final String targetName;
  const HuntingScreen({super.key, required this.targetName});

  @override
  State<HuntingScreen> createState() => _HuntingScreenState();
}

class _HuntingScreenState extends State<HuntingScreen> {
  final ScannerRepository _repository = ScannerRepository();
  late TargetMatcher _matcher;
  final RssiProcessor _processor = RssiProcessor(alpha: 0.3);
  final SignalStateEngine _stateEngine = SignalStateEngine();
  
  StreamSubscription? _subscription;
  
  ScanResultModel? _currentTarget;
  SignalState? _currentState;
  Trend _currentTrend = Trend.stable;
  
  bool _searching = true;

  @override
  void initState() {
    super.initState();
    _matcher = TargetMatcher(config: TargetConfig(ssid: widget.targetName));
    _startHunting();
  }

  void _startHunting() {
    _subscription = _repository.scanResultsStream.listen((results) {
      final target = _matcher.findTarget(results);
      if (target != null) {
        final double previousFiltered = _processor.filteredRssi ?? target.rssi.toDouble();
        _processor.processSample(target.rssi);
        
        setState(() {
          _searching = false;
          _currentTarget = target;
          _currentTrend = _processor.calculateTrend(previousFiltered);
          _currentState = _stateEngine.determineState(_processor.filteredRssi!);
        });
      } else {
        setState(() {
          _searching = true;
          _currentTarget = null;
        });
      }
    });

    _repository.startScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searching) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.radar, size: 80, color: Colors.orangeAccent),
              const SizedBox(height: 32),
              const Text(
                'SEARCHING',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 4.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2),
              const SizedBox(height: 32),
              Text(
                'Target: ${widget.targetName}', 
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 12),
              Text(
                'Out of range. Keep moving to find signal.', 
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)
              ),
              const SizedBox(height: 64),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ABORT HUNT', style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
      );
    }
    
    if (_currentState == SignalState.targetRange) {
      return Scaffold(
        backgroundColor: Colors.green.shade900,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.targetName} LOCATED',
                style: const TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent.withOpacity(0.2),
                ),
                child: const Icon(Icons.location_on, size: 100, color: Colors.greenAccent),
              ),
              const SizedBox(height: 64),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                   Navigator.pop(context); // Go back to selection screen
                },
                child: const Text('BACK TO MENU', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    final String message = _stateEngine.getDisplayMessage(_currentState!);
    
    IconData trendIcon = Icons.remove;
    Color trendColor = Colors.grey;
    if (_currentTrend == Trend.stronger) {
      trendIcon = Icons.arrow_upward;
      trendColor = Colors.greenAccent;
    } else if (_currentTrend == Trend.weaker) {
      trendIcon = Icons.arrow_downward;
      trendColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HUNTING: ${widget.targetName}', 
                style: TextStyle(fontSize: 16, letterSpacing: 3.0, color: Colors.white.withOpacity(0.5))
              ),
              const SizedBox(height: 48),
              _buildBatteryIndicator(_currentState!),
              const SizedBox(height: 64),
              Text(
                _currentState.toString().split('.').last.toUpperCase(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                message, 
                style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '${_processor.filteredRssi!.toStringAsFixed(1)} dBm', 
                style: TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.white.withOpacity(0.3))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatteryIndicator(SignalState state) {
    int level = 1;
    Color activeColor = Colors.redAccent;

    switch (state) {
      case SignalState.veryCold:
        level = 1;
        activeColor = Colors.redAccent;
        break;
      case SignalState.cold:
        level = 2;
        activeColor = Colors.orangeAccent;
        break;
      case SignalState.warm:
        level = 3;
        activeColor = Colors.yellowAccent;
        break;
      case SignalState.hot:
        level = 4;
        activeColor = Colors.lightGreenAccent;
        break;
      case SignalState.veryHot:
      case SignalState.targetRange:
        level = 5;
        activeColor = Colors.greenAccent;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 80,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.02),
          ),
          child: Row(
            children: [
              Expanded(
                flex: level,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5 - level,
                child: Container(),
              ),
            ],
          ),
        ),
        Container(
          width: 12,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
          ),
        ),
      ],
    );
  }
}
