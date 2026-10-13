import 'package:flutter/material.dart';

class LinhaJogador extends StatelessWidget {
  final Map<String, dynamic> jogador;
  final bool selecionado;
  final VoidCallback onTap;

  const LinhaJogador({
    super.key,
    required this.jogador,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? Colors.amber[200] : Colors.white,
          border: Border.all(
            color: selecionado ? Colors.orange[800]! : Colors.grey[400]!,
            width: selecionado ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${jogador['numero_camisola']} - ${jogador['nome']}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}