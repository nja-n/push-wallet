import 'package:flutter/material.dart';

class PinPad extends StatefulWidget {
  final int pinLength;
  final Function(String) onCompleted;
  final String title;
  final bool isConfirming;

  const PinPad({
    super.key,
    this.pinLength = 4,
    required this.onCompleted,
    this.title = 'Enter PIN',
    this.isConfirming = false,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _onKeyPress(String val) {
    if (_pin.length < widget.pinLength) {
      setState(() {
        _pin += val;
      });
      if (_pin.length == widget.pinLength) {
        widget.onCompleted(_pin);
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Widget _buildButton(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: Text(
          val,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.pinLength,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _pin.length
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
        // Grid
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((e) => _buildButton(e)).toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty space for alignment
            _buildButton('0'),
            InkWell(
              onTap: _onDelete,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
