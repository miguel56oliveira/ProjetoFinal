<!DOCTYPE html>
<html lang="pt-PT">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Basquetebol - Resultado em Direto</title>
    <style>
        body {
            margin: 0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #151922; 
            color: white;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        .header h1 {
            margin: 0;
            color: #f1f3f6;
            font-size: 28px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .scoreboard {
            display: flex;
            background-color: #252c38;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            width: 90%;
            max-width: 800px;
            justify-content: space-between;
            align-items: center;
        }
        .equipa {
            flex: 1;
            text-align: center;
        }
        .equipa h2 {
            margin: 0;
            font-size: 24px;
            color: #f1f3f6;
        }
        .pontuacao {
            font-size: 80px;
            font-weight: bold;
            margin: 10px 0;
        }
        .casa .pontuacao { color: #2864A5; } 
        .fora .pontuacao { color: #C34B42; }
        
        .centro {
            flex: 1;
            text-align: center;
            padding: 0 20px;
        }
        .periodo {
            background-color: #E7EBF0;
            color: #151922;
            padding: 5px 15px;
            border-radius: 5px;
            font-weight: bold;
            font-size: 18px;
            display: inline-block;
            margin-bottom: 10px;
        }
        .tempo {
            font-size: 45px;
            font-family: monospace;
            font-weight: bold;
        }
        .estado {
            margin-top: 10px;
            font-size: 14px;
            color: #4CAF50; 
            text-transform: uppercase;
            letter-spacing: 1px;
            font-weight: bold;
        }
    </style>
</head>
<body>

    <div class="header">
        <h1>Basquetebol em Direto</h1>
        <p>Acompanha o resultado em tempo real</p>
    </div>

    <div class="scoreboard">
        <!-- Equipa da Casa -->
        <div class="equipa casa">
            <h2 id="nome-casa">Equipa Casa</h2>
            <div class="pontuacao" id="pontos-casa">0</div>
        </div>

        <div class="centro">
            <div class="periodo" id="periodo">Q1</div>
            <div class="tempo" id="tempo">10:00</div>
            <div class="estado">A Decorrer</div>
        </div>

        <div class="equipa fora">
            <h2 id="nome-fora">Equipa Fora</h2>
            <div class="pontuacao" id="pontos-fora">0</div>
        </div>
    </div>

    <script>
        const baseUrl = 'http://localhost:8000/api';
        let idJogoAtual = null;

        // Função para escrever mensagens diretamente no ecrã (no lugar do estado)
        function mostrarMensagem(texto) {
            const el = document.querySelector('.estado');
            if (el) el.textContent = texto;
        }

        async function carregarJogo() {
            mostrarMensagem('A ligar à API...');

            try {
                const resposta = await fetch(`${baseUrl}/listar_jogos.php`);
                
                if (!resposta.ok) {
                    mostrarMensagem(`Erro HTTP na API: ${resposta.status}`);
                    return;
                }

                const jogos = await resposta.json();

                if (Array.isArray(jogos) && jogos.length > 0) {
                    const jogo = jogos[0];
                    idJogoAtual = jogo.id_jogo;

                    document.getElementById('nome-casa').textContent = jogo.nome_equipa_casa ?? 'Casa';
                    document.getElementById('nome-fora').textContent = jogo.nome_equipa_fora ?? 'Fora';

                    mostrarMensagem('Jogo carregado! A obter resultado...');
                    await atualizarResultado();
                } else {
                    mostrarMensagem('Sem jogos na base de dados.');
                }
            } catch (erro) {
                // Se falhar a ligação/CORS, mostra o erro no ecrã
                mostrarMensagem(`Erro de rede: ${erro.message}`);
            }
        }

        async function atualizarResultado() {
            if (!idJogoAtual) return;

            try {
                const resposta = await fetch(`${baseUrl}/obter_resultado.php?id_jogo=${idJogoAtual}`);
                if (!resposta.ok) return;

                const resultado = await resposta.json();

                document.getElementById('pontos-casa').textContent = resultado.pontos_casa ?? 0;
                document.getElementById('pontos-fora').textContent = resultado.pontos_fora ?? 0;
                
                if (resultado.tempo_formatado) {
                    document.getElementById('tempo').textContent = resultado.tempo_formatado;
                }
                if (resultado.periodo) {
                    document.getElementById('periodo').textContent = `Q${resultado.periodo}`;
                }

                mostrarMensagem('A decorrer (Em Direto)');
            } catch (erro) {
                mostrarMensagem(`Erro ao atualizar pontos: ${erro.message}`);
            }
        }

        // Executa ao carregar
        carregarJogo();

        // Atualiza a cada 1 segundo
        setInterval(atualizarResultado, 500);
    </script>
</body>
</html>