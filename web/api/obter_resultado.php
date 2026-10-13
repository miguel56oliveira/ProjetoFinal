<?php

header('Access-Control-Allow-Origin: http://localhost:50249');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once '../ligacao.php';

$id_jogo = $_GET['id_jogo'] ?? null;

if (!$id_jogo) {
    http_response_code(400);
    echo json_encode(["error" => "ID do jogo em falta."]);
    exit;
}

try {
    $sql = "SELECT
                j.id_equipa_casa,
                j.id_equipa_fora,
                COALESCE(SUM(
                    CASE
                        WHEN e.id_equipa = j.id_equipa_casa
                             AND e.tipo_evento IN ('+1', '+2', '+3', '+ 1', '+ 2', '+ 3')
                        THEN CAST(SUBSTRING(e.tipo_evento, 2) AS UNSIGNED)
                        ELSE 0
                    END
                ), 0) AS pontos_casa,
                COALESCE(SUM(
                    CASE
                        WHEN e.id_equipa = j.id_equipa_fora
                             AND e.tipo_evento IN ('+1', '+2', '+3', '+ 1', '+ 2', '+ 3')
                        THEN CAST(TRIM(SUBSTRING(e.tipo_evento, 2)) AS UNSIGNED)
                        ELSE 0
                    END
                ), 0) AS pontos_fora
            FROM Jogo j
            LEFT JOIN Evento_Jogo e ON e.id_jogo = j.id_jogo
            WHERE j.id_jogo = :id_jogo
            GROUP BY j.id_jogo, j.id_equipa_casa, j.id_equipa_fora";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([':id_jogo' => $id_jogo]);

    $resultado = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$resultado){
        http_response_code(404);
        echo json_encode(["error" => "Jogo não encontrado."]);
        exit;
    }

    echo json_encode($resultado);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao obter o resultado do jogo: " . $e->getMessage()]);
}

?>