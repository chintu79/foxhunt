import 'package:flutter/material.dart';
import '../space_colors.dart';

class PasscodeDialog extends StatefulWidget {
  final String expectedPasscode;

  const PasscodeDialog({super.key, required this.expectedPasscode});

  static Future<bool> show(BuildContext context, {required String expectedPasscode}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: SpaceColors.voidBlack.withValues(alpha: 0.85),
      builder: (context) => PasscodeDialog(expectedPasscode: expectedPasscode),
    );
    return result ?? false;
  }

  @override
  State<PasscodeDialog> createState() => _PasscodeDialogState();
}

class _PasscodeDialogState extends State<PasscodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'PLEASE ENTER EVENT PASSCODE';
      });
      return;
    }

    if (input.toUpperCase() == widget.expectedPasscode.trim().toUpperCase()) {
      setState(() {
        _hasError = false;
      });
      Navigator.pop(context, true);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'ACCESS DENIED // INVALID CODE';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: SpaceColors.deepCosmos,
          border: Border.all(
            color: _hasError ? Colors.redAccent : SpaceColors.cloudyBlue,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with tactical brackets
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    color: _hasError ? Colors.redAccent : SpaceColors.electricCyan,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SECURITY CLEARANCE',
                    style: TextStyle(
                      fontFamily: 'Brunson',
                      fontSize: 16,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.bold,
                      color: _hasError ? Colors.redAccent : SpaceColors.electricCyan,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _hasError ? Icons.lock_clock : Icons.lock_outline,
                    color: _hasError ? Colors.redAccent : SpaceColors.cloudyBlue,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: SpaceColors.starlightNavy, thickness: 1),
              const SizedBox(height: 16),

              Text(
                'ENTER AUTHORIZED EVENT PASSCODE TO INITIALIZE HUNT TELEMETRY:',
                style: TextStyle(
                  fontSize: 12,
                  color: SpaceColors.lunarDust.withValues(alpha: 0.9),
                  letterSpacing: 1.0,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Tactical text field with sharp edges
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'Brunson',
                  color: SpaceColors.starWhite,
                  fontSize: 18,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'PASSCODE',
                  hintStyle: TextStyle(
                    fontFamily: 'Brunson',
                    color: SpaceColors.meteorSilver.withValues(alpha: 0.5),
                    letterSpacing: 3.0,
                  ),
                  filled: true,
                  fillColor: SpaceColors.midnightNavy.withValues(alpha: 0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: _hasError ? Colors.redAccent : SpaceColors.starlightNavy,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: _hasError ? Colors.redAccent : SpaceColors.electricCyan,
                      width: 2.0,
                    ),
                  ),
                ),
                onSubmitted: (_) => _verify(),
              ),

              if (_hasError) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 28),

              // Action buttons (sharp edges)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SpaceColors.meteorSilver,
                        side: const BorderSide(color: SpaceColors.starlightNavy),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'ABORT',
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          letterSpacing: 2.0,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SpaceColors.cloudyBlue,
                        foregroundColor: SpaceColors.voidBlack,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _verify,
                      child: const Text(
                        'AUTHENTICATE',
                        style: TextStyle(
                          fontFamily: 'Brunson',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
