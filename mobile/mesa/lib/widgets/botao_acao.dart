import 'package:flutter/material.dart';

class BotaoAcao extends StatelessWidget {
  final String texto;
  final Color cor;
  final VoidCallback onPressed;

  const BotaoAcao({
    super.key,
    required this.texto,
    required this.cor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}