import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onDone;

  const CalculatorKeyboard({
    super.key,
    required this.controller,
    required this.onDone,
  });

  @override
  State<CalculatorKeyboard> createState() => _CalculatorKeyboardState();
}

class _CalculatorKeyboardState extends State<CalculatorKeyboard> {
  // Add a character or operator to the controller text
  void _input(String text) {
    widget.controller.text += text;
  }

  // Remove the last character
  void _backspace() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      widget.controller.text = text.substring(0, text.length - 1);
    }
  }

  // Clear the entire text
  void _clear() {
    widget.controller.clear();
  }

  // Evaluate the expression using math_expressions
  void _calculate() {
    if (widget.controller.text.isEmpty) return;

    try {
      String input = widget.controller.text;

      // Replace visual 'x' with '*' for parser logic if we used 'x'
      // But we will strictly use standard symbols for simplicity or match parser

      Parser p = Parser();
      Expression exp = p.parse(input);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Check if it's an integer value in float disguise (e.g. 5.0)
      if (eval % 1 == 0) {
        widget.controller.text = eval.toInt().toString();
      } else {
        // Limit decimal places
        widget.controller.text = eval.toStringAsFixed(2);
      }
    } catch (e) {
      // If error (e.g. incomplete expression "5+"), do nothing or shake?
      // For now, we just leave it. Or maybe clear it?
      // Let's just catch and ignore invalid parses during intermediate steps
      // print('Expr Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      height: 300, // Fixed height for keyboard area
      child: Column(
        children: [
          // Optional: Display current partial result?
          // For now, simple grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main numbers area
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRow(['7', '8', '9']),
                      _buildRow(['4', '5', '6']),
                      _buildRow(['1', '2', '3']),
                      _buildRow(['.', '0', 'DEL']),
                    ],
                  ),
                ),
                // Operations area
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildOpBtn('C', color: Colors.red[100]),
                      _buildOpBtn('/'),
                      _buildOpBtn('*'),
                      _buildOpBtn('-'),
                      _buildOpBtn('+'),
                      // Done/Equals button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            // First calculate any pending op
                            _calculate();
                            // Then signal done
                            widget.onDone();
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.check, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: keys.map((k) {
          if (k == 'DEL') {
            return Expanded(
              child: InkWell(
                onTap: _backspace,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.backspace_outlined)),
                ),
              ),
            );
          }
          return Expanded(
            child: InkWell(
              onTap: () => _input(k),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpBtn(String label, {Color? color}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (label == 'C') {
            _clear();
          } else {
            _input(label);
          }
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
