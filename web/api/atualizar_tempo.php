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

// 1. Tentar ler o corpo JSON
$rawInput = file_get_contents('php://input');
$dados = json_decode($rawInput, true);

// 2. Se o JSON falhar, tenta ler de $_POST
if (!is_array($dados) && !empty($_POST)) {
    $dados = $_POST;
}

$id_jogo = 0;
if (is_array($dados)) {
    if (isset($dados['id_jogo'])) {
        $id_jogo = intval($dados['id_jogo']);
    } elseif (isset($dados['id'])) {
        $id_jogo = intval($dados['id']);
    }
}

$tempo_formatado = isset($dados['tempo_formatado']) ? $dados['tempo_formatado'] : '10:00';
$periodo = isset($dados['periodo']) ? intval($dados['periodo']) : 1;

// Se continuar a ser 0, devolve o que o PHP recebeu para diagnóstico
if ($id_jogo <= 0) {
    http_response_code(400);
    echo json_encode([
        "error" => "Dados em falta ou inválidos.",
        "raw_recebido" => $rawInput,
        "dados_parsed" => $dados
    ]);
    exit;
}

try {
    $sql = "UPDATE Jogo SET tempo_formatado = :tempo_formatado, periodo = :periodo WHERE id_jogo = :id_jogo";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':tempo_formatado' => $tempo_formatado,
        ':periodo'         => $periodo,
        ':id_jogo'         => $id_jogo
    ]);

    echo json_encode(["sucesso" => true]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao atualizar o tempo: " . $e->getMessage()]);
}
?>