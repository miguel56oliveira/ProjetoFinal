import 'package:flutter/material.dart';

import 'telas/pagina_principal.dart'; 

void main() {
  runApp(const BasquetebolApp());
}

class BasquetebolApp extends StatelessWidget {
  const BasquetebolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesa de Jogo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PaginaPrincipal(),
    );
  }
}
