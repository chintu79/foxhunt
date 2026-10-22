import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'data/scanner_repository.dart';
import 'domain/target_matcher.dart';
import 'domain/rssi_processor.dart';
import 'domain/signal_state_engine.dart';
import 'domain/calibration_config.dart';
import 'ui/widgets/passcode_dialog.dart';
import 'ui/widgets/tactical_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/sound_service.dart';

import 'ui/space_colors.dart';

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
        primaryColor: SpaceColors.midnightNavy,
        scaffoldBackgroundColor: SpaceColors.voidBlack,
        colorScheme: const ColorScheme.dark(
          primary: SpaceColors.cloudyBlue,
          secondary: SpaceColors.electricCyan,
          surface: SpaceColors.deepCosmos,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: SpaceColors.deepCosmos,
          foregroundColor: SpaceColors.starWhite,
          elevation: 0,
        ),
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
      backgroundColor: SpaceColors.voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Tactical Cosmic Artwork
          Image.asset(
            'assets/foxhunt_image.png',
            fit: BoxFit.cover,
          ),
          // Deep space technical gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SpaceColors.voidBlack.withValues(alpha: 0.50),
                  SpaceColors.deepCosmos.withValues(alpha: 0.70),
                  SpaceColors.voidBlack.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  // App Logo
                  Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/foxhunt_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Title using custom font Brunson
                  const Text(
                    'FOXHUNT',
                    style: TextStyle(
                      fontFamily: 'Brunson',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                      color: SpaceColors.starWhite,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle using Brunson
                  const Text(
                    'RADIO BEACON EXPEDITION',
                    style: TextStyle(
                      fontFamily: 'Brunson',
                      fontSize: 15,
                      letterSpacing: 4.0,
                      color: SpaceColors.cloudyBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Mission briefing card - Sharp Technical HUD container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SpaceColors.midnightNavy.withValues(alpha: 0.85),
                      border: Border.all(
                        color: SpaceColors.cloudyBlue.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 3, height: 14, color: SpaceColors.electricCyan),
                            const SizedBox(width: 8),
                            const Text(
                              'TACTICAL MISSION BRIEFING',
                              style: TextStyle(
                                fontFamily: 'Brunson',
                                fontSize: 12,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                                color: SpaceColors.electricCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Track and triangulate the hidden transmitters across the sector.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 14,
                            color: SpaceColors.starWhite,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your device will scan nearby Bluetooth beacon telemetry and map live RF signal strength.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                            color: SpaceColors.lunarDust.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Start Hunt Button with Sharp Technical Edges
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: SpaceColors.electricCyan.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SpaceColors.cloudyBlue,
                        foregroundColor: SpaceColors.voidBlack,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final config = await CalibrationConfig.load();
                        if (!context.mounted) return;
                        final authorized = await PasscodeDialog.show(
                          context,
                          expectedPasscode: config.eventPasscode,
                        );
                        if (authorized && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const PermissionScreen()),
                          );
                        }
                      },
                      child: const Text(
                        'START HUNT',
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
      backgroundColor: SpaceColors.voidBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.satellite_alt, size: 72, color: SpaceColors.cloudyBlue),
              const SizedBox(height: 24),
              const Text(
                'READY TO SCAN',
                style: TextStyle(
                  fontFamily: 'Brunson',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                  color: SpaceColors.starWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SpaceColors.midnightNavy.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: SpaceColors.cloudyBlue.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Radio scanner requires system telemetry permissions:',
                      style: TextStyle(color: SpaceColors.lunarDust, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth, color: SpaceColors.cloudyBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Bluetooth Sensor', style: TextStyle(color: SpaceColors.starWhite, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: SpaceColors.cloudyBlue, size: 20),
                        SizedBox(width: 8),
                        Text('Location Telemetry', style: TextStyle(color: SpaceColors.starWhite, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SpaceColors.cloudyBlue,
                  foregroundColor: SpaceColors.voidBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  elevation: 0,
                ),
                onPressed: _checking ? null : _requestPermissions,
                child: const Text(
                  'ENABLE SCANNING',
                  style: TextStyle(
                    fontFamily: 'Brunson',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              )
            ],
          ),
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
  
  // The 2 Foxes we are looking for
  final List<String> _targetNames = [
    'FOXHUNT_01',
    'FOXHUNT_02',
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
          final normName = name.replaceAll('FOXHUNT_0', 'FOXHUNT_');
          final normTarget = targetName.replaceAll('FOXHUNT_0', 'FOXHUNT_');
          if (name == targetName || normName == normTarget) {
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
      backgroundColor: SpaceColors.voidBlack,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/foxhunt_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: const Text(
          'SELECT A TARGET',
          style: TextStyle(
            fontFamily: 'Brunson',
            letterSpacing: 3.0,
            fontSize: 20,
            color: SpaceColors.starWhite,
          ),
        ),
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
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isAvailable 
                      ? SpaceColors.midnightNavy.withValues(alpha: 0.85)
                      : SpaceColors.midnightNavy.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: isAvailable
                        ? SpaceColors.electricCyan
                        : SpaceColors.starlightNavy.withValues(alpha: 0.8),
                    width: isAvailable ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? SpaceColors.electricCyan.withValues(alpha: 0.15)
                          : SpaceColors.deepCosmos,
                      border: Border.all(
                        color: isAvailable ? SpaceColors.electricCyan : SpaceColors.starlightNavy,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '0${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isAvailable ? SpaceColors.electricCyan : SpaceColors.meteorSilver,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Brunson',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2.0,
                      color: SpaceColors.starWhite,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isCurrentlyScanning
                          ? 'SWEEPING SECTOR TELEMETRY...'
                          : (isAvailable ? 'BEACON ONLINE // READY TO TRACK' : 'BEACON OFFLINE // SWEEP FREQUENCY'),
                      style: TextStyle(
                        fontFamily: 'Brunson',
                        color: isCurrentlyScanning
                            ? SpaceColors.pulsarBlue
                            : (isAvailable ? SpaceColors.electricCyan : SpaceColors.meteorSilver),
                        fontSize: 10,
                        letterSpacing: 1.0,
                        fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAvailable && !isCurrentlyScanning)
                        const Icon(Icons.radar, color: SpaceColors.electricCyan)
                      else if (!isCurrentlyScanning)
                        const Icon(Icons.signal_wifi_off, color: SpaceColors.meteorSilver, size: 20),
                      
                      const SizedBox(width: 12),
                      
                      isCurrentlyScanning
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: SpaceColors.cloudyBlue, strokeWidth: 2)
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, color: SpaceColors.starWhite),
                            onPressed: () => _scanForDevice(name),
                            tooltip: 'Sweep Beacon Signal',
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
  CalibrationConfig _config = const CalibrationConfig();
  late RssiProcessor _processor;
  late SignalStateEngine _stateEngine;

  StreamSubscription? _scanSubscription;
  Timer? _trackingTimer;
  Timer? _smoothUpdateTimer;
  Timer? _cooldownTimer;

  HuntingState _currentState = HuntingState.cold;
  bool _hasReceivedSignal = false;
  bool _isSweeping = false;
  int _trackingRemaining = 0; // 30 down to 0 while active tracking
  int _cooldownRemaining = 0; // In seconds: 10 down to 0

  @override
  void initState() {
    super.initState();
    _matcher = TargetMatcher(config: TargetConfig(ssid: widget.targetName));
    _processor = RssiProcessor(config: _config);
    _stateEngine = SignalStateEngine(config: _config);

    _loadSavedCalibration();
    _performSignalSweep();
  }

  Future<void> _loadSavedCalibration() async {
    final loaded = await CalibrationConfig.load();
    if (mounted) {
      setState(() {
        _config = loaded;
        _processor.updateConfig(_config);
        _stateEngine.updateConfig(_config);
      });
    }
  }

  DateTime? _lastAlarmSoundTime;
  bool _alarmActive = false;

  void _checkAlarmTrigger() {
    final rssi = _processor.filteredRssi;
    if (rssi == null) {
      _alarmActive = false;
      return;
    }

    if (rssi >= _config.alarmThreshold) {
      _alarmActive = true;
    } else if (rssi < (_config.alarmThreshold - _config.hysteresisMargin)) {
      _alarmActive = false;
    }

    if (_alarmActive && _isSweeping) {
      final now = DateTime.now();
      if (_lastAlarmSoundTime == null ||
          now.difference(_lastAlarmSoundTime!).inMilliseconds >= 2500) {
        _lastAlarmSoundTime = now;
        final isReal = _config.isRealTarget(widget.targetName);
        if (isReal) {
          SoundService.playRealSound();
        } else {
          SoundService.playDummySound();
        }
      }
    }
  }

  Future<void> _performSignalSweep() async {
    if (_isSweeping || _cooldownRemaining > 0) return;

    setState(() {
      _isSweeping = true;
      _trackingRemaining = 30;
    });

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_trackingRemaining > 1) {
          _trackingRemaining--;
        } else {
          _trackingRemaining = 0;
          timer.cancel();
        }
      });
    });

    final List<ScanResultModel> sweepSamples = [];
    DateTime? lastProcessedTime;
    int? lastRawRssi;

    await _scanSubscription?.cancel();
    _scanSubscription = _repository.scanResultsStream.listen((results) {
      final target = _matcher.findTarget(results);
      if (target != null) {
        final isNew = lastProcessedTime == null ||
            target.timestamp.isAfter(lastProcessedTime!) ||
            (target.timestamp == lastProcessedTime && target.rssi != lastRawRssi);

        if (isNew) {
          lastProcessedTime = target.timestamp;
          lastRawRssi = target.rssi;
          sweepSamples.add(target);
          _processor.processSample(target.rssi, target.timestamp);

          // Real-time instantaneous UI update (< 100ms packet-to-screen response)
          if (mounted && _processor.filteredRssi != null) {
            final stability = _processor.calculateStability();
            final evaluated = _stateEngine.processSample(
              _processor.filteredRssi!,
              stability: stability,
            );

            _checkAlarmTrigger();

            setState(() {
              _currentState = evaluated;
              _hasReceivedSignal = true;
            });
          }
        }
      }
    });

    // 100ms periodic heartbeat to maintain signal state engine cadence and smooth UI updates
    _smoothUpdateTimer?.cancel();
    _smoothUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_processor.filteredRssi != null) {
        final stability = _processor.calculateStability();
        final evaluated = _stateEngine.processSample(
          _processor.filteredRssi!,
          stability: stability,
        );

        _checkAlarmTrigger();

        setState(() {
          _currentState = evaluated;
          _hasReceivedSignal = true;
        });
      }
    });

    try {
      await _repository.startScan(
        timeout: const Duration(seconds: 30),
        targetName: widget.targetName,
      );
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 30));

    _trackingTimer?.cancel();
    _smoothUpdateTimer?.cancel();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _repository.stopScan();

    if (!mounted) return;

    if (sweepSamples.isNotEmpty) {
      final stability = _processor.calculateStability();
      if (_processor.filteredRssi != null) {
        _currentState = _stateEngine.processSample(
          _processor.filteredRssi!,
          stability: stability,
        );
        _checkAlarmTrigger();
      }
      _hasReceivedSignal = true;
    }

    setState(() {
      _isSweeping = false;
      _trackingRemaining = 0;
      _cooldownRemaining = 10;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownRemaining > 1) {
          _cooldownRemaining--;
        } else {
          _cooldownRemaining = 0;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _smoothUpdateTimer?.cancel();
    _cooldownTimer?.cancel();
    _scanSubscription?.cancel();
    _repository.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor(_currentState);

    return Scaffold(
      backgroundColor: SpaceColors.voidBlack,
      appBar: AppBar(
        title: Text(
          widget.targetName,
          style: const TextStyle(
            fontFamily: 'Brunson',
            fontSize: 18,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: SpaceColors.deepCosmos,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // State Name Badge (COLD / WARM / HOT / VERY HOT) with clean sharp edges
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  border: Border.all(color: stateColor, width: 2.0),
                ),
                child: Column(
                  children: [
                    Text(
                      _hasReceivedSignal || _isSweeping
                          ? _stateEngine.getStateName(_currentState)
                          : 'READY TO SWEEP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Brunson',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: stateColor,
                      ),
                    ),
                    if (_hasReceivedSignal && _processor.filteredRssi != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${_processor.filteredRssi!.toStringAsFixed(1)} dBm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: stateColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ] else if (_isSweeping) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ACQUIRING SIGNAL...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          color: stateColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Tactical Real vs Dummy Verification Banner (Shown when signal reaches 65 dBm alarm threshold)
              if (_alarmActive && (_hasReceivedSignal || _isSweeping)) ...[
                const SizedBox(height: 12),
                _buildVerificationBanner(),
              ],

              const Spacer(flex: 1),

              // Tactical Fluctuating Receiver Field Meter
              TacticalFluctuatingMeter(
                currentState: _currentState,
                smoothedRssi: _processor.filteredRssi,
              ),

              const Spacer(flex: 2),

              // Refresh Button with 10s cooldown
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isSweeping || _cooldownRemaining > 0)
                        ? SpaceColors.midnightNavy.withValues(alpha: 0.6)
                        : SpaceColors.cloudyBlue,
                    foregroundColor: (_isSweeping || _cooldownRemaining > 0)
                        ? SpaceColors.meteorSilver
                        : SpaceColors.voidBlack,
                    disabledBackgroundColor: SpaceColors.midnightNavy.withValues(alpha: 0.6),
                    disabledForegroundColor: SpaceColors.meteorSilver,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: BorderSide(
                      color: (_isSweeping || _cooldownRemaining > 0)
                          ? SpaceColors.starlightNavy
                          : SpaceColors.electricCyan,
                      width: 1.5,
                    ),
                    elevation: 0,
                  ),
                  onPressed: (_isSweeping || _cooldownRemaining > 0)
                      ? null
                      : _performSignalSweep,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSweeping) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: SpaceColors.cloudyBlue,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _trackingRemaining > 0
                              ? 'TRACKING TRANSMITTER (${_trackingRemaining}S)...'
                              : 'TRACKING TRANSMITTER...',
                          style: const TextStyle(
                            fontFamily: 'Brunson',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ] else if (_cooldownRemaining > 0) ...[
                        const Icon(Icons.pause_circle_outline, size: 18, color: SpaceColors.meteorSilver),
                        const SizedBox(width: 8),
                        Text(
                          'PAUSED // REFRESH IN ${_cooldownRemaining}S',
                          style: const TextStyle(
                            fontFamily: 'Brunson',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'REFRESH SIGNAL',
                          style: TextStyle(
                            fontFamily: 'Brunson',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Return Button with sharp edges
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SpaceColors.starWhite,
                    side: BorderSide(color: SpaceColors.cloudyBlue.withValues(alpha: 0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'RETURN TO TARGET RADAR',
                    style: TextStyle(
                      fontFamily: 'Brunson',
                      fontSize: 13,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner() {
    final isReal = _config.isRealTarget(widget.targetName);
    final accentColor = isReal ? SpaceColors.electricCyan : const Color(0xFFFF9E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReal ? Icons.verified : Icons.warning_amber_rounded,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isReal ? 'REAL TRANSMITTER DETECTED' : 'DUMMY TRANSMITTER (EMPTY)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Brunson',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isReal
                ? 'PRIMARY OBJECTIVE VERIFIED // TARGET ACQUIRED'
                : 'DECOY MODULE DETECTED // SEARCH FOR THE OTHER FOX',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: SpaceColors.starWhite.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(HuntingState state) {
    switch (state) {
      case HuntingState.cold:
        return SpaceColors.coldBlue;
      case HuntingState.warm:
        return SpaceColors.cloudyBlue;
      case HuntingState.hot:
        return SpaceColors.pulsarBlue;
      case HuntingState.veryHot:
        return SpaceColors.electricCyan;
    }
  }
}
