import 'package:flutter/material.dart';
import '../../core/constants/security_constants.dart';
import '../theme/app_theme.dart';

/// A custom numeric PIN pad with animated dot indicators.
///
/// Fires [onCompleted] when the user enters the required number of digits.
class PinInputWidget extends StatefulWidget {
  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.errorMessage,
    this.label = 'הכנס קוד PIN',
    this.clearOnError = true,
  });

  final void Function(String pin) onCompleted;
  final String? errorMessage;
  final String  label;
  final bool    clearOnError;

  @override
  State<PinInputWidget> createState() => PinInputWidgetState();
}

class PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  final _pin = <int>[];
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(PinInputWidget old) {
    super.didUpdateWidget(old);
    if (widget.errorMessage != null &&
        widget.errorMessage != old.errorMessage) {
      _shake();
      if (widget.clearOnError) clear();
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  void clear() {
    setState(() => _pin.clear());
  }

  void _onDigit(int d) {
    if (_pin.length >= SecurityConstants.pinLength) return;
    setState(() => _pin.add(d));
    if (_pin.length == SecurityConstants.pinLength) {
      final pin = _pin.join();
      widget.onCompleted(pin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // Dot indicators
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (context, child) {
            final offset = (_shakeAnim.value * 2 - 1) *
                8 *
                (1 - _shakeAnim.value);
            return Transform.translate(
              offset: Offset(offset * 8, 0),
              child: child,
            );
          },
          child: _buildDots(),
        ),
        const SizedBox(height: 8),

        // Error message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: widget.errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.errorMessage!,
                    key: ValueKey(widget.errorMessage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox(height: 24, key: ValueKey('empty')),
        ),
        const SizedBox(height: 32),

        // Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(SecurityConstants.pinLength, (i) {
        final filled = i < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width:  filled ? 16 : 14,
          height: filled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.gold : Colors.transparent,
            border: Border.all(
              color: filled ? AppTheme.gold : AppTheme.border,
              width: 2,
            ),
            boxShadow: filled
                ? [BoxShadow(
                    color:     AppTheme.gold.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow([1, 2, 3]),
        const SizedBox(height: 12),
        _buildKeyRow([4, 5, 6]),
        const SizedBox(height: 12),
        _buildKeyRow([7, 8, 9]),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmptyKey(),
            const SizedBox(width: 12),
            _DigitKey(digit: 0, onPressed: _onDigit),
            const SizedBox(width: 12),
            _DeleteKey(onPressed: _onDelete),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<int> digits) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: digits.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(right: e.key < digits.length - 1 ? 12 : 0),
          child:   _DigitKey(digit: e.value, onPressed: _onDigit),
        );
      }).toList(),
    );
  }
}

// ── Key Widgets ────────────────────────────────────────────────────────────────

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onPressed});
  final int              digit;
  final void Function(int) onPressed;

  @override
  Widget build(BuildContext context) {
    return _KeyBase(
      onTap: () => onPressed(digit),
      child: Text(
        digit.toString(),
        style: const TextStyle(
          fontSize:   24,
          fontWeight: FontWeight.w600,
          color:      AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _DeleteKey extends StatelessWidget {
  const _DeleteKey({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _KeyBase(
      onTap: onPressed,
      child: const Icon(Icons.backspace_outlined,
          color: AppTheme.textSecondary, size: 22),
    );
  }
}

class _EmptyKey extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 76, height: 76);
}

class _KeyBase extends StatefulWidget {
  const _KeyBase({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_KeyBase> createState() => _KeyBaseState();
}

class _KeyBaseState extends State<_KeyBase> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width:  76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? AppTheme.surfaceVariant.withOpacity(0.8)
              : AppTheme.surface,
          border: Border.all(
            color: _pressed ? AppTheme.gold.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
