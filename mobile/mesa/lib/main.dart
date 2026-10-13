/* import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  final String baseUrl = 'http://localhost:8000/api';

  int pontosCasa = 0;
  int pontosFora = 0;
  bool aRegistarEvento = false;

  // Variáveis do Relógio
  Duration tempoRestante = const Duration(minutes: 10);
  Timer? cronometro;
  bool relogioAtivo = false;
  int periodoAtual = 1;

  List<Map<String, dynamic>> jogos = [];
  List<Map<String, dynamic>> jogadores = [];

  Map<String, dynamic>? jogoSelecionado;
  Map<String, dynamic>? jogadorSelecionado;

  bool aCarregar = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // --- LÓGICA DO RELÓGIO ---
  String get tempoFormatado {
    final minutos = tempoRestante.inMinutes;
    final segundos = (tempoRestante.inSeconds % 60);
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  void iniciarRelogio() {
    if (relogioAtivo || tempoRestante.inSeconds <= 0) return;

    setState(() {
      relogioAtivo = true;
    });

    cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tempoRestante.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          tempoRestante = Duration.zero;
          relogioAtivo = false;
        });
        return;
      }
      setState(() {
        tempoRestante -= const Duration(seconds: 1);
      });
    });
  }

  void pausarRelogio() {
    cronometro?.cancel();
    setState(() {
      relogioAtivo = false;
    });
  } 

  void reiniciarRelogio() { 
    cronometro?.cancel();
    setState(() {
      tempoRestante = const Duration(minutes: 10);
      relogioAtivo = false;
    });
  }

  @override
  void dispose() {
    cronometro?.cancel();
    super.dispose();
  }

  // --- LÓGICA DA API ---
  Future<void> _carregarDados() async {
    try {
      final respostas = await Future.wait([
        http.get(Uri.parse('$baseUrl/listar_jogos.php')),
        http.get(Uri.parse('$baseUrl/listar_jogadores.php')),
      ]);

      if (respostas[0].statusCode != 200 || respostas[1].statusCode != 200) {
        throw Exception('Não foi possível carregar os dados.');
      }

      final dadosJogos = List<Map<String, dynamic>>.from(jsonDecode(respostas[0].body));
      final dadosJogadores = List<Map<String, dynamic>>.from(jsonDecode(respostas[1].body));

      if (!mounted) return;

      setState(() {
        jogos = dadosJogos;
        jogadores = dadosJogadores;
        if (jogos.isNotEmpty) {
          jogoSelecionado = jogos.first;
        }
        aCarregar = false;
      });

      if (jogos.isNotEmpty) {
        await _carregarResultado();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aCarregar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int _numero(dynamic valor) {
    return int.parse(valor.toString());
  }

  List<Map<String, dynamic>> get jogadoresDaCasa {
    if (jogoSelecionado == null) return [];
    final idEquipa = _numero(jogoSelecionado!['id_equipa_casa']);
    return jogadores.where((jogador) => _numero(jogador['id_equipa']) == idEquipa).toList();
  }

  List<Map<String, dynamic>> get jogadoresDeFora {
    if (jogoSelecionado == null) return [];
    final idEquipa = _numero(jogoSelecionado!['id_equipa_fora']);
    return jogadores.where((jogador) => _numero(jogador['id_equipa']) == idEquipa).toList();
  }

  Future<void> _carregarResultado() async {
    if (jogoSelecionado == null) return;
    try {
      final idJogo = _numero(jogoSelecionado!['id_jogo']);
      final resposta = await http.get(Uri.parse('$baseUrl/obter_resultado.php?id_jogo=$idJogo'));

      if (resposta.statusCode != 200) {
        throw Exception('Erro ao carregar o resultado.');
      }

      final resultado = jsonDecode(resposta.body);
      if (!mounted) return;

      setState(() {
        pontosCasa = _numero(resultado['pontos_casa']);
        pontosFora = _numero(resultado['pontos_fora']);
      });
    } catch (e) {
      debugPrint('Erro ao carregar resultado: $e');
    }
  }

  Future<void> _registarEventoAPI(String acao) async {
    if (jogoSelecionado == null || jogadorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um jogo e um jogador.'), backgroundColor: Colors.red),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/registar_evento.php');
    final dados = {
      'tipo_evento': acao,
      'id_jogo': _numero(jogoSelecionado!['id_jogo']),
      'id_jogador': _numero(jogadorSelecionado!['id_jogador']),
      'id_equipa': _numero(jogadorSelecionado!['id_equipa']),
    };

    try {
      final resposta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dados),
      );

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        await _carregarResultado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$acao registado para ${jogadorSelecionado!['nome']}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ${resposta.statusCode}: ${resposta.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de ligação à API: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- WIDGETS ---
  Widget _criarLinhaJogador(Map<String, dynamic> jogador) {
    final selecionado = jogadorSelecionado != null &&
        _numero(jogadorSelecionado!['id_jogador']) == _numero(jogador['id_jogador']);

    return GestureDetector(
      onTap: () {
        setState(() {
          jogadorSelecionado = jogador;
        });
      },
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
          '${jogador['numero_camisola']} - ${jogador['nome']}', // Formatação corrigida
          style: TextStyle(
            fontSize: 18,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _criarBotaoAcao(String texto, Color cor) {
    return ElevatedButton(
      onPressed: () => _registarEventoAPI(texto),
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

  @override
  Widget build(BuildContext context) {
    if (aCarregar) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (jogos.isEmpty || jogoSelecionado == null) {
      return const Scaffold(
        body: Center(child: Text('Não existem jogos disponíveis.')),
      );
    }

    final casa = jogoSelecionado!['nome_equipa_casa'];
    final fora = jogoSelecionado!['nome_equipa_fora'];

    return Scaffold(
      backgroundColor: const Color(0xFF151922),
      body: SafeArea(
        child: Column(
          children: [
            // Dropdown de Seleção de Jogo
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: jogoSelecionado,
                isExpanded: true,
                dropdownColor: const Color(0xFF252C38),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  labelText: 'Jogo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF252C38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: jogos.map((jogo) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: jogo,
                    child: Text(
                      '${jogo['nome_equipa_casa']} vs ${jogo['nome_equipa_fora']} (Jogo ${jogo['id_jogo']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (jogo) async {
                  if (jogo == null) return;
                  setState(() {
                    jogoSelecionado = jogo;
                    jogadorSelecionado = null;
                    pontosCasa = 0;
                    pontosFora = 0;
                  });
                  await _carregarResultado();
                },
              ),
            ),
            
            // Corpo Principal
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =============== EQUIPA CASA ===============
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2864A5),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: Text(
                              casa.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: jogadoresDaCasa.map(_criarLinhaJogador).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // =============== COLUNA CENTRAL ===============
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // BLOCO 1: PLACAR (Envolvido em Expanded + FittedBox para zero overflows)
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7EBF0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'RESULTADO',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Color(0xFF525D6B)),
                                  ),
                                  Text(
                                    '$pontosCasa - $pontosFora', // Formatação corrigida
                                    style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF151922)),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                        decoration: BoxDecoration(color: const Color(0xFF2864A5), borderRadius: BorderRadius.circular(6)),
                                        child: Text(
                                          'Q$periodoAtual',
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        tempoFormatado,
                                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFF151922), fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: relogioAtivo ? pausarRelogio : iniciarRelogio,
                                        icon: Icon(relogioAtivo ? Icons.pause : Icons.play_arrow, size: 18),
                                        label: Text(relogioAtivo ? 'Pausar' : 'Iniciar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2864A5),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: const Size(0, 32),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: reiniciarRelogio,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFDDE2E9),
                                          foregroundColor: const Color(0xFF252C38),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        child: const Text('Reiniciar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // BLOCO 2: STATUS A DECORRER
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFF252C38), borderRadius: BorderRadius.circular(6)),
                          child: const Text(
                            'A DECORRER',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                        
                        // BLOCO 3: GRELHA DE BOTÕES
                        Expanded(
                          flex: 4,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFF252C38), borderRadius: BorderRadius.circular(10)),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final larguraBotao = (constraints.maxWidth - 8) / 2;
                                final alturaBotao = (constraints.maxHeight - 16) / 3;
                                final proporcao = alturaBotao > 0 ? larguraBotao / alturaBotao : 1.8;

                                return GridView.count(
                                  padding: EdgeInsets.zero,
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: proporcao,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _criarBotaoAcao('+ 1', const Color(0xFF219653)),
                                    _criarBotaoAcao('+ 2', const Color(0xFF219653)),
                                    _criarBotaoAcao('+ 3', const Color(0xFF219653)),
                                    _criarBotaoAcao('Time Out', const Color(0xFFE58A19)),
                                    _criarBotaoAcao('FT', const Color(0xFFD64545)),
                                    _criarBotaoAcao('FA', const Color(0xFFD64545)),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // =============== EQUIPA FORA ===============
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F6), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC34B42),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                            ),
                            child: Text(
                              fora.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: jogadoresDeFora.map(_criarLinhaJogador).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} */

import 'package:flutter/material.dart';

import 'telas/pagina_principal.dart'; // Chamamos a nossa página limpa!

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
