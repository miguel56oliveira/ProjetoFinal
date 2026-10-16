import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Importar os widgets personalizados
import '../widgets/botao_acao.dart';
import '../widgets/linha_jogador.dart';

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

  int faltasCasa = 0;
  int faltasFora = 0;
  int timeoutsCasa = 0;
  int timeoutsFora = 0;

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
    setState(() => relogioAtivo = true);

    cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tempoRestante.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          if (periodoAtual < 4) {
            periodoAtual++;
            tempoRestante = const Duration(minutes: 10);
            faltasCasa = 0;
            faltasFora = 0;
          } else {
            tempoRestante = Duration.zero;
          }
          relogioAtivo = false;
        });

        _sincronizarTempoAPI();
        return;
      }
      setState(() => tempoRestante -= const Duration(seconds: 1));
      _sincronizarTempoAPI();
    });
  }

  void pausarRelogio() {
    cronometro?.cancel();
    setState(() => relogioAtivo = false);
    _sincronizarTempoAPI();
  }

  void reiniciarRelogio() {
    cronometro?.cancel();
    setState(() {
      tempoRestante = const Duration(minutes: 10);
      relogioAtivo = false;
    });
    _sincronizarTempoAPI();
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
        throw Exception('Erro ao carregar dados.');
      }

      if (!mounted) return;
      setState(() {
        jogos = List<Map<String, dynamic>>.from(jsonDecode(respostas[0].body));
        jogadores = List<Map<String, dynamic>>.from(
          jsonDecode(respostas[1].body),
        );
        if (jogos.isNotEmpty) jogoSelecionado = jogos.first;
        aCarregar = false;
      });

      if (jogos.isNotEmpty) await _carregarResultado();
    } catch (e) {
      if (!mounted) return;
      setState(() => aCarregar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int _numero(dynamic valor) => int.parse(valor.toString());

  List<Map<String, dynamic>> get jogadoresDaCasa {
    if (jogoSelecionado == null) return [];
    final idEquipa = _numero(jogoSelecionado!['id_equipa_casa']);
    return jogadores.where((j) => _numero(j['id_equipa']) == idEquipa).toList();
  }

  List<Map<String, dynamic>> get jogadoresDeFora {
    if (jogoSelecionado == null) return [];
    final idEquipa = _numero(jogoSelecionado!['id_equipa_fora']);
    return jogadores.where((j) => _numero(j['id_equipa']) == idEquipa).toList();
  }

  Future<void> _carregarResultado() async {
    if (jogoSelecionado == null) return;
    try {
      final idJogo = _numero(jogoSelecionado!['id_jogo']);
      final resposta = await http.get(
        Uri.parse('$baseUrl/obter_resultado.php?id_jogo=$idJogo'),
      );

      if (resposta.statusCode == 200) {
        final resultado = jsonDecode(resposta.body);
        if (!mounted) return;
        setState(() {
          pontosCasa = _numero(resultado['pontos_casa']);
          pontosFora = _numero(resultado['pontos_fora']);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar resultado: $e');
    }
  }

  Future<void> _registarEventoAPI(String acao) async {
    if (jogoSelecionado == null || jogadorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um jogo e um jogador.'),
          backgroundColor: Colors.red,
        ),
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
            content: Text(
              '$acao registado para ${jogadorSelecionado!['nome']}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ${resposta.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na API: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sincronizarTempoAPI() async {
    if (jogoSelecionado == null) return;

    final idJogo = _numero(jogoSelecionado!['id_jogo']);

    final url = Uri.parse('$baseUrl/atualizar_tempo.php');
    final dados = {
      'id_jogo': idJogo,
      'tempo_formatado': tempoFormatado,
      'periodo': periodoAtual,
    };

    try {
      final resposta = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(dados),
      );

      debugPrint('Resposta Tempo: ${resposta.statusCode} - ${resposta.body}');
    } catch (e) {
      debugPrint('Erro ao sincronizar tempo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (aCarregar) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (jogos.isEmpty || jogoSelecionado == null) {
      return const Scaffold(body: Center(child: Text('Não há jogos.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF151922),
      body: SafeArea(
        child: Column(
          children: [
            // Dropdown do Jogo
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: jogos.map((jogo) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: jogo,
                    child: Text(
                      '${jogo['nome_equipa_casa']} vs ${jogo['nome_equipa_fora']}',
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

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // EQUIPA CASA
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2864A5),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              jogoSelecionado!['nome_equipa_casa'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: jogadoresDaCasa.map((jogador) {
                                final selecionado =
                                    jogadorSelecionado != null &&
                                    _numero(
                                          jogadorSelecionado!['id_jogador'],
                                        ) ==
                                        _numero(jogador['id_jogador']);
                                return LinhaJogador(
                                  jogador: jogador,
                                  selecionado: selecionado,
                                  onTap: () => setState(
                                    () => jogadorSelecionado = jogador,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // COLUNA CENTRAL
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF525D6B),
                                    ),
                                  ),
                                  Text(
                                    '$pontosCasa - $pontosFora',
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF151922),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2864A5),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Q$periodoAtual',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        tempoFormatado,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF151922),
                                          fontFamily: 'monospace',
                                        ),
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
                                        onPressed: relogioAtivo
                                            ? pausarRelogio
                                            : iniciarRelogio,
                                        icon: Icon(
                                          relogioAtivo
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          size: 18,
                                        ),
                                        label: Text(
                                          relogioAtivo ? 'Pausar' : 'Iniciar',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: reiniciarRelogio,
                                        child: const Text('Reiniciar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252C38),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'A DECORRER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 4,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252C38),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final proporcao =
                                    ((constraints.maxHeight - 16) / 3) > 0
                                    ? ((constraints.maxWidth - 8) / 2) /
                                          ((constraints.maxHeight - 16) / 3)
                                    : 1.8;
                                return GridView.count(
                                  padding: EdgeInsets.zero,
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: proporcao,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    BotaoAcao(
                                      texto: '+ 1',
                                      cor: const Color(0xFF219653),
                                      onPressed: () =>
                                          _registarEventoAPI('+ 1'),
                                    ),
                                    BotaoAcao(
                                      texto: '+ 2',
                                      cor: const Color(0xFF219653),
                                      onPressed: () =>
                                          _registarEventoAPI('+ 2'),
                                    ),
                                    BotaoAcao(
                                      texto: '+ 3',
                                      cor: const Color(0xFF219653),
                                      onPressed: () =>
                                          _registarEventoAPI('+ 3'),
                                    ),
                                    BotaoAcao(
                                      texto: 'Time Out',
                                      cor: const Color(0xFFE58A19),
                                      onPressed: () =>
                                          _registarEventoAPI('Time Out'),
                                    ),
                                    BotaoAcao(
                                      texto: 'FT',
                                      cor: const Color(0xFFD64545),
                                      onPressed: () => _registarEventoAPI('FT'),
                                    ),
                                    BotaoAcao(
                                      texto: 'FA',
                                      cor: const Color(0xFFD64545),
                                      onPressed: () => _registarEventoAPI('FA'),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // EQUIPA FORA
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC34B42),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              jogoSelecionado!['nome_equipa_fora'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: jogadoresDeFora.map((jogador) {
                                final selecionado =
                                    jogadorSelecionado != null &&
                                    _numero(
                                          jogadorSelecionado!['id_jogador'],
                                        ) ==
                                        _numero(jogador['id_jogador']);
                                return LinhaJogador(
                                  jogador: jogador,
                                  selecionado: selecionado,
                                  onTap: () => setState(
                                    () => jogadorSelecionado = jogador,
                                  ),
                                );
                              }).toList(),
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
}