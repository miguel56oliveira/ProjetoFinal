import 'package:flutter/material.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greyy[900],
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[300],
                margin: const EdgeInsets.all(4.0),
                child: const Center(child: Text('Lista Equipa A', style: TextStyle(fontSize: 24))),
              ),
            ),
            Expanded(
              flex: 3,
              child: [
                Expanded(
                  flex: 1, 
                  child: Container(
                    color: Colors.grey[400],
                    margin: const EdgeInsets.all(4.0),
                    width: double.infinity,
                    child:  Text('00 : 00\nQ0', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                  )
                ),
            ),

            Expanded(
              flex: 4,
              child: Container(
                color: Colors.grey[400],
                margin: const EdgeInsets.all(4.0),
                width: double.infinity,
                child: const Center(child: Text('Grelha de Botões', style: TextStyle(fontSize: 24))),
              )
            ),
          ],
        ),
      )
}