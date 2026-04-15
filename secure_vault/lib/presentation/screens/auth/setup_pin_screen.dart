import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/security_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pin_input_widget.dart';

/// Two-step first-run setup: choose PIN → confirm PIN.
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  _Step   _step        = _Step.choose;
  String? _firstPin;
  String? _errorMsg;
  bool    _isLoading   = false;

  final _pinKey1 = GlobalKey<PinInputWidgetState>();
  final _pinKey2 = GlobalKey<PinInputWidgetState>();

  void _onPinChosen(String pin) {
    setState(() {
      _firstPin = pin;
      _errorMsg = null;
      _step     = _Step.confirm;
    });
  }

  Future<void> _onPinConfirmed(String pin) async {
    if (pin != _firstPin) {
      setState(() {
        _errorMsg = 'קודי ה-PIN אינם תואמים. נסה שוב.';
        _step     = _Step.choose;
        _firstPin = null;
      });
      _pinKey1.currentState?.clear();
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    final auth = context.read<AuthProvider>();
    final ok   = await auth.setupPin(pin);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeVault);
    } else {
      setState(() => _errorMsg = auth.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Icon + title
          Container(
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              gradient:     AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 36, color: Color(0xFF1A1600)),
          ),
          const SizedBox(height: 20),

          Text(
            _step == _Step.choose ? 'יצירת קוד PIN' : 'אימות קוד PIN',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _step == _Step.choose
                ? 'בחר קוד ${SecurityConstants.pinLength} ספרות לתיקייה הנעולה'
                : 'הכנס שוב את קוד ה-PIN לאימות',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // PIN input (switches between step 1 & 2)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _step == _Step.choose
                ? PinInputWidget(
                    key:         _pinKey1,
                    label:       'בחר קוד PIN',
                    onCompleted: _onPinChosen,
                    errorMessage: _errorMsg,
                  )
                : PinInputWidget(
                    key:         _pinKey2,
                    label:       'אמת קוד PIN',
                    onCompleted: _onPinConfirmed,
                    errorMessage: _errorMsg,
                  ),
          ),

          // Back button on confirm step
          if (_step == _Step.confirm) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() {
                _step     = _Step.choose;
                _firstPin = null;
                _errorMsg = null;
                _pinKey1.currentState?.clear();
              }),
              icon:  const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text('חזור'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppTheme.background.withOpacity(0.85),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.gold),
            SizedBox(height: 16),
            Text('מגדיר הצפנה…',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

enum _Step { choose, confirm }
