<?php

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

ini_set('display_errors', 0);

require_once '../ligacao.php';

$id_jogo = isset($_GET['id_jogo']) ? intval($_GET['id_jogo']) : 0;

if ($id_jogo <= 0) {
    http_response_code(400);
    echo json_encode(["error" => "ID do jogo em falta ou inválido."]);
    exit;
}

try {
    $sql = "SELECT
                j.id_equipa_casa,
                j.id_equipa_fora,
                j.tempo_formatado,
                j.periodo,
                COALESCE(SUM(
                    CASE
                        WHEN e.id_equipa = j.id_equipa_casa
                             AND e.tipo_evento IN ('+1', '+2', '+3', '+ 1', '+ 2', '+ 3')
                        THEN CAST(TRIM(REPLACE(e.tipo_evento, '+', '')) AS UNSIGNED)
                        ELSE 0
                    END
                ), 0) AS pontos_casa,
                COALESCE(SUM(
                    CASE
                        WHEN e.id_equipa = j.id_equipa_fora
                             AND e.tipo_evento IN ('+1', '+2', '+3', '+ 1', '+ 2', '+ 3')
                        THEN CAST(TRIM(REPLACE(e.tipo_evento, '+', '')) AS UNSIGNED)
                        ELSE 0
                    END
                ), 0) AS pontos_fora
            FROM Jogo j
            LEFT JOIN Evento_Jogo e ON e.id_jogo = j.id_jogo
            WHERE j.id_jogo = :id_jogo
            GROUP BY j.id_jogo, j.id_equipa_casa, j.id_equipa_fora, j.tempo_formatado, j.periodo";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id_jogo' => $id_jogo]);

    $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$resultado) {
        http_response_code(404);
        echo json_encode(["error" => "Jogo não encontrado."]);
        exit;
    }

    $resposta = [
        'pontos_casa'     => (int) ($resultado['pontos_casa'] ?? 0),
        'pontos_fora'     => (int) ($resultado['pontos_fora'] ?? 0),
        'tempo_formatado' => $resultado['tempo_formatado'] ?? '10:00',
        'periodo'         => isset($resultado['periodo']) ? (int)$resultado['periodo'] : 1
    ];

    echo json_encode($resposta);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao obter o resultado do jogo: " . $e->getMessage()]);
}