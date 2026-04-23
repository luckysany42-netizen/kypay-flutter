import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Custom numpad GoPay-style yang bisa dipakai di Transfer, TopUp, Payment, QR.
///
/// Cara pakai:
/// ```dart
/// final result = await showMoneyInput(
///   context,
///   title: 'Jumlah Transfer',
///   initialValue: 0,
///   maxValue: currentBalance,
///   quickAmounts: [25000, 50000, 100000, 200000, 300000, 500000],
/// );
/// if (result != null) {
///   // pakai result (double)
/// }
/// ```

Future<double?> showMoneyInput(
  BuildContext context, {
  required String title,
  String? subtitle,
  double initialValue = 0,
  double? maxValue,
  double minValue = 1000,
  List<int> quickAmounts = const [25000, 50000, 100000, 200000, 300000, 500000],
  String confirmLabel = 'Lanjut',
  Color accentColor = const Color(0xFF0891b2),
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MoneyInputSheet(
      title: title,
      subtitle: subtitle,
      initialValue: initialValue,
      maxValue: maxValue,
      minValue: minValue,
      quickAmounts: quickAmounts,
      confirmLabel: confirmLabel,
      accentColor: accentColor,
    ),
  );
}

class MoneyInputSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double initialValue;
  final double? maxValue;
  final double minValue;
  final List<int> quickAmounts;
  final String confirmLabel;
  final Color accentColor;

  const MoneyInputSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.initialValue = 0,
    this.maxValue,
    this.minValue = 1000,
    this.quickAmounts = const [25000, 50000, 100000, 200000, 300000, 500000],
    this.confirmLabel = 'Lanjut',
    this.accentColor = const Color(0xFF0891b2),
  });

  @override
  State<MoneyInputSheet> createState() => _MoneyInputSheetState();
}

class _MoneyInputSheetState extends State<MoneyInputSheet> {
  String _raw = '';
  bool _shake = false;

  double get _value => double.tryParse(_raw) ?? 0;

  String get _formatted {
    if (_raw.isEmpty) return '0';
    final num = int.tryParse(_raw) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(num);
  }

  bool get _isValid {
    if (_value < widget.minValue) return false;
    if (widget.maxValue != null && _value > widget.maxValue!) return false;
    return true;
  }

  String get _errorText {
    if (_raw.isEmpty || _value == 0) return '';
    if (_value < widget.minValue) {
      return 'Minimal ${_rupiahCompact(widget.minValue)}';
    }
    if (widget.maxValue != null && _value > widget.maxValue!) {
      return 'Melebihi saldo (${_rupiahCompact(widget.maxValue!)})';
    }
    return '';
  }

  String _rupiahCompact(double val) {
    if (val >= 1000000) {
      return 'Rp ${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)}jt';
    }
    if (val >= 1000) {
      return 'Rp ${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}rb';
    }
    return 'Rp ${val.toInt()}';
  }

  void _input(String key) {
    setState(() {
      if (key == '⌫') {
        if (_raw.isNotEmpty) _raw = _raw.substring(0, _raw.length - 1);
        return;
      }
      if (key == '000') {
        if (_raw.isEmpty) return;
        if (_raw.length + 3 > 12) return;
        _raw = '${_raw}000';
        return;
      }
      if (key == '0' && _raw.isEmpty) return;
      if (_raw.length >= 12) return;
      _raw += key;
    });

    if (widget.maxValue != null && _value > widget.maxValue! && !_shake) {
      _triggerShake();
    }
  }

  void _setQuick(int amount) {
    if (widget.maxValue != null && amount > widget.maxValue!) {
      _triggerShake();
      return;
    }
    setState(() => _raw = amount.toString());
  }

  void _triggerShake() async {
    setState(() => _shake = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _shake = false);
  }

  void _confirm() {
    if (!_isValid) {
      _triggerShake();
      return;
    }
    Navigator.pop(context, _value);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      _raw = widget.initialValue.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1a2340),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Display nominal
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _raw.isNotEmpty && !_isValid
                        // ignore: deprecated_member_use
                        ? Colors.red.withOpacity(0.5)
                        // ignore: deprecated_member_use
                        : widget.accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rp',
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: _shake
                          ? Tween(begin: -10.0, end: 0.0)
                          : Tween(begin: 0.0, end: 0.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (_, offset, child) => Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      ),
                      child: Text(
                        _formatted,
                        style: TextStyle(
                          color: _raw.isNotEmpty && !_isValid
                              ? Colors.red
                              : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    if (_errorText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _errorText,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Quick amount chips
            if (widget.quickAmounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.quickAmounts.map((amt) {
                    final isOver =
                        widget.maxValue != null && amt > widget.maxValue!;
                    final label = amt >= 1000000
                        ? '${amt ~/ 1000000}jt'
                        : '${amt ~/ 1000}rb';
                    return GestureDetector(
                      onTap: () => _setQuick(amt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isOver
                              // ignore: deprecated_member_use
                              ? Colors.white.withOpacity(0.03)
                              // ignore: deprecated_member_use
                              : widget.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOver
                                // ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.06)
                                // ignore: deprecated_member_use
                                : widget.accentColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Rp$label',
                          style: TextStyle(
                            color: isOver
                                // ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.2)
                                : widget.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const Divider(color: Colors.white10, height: 1),

            // Numpad
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                children: [
                  _buildNumRow(['1', '2', '3']),
                  const SizedBox(height: 8),
                  _buildNumRow(['4', '5', '6']),
                  const SizedBox(height: 8),
                  _buildNumRow(['7', '8', '9']),
                  const SizedBox(height: 8),
                  _buildNumRow(['000', '0', '⌫']),
                ],
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isValid ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isValid
                        ? '${widget.confirmLabel}  —  Rp $_formatted'
                        : widget.confirmLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        final isBackspace = k == '⌫';
        final isTripleZero = k == '000';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => _input(k),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: isBackspace
                      // ignore: deprecated_member_use
                      ? Colors.white.withOpacity(0.04)
                      // ignore: deprecated_member_use
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_outlined,
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.6),
                          size: 20,
                        )
                      : Text(
                          k,
                          style: TextStyle(
                            color: isTripleZero
                                // ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.7)
                                : Colors.white,
                            fontSize: isTripleZero ? 16 : 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}