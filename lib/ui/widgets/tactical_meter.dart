import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/signal_state_engine.dart';
import '../space_colors.dart';

class TacticalFluctuatingMeter extends StatefulWidget {
  final HuntingState currentState;
  final double? smoothedRssi;

  const TacticalFluctuatingMeter({
    super.key,
    required this.currentState,
    this.smoothedRssi,
  });

  @override
  State<TacticalFluctuatingMeter> createState() => _TacticalFluctuatingMeterState();
}

class _TacticalFluctuatingMeterState extends State<TacticalFluctuatingMeter> {
  Timer? _fluctuationTimer;

  double _displayLevel = 0.15; // 0.0 to 1.0
  double _needleVelocity = 0.0;

  @override
  void initState() {
    super.initState();
    _displayLevel = _getTargetBaseLevel();
    _startFluctuationEngine();
  }

  @override
  void didUpdateWidget(covariant TacticalFluctuatingMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentState != widget.currentState ||
        oldWidget.smoothedRssi != widget.smoothedRssi) {
      final targetBase = _getTargetBaseLevel();
      final displacement = targetBase - _displayLevel;
      _needleVelocity = (_needleVelocity * 0.50) + (displacement * 0.35);
      _displayLevel = (_displayLevel + _needleVelocity).clamp(0.02, 0.98);
    }
  }

  @override
  void dispose() {
    _fluctuationTimer?.cancel();
    super.dispose();
  }

  double _getTargetBaseLevel() {
    // Piecewise mapping calibrated to thresholds:
    // Cold: < -90 dBm (floor at -100 to -90 dBm) -> 0.04..0.24
    // Warm: -90 dBm to -80 dBm                   -> 0.25..0.49
    // Hot: -80 dBm to -70 dBm                    -> 0.50..0.74
    // Very Hot: >= -70 dBm (up to -50 dBm)        -> 0.75..0.98
    if (widget.smoothedRssi != null) {
      final rssi = widget.smoothedRssi!;
      if (rssi < -90.0) {
        return (0.04 + ((rssi - (-100.0)) / 10.0) * 0.20).clamp(0.04, 0.24);
      } else if (rssi < -80.0) {
        return (0.25 + ((rssi - (-90.0)) / 10.0) * 0.24).clamp(0.25, 0.49);
      } else if (rssi < -70.0) {
        return (0.50 + ((rssi - (-80.0)) / 10.0) * 0.24).clamp(0.50, 0.74);
      } else {
        return (0.75 + ((rssi - (-70.0)) / 20.0) * 0.23).clamp(0.75, 0.98);
      }
    }

    // Fallback base on HuntingState
    switch (widget.currentState) {
      case HuntingState.cold:
        return 0.14;
      case HuntingState.warm:
        return 0.37;
      case HuntingState.hot:
        return 0.62;
      case HuntingState.veryHot:
        return 0.88;
    }
  }

  void _startFluctuationEngine() {
    // 40ms tick with silky smooth asymptotic lerp (sub-100ms response, zero twitching)
    _fluctuationTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;

      final targetBase = _getTargetBaseLevel();
      final diff = targetBase - _displayLevel;
      
      if (diff.abs() > 0.002) {
        setState(() {
          _displayLevel = (_displayLevel + diff * 0.18).clamp(0.02, 0.98);
        });
      }
    });
  }

  Color _getSegmentColor(int index, int totalSegments) {
    final progress = index / totalSegments;
    if (progress < 0.25) {
      return SpaceColors.coldBlue;
    } else if (progress < 0.50) {
      return SpaceColors.cloudyBlue;
    } else if (progress < 0.75) {
      return SpaceColors.pulsarBlue;
    } else {
      return SpaceColors.electricCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalSegments = 28;
    final activeSegments = (_displayLevel * totalSegments).round().clamp(1, totalSegments);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: SpaceColors.midnightNavy.withValues(alpha: 0.6),
        border: Border.all(color: SpaceColors.cloudyBlue.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tactical Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: SpaceColors.deepCosmos.withValues(alpha: 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: SpaceColors.electricCyan, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'RECEIVER RF S-METER',
                      style: TextStyle(
                        fontFamily: 'Brunson',
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        color: SpaceColors.starWhite,
                      ),
                    ),
                  ],
                ),
                // Calm status marker
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: SpaceColors.electricCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE RF',
                      style: TextStyle(
                        fontFamily: 'Brunson',
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: SpaceColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              children: [
                // Zone Labels: [ COLD ] [ WARM ] [ HOT ] [ VERY HOT ]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildZoneBadge('COLD', HuntingState.cold, SpaceColors.coldBlue),
                    _buildZoneBadge('WARM', HuntingState.warm, SpaceColors.cloudyBlue),
                    _buildZoneBadge('HOT', HuntingState.hot, SpaceColors.pulsarBlue),
                    _buildZoneBadge('VERY HOT', HuntingState.veryHot, SpaceColors.electricCyan),
                  ],
                ),
                const SizedBox(height: 12),

                // Multi-Segment Fluctuating LED Ladder with Sharp Edges
                Container(
                  height: 38,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SpaceColors.voidBlack.withValues(alpha: 0.8),
                    border: Border.all(color: SpaceColors.starlightNavy, width: 1.0),
                  ),
                  child: Row(
                    children: List.generate(totalSegments, (index) {
                      final isActive = index < activeSegments;
                      final segColor = _getSegmentColor(index, totalSegments);

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? segColor
                                : SpaceColors.starlightNavy.withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 8),

                // Standard ARDF Amateur Radio Receiver S-Scale markings
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('S1', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.meteorSilver)),
                    Text('S3', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.meteorSilver)),
                    Text('S5', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.meteorSilver)),
                    Text('S7', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.meteorSilver)),
                    Text('S9', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.cloudyBlue)),
                    Text('+20', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.pulsarBlue)),
                    Text('+40', style: TextStyle(fontFamily: 'Brunson', fontSize: 10, color: SpaceColors.electricCyan, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneBadge(String label, HuntingState state, Color zoneColor) {
    final isSelected = widget.currentState == state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? zoneColor.withValues(alpha: 0.2) : Colors.transparent,
        border: Border.all(
          color: isSelected ? zoneColor : SpaceColors.starlightNavy.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Brunson',
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 1.5,
          color: isSelected ? zoneColor : SpaceColors.meteorSilver.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
