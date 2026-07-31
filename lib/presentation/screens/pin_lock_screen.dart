import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_lock_provider.dart';
import '../../core/theme.dart';

enum PinLockMode {
  unlock,
  create,
  change,
  verify,
}

class PinLockScreen extends ConsumerStatefulWidget {
  final PinLockMode mode;
  final VoidCallback? onUnlocked;

  const PinLockScreen({
    super.key,
    this.mode = PinLockMode.unlock,
    this.onUnlocked,
  });

  static Future<bool?> showVerify(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PinLockScreen(mode: PinLockMode.verify),
    );
  }

  static Future<bool?> showCreate(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PinLockScreen(mode: PinLockMode.create),
    );
  }

  static Future<bool?> showChange(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const PinLockScreen(mode: PinLockMode.change),
    );
  }

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPinAttempt = '';
  String _oldPinAttempt = '';
  int _step = 1; // 1 for first prompt, 2 for confirm/new pin

  String _errorMessage = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerError(String msg) {
    setState(() {
      _errorMessage = msg;
      _enteredPin = '';
    });
    _shakeController.forward(from: 0.0);
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _errorMessage = '';
      _enteredPin += val;
    });

    if (_enteredPin.length == 4) {
      _processPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = '';
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClear() {
    setState(() {
      _errorMessage = '';
      _enteredPin = '';
    });
  }

  Future<void> _processPin() async {
    final notifier = ref.read(appLockProvider.notifier);

    switch (widget.mode) {
      case PinLockMode.unlock:
        if (notifier.verifyPin(_enteredPin)) {
          notifier.unlock();
          if (widget.onUnlocked != null) {
            widget.onUnlocked!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else {
          _triggerError('Incorrect PIN. Please try again.');
        }
        break;

      case PinLockMode.verify:
        if (notifier.verifyPin(_enteredPin)) {
          Navigator.pop(context, true);
        } else {
          _triggerError('Incorrect PIN. Try again.');
        }
        break;

      case PinLockMode.create:
        if (_step == 1) {
          setState(() {
            _firstPinAttempt = _enteredPin;
            _enteredPin = '';
            _step = 2;
          });
        } else {
          if (_enteredPin == _firstPinAttempt) {
            await notifier.setPinAndEnable(_enteredPin);
            if (mounted) Navigator.pop(context, true);
          } else {
            _triggerError('PINs do not match. Start over.');
            setState(() {
              _firstPinAttempt = '';
              _step = 1;
            });
          }
        }
        break;

      case PinLockMode.change:
        if (_step == 1) {
          if (notifier.verifyPin(_enteredPin)) {
            setState(() {
              _oldPinAttempt = _enteredPin;
              _enteredPin = '';
              _step = 2;
            });
          } else {
            _triggerError('Incorrect current PIN.');
          }
        } else if (_step == 2) {
          setState(() {
            _firstPinAttempt = _enteredPin;
            _enteredPin = '';
            _step = 3;
          });
        } else {
          if (_enteredPin == _firstPinAttempt) {
            await notifier.changePin(_oldPinAttempt, _enteredPin);
            if (mounted) Navigator.pop(context, true);
          } else {
            _triggerError('New PINs do not match. Try again.');
            setState(() {
              _firstPinAttempt = '';
              _step = 2;
            });
          }
        }
        break;
    }
  }

  String get _headerTitle {
    switch (widget.mode) {
      case PinLockMode.unlock:
        return 'Epicordia';
      case PinLockMode.create:
        return _step == 1 ? 'Create PIN' : 'Confirm PIN';
      case PinLockMode.change:
        if (_step == 1) return 'Verify Current PIN';
        if (_step == 2) return 'New 4-Digit PIN';
        return 'Confirm New PIN';
      case PinLockMode.verify:
        return 'Verify PIN';
    }
  }

  String get _headerSubtitle {
    switch (widget.mode) {
      case PinLockMode.unlock:
        return 'Enter your 4-digit PIN to access workspace';
      case PinLockMode.create:
        return _step == 1
            ? 'Enter a 4-digit PIN to secure your app'
            : 'Re-enter your 4-digit PIN to confirm';
      case PinLockMode.change:
        if (_step == 1) return 'Enter your current PIN to change it';
        if (_step == 2) return 'Enter your new 4-digit PIN';
        return 'Re-enter your new 4-digit PIN to confirm';
      case PinLockMode.verify:
        return 'Enter your PIN to confirm this change';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final accentColor = isDark ? EpicordiaColors.blue400 : EpicordiaColors.blue600;
    final errorColor = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;

    final canCancel = widget.mode != PinLockMode.unlock;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              // Top Bar / Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canCancel)
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondary),
                      onPressed: () => Navigator.pop(context, false),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const SizedBox(width: 48),
                ],
              ),

              const Spacer(flex: 1),

              // Logo / Lock Icon Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.mode == PinLockMode.create || widget.mode == PinLockMode.change
                      ? Icons.phonelink_lock_rounded
                      : Icons.lock_outline_rounded,
                  size: 34,
                  color: accentColor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _headerTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _headerSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // PIN Indicator Dots with Shake Animation
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * (1 - (_shakeController.value - 0.5).abs() * 2), 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    final hasError = _errorMessage.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasError
                            ? errorColor
                            : isFilled
                                ? accentColor
                                : Colors.transparent,
                        border: Border.all(
                          color: hasError
                              ? errorColor
                              : isFilled
                                  ? accentColor
                                  : isDark
                                      ? EpicordiaColors.borderStrongDark
                                      : EpicordiaColors.borderStrongLight,
                          width: 2,
                        ),
                        boxShadow: isFilled && !hasError
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 16),

              // Error Text Slot
              SizedBox(
                height: 24,
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: TextStyle(
                          color: errorColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),

              const Spacer(flex: 2),

              // Numeric Keypad Grid (0-9)
              Column(
                children: [
                  _buildKeyRow(['1', '2', '3'], isDark, textPrimary),
                  const SizedBox(height: 16),
                  _buildKeyRow(['4', '5', '6'], isDark, textPrimary),
                  const SizedBox(height: 16),
                  _buildKeyRow(['7', '8', '9'], isDark, textPrimary),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.clear_rounded,
                        onTap: _onClear,
                        isDark: isDark,
                        textSecondary: textSecondary,
                      ),
                      _buildKeyButton('0', isDark, textPrimary),
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                        isDark: isDark,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, bool isDark, Color textPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key, isDark, textPrimary)).toList(),
    );
  }

  Widget _buildKeyButton(String key, bool isDark, Color textPrimary) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? EpicordiaColors.surfaceCardDark.withValues(alpha: 0.6)
              : EpicordiaColors.surfaceCardLight,
          border: Border.all(
            color: isDark
                ? EpicordiaColors.borderSubtleDark
                : EpicordiaColors.borderSubtleLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          key,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Icon(
          icon,
          size: 24,
          color: textSecondary,
        ),
      ),
    );
  }
}
