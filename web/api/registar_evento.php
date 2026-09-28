<?php
require_once '../ligacao.php';

header('Content-Type: application/json; charset=utf-8');

$input = json_decode(file_get_contents('php://input'), true);

$tipo_evento = $input['tipo_evento'] ?? $_POST['tipo_evento'] ?? null;
$id_jogo = $input['id_jogo'] ?? $_POST['id_jogo'] ?? null;
$id_jogador = $input['id_jogador'] ?? $_POST['id_jogador'] ?? null;
$id_equipa = $input['id_equipa'] ?? $_POST['id_equipa'] ?? null;

if (!$tipo_evento || !$id_jogo || !$id_equipa) {
    http_response_code(400);
    echo json_encode([
        "error" => "Campos obrigatórios em falta.",
        "recebido" => $input
    ]);
    exit;
}

try {
    $sql = "INSERT INTO Evento_Jogo (tipo_evento, id_jogo, id_jogador, id_equipa) VALUES (:tipo_evento, :id_jogo, :id_jogador, :id_equipa)";
    $stmt = $pdo->prepare($sql);

    $stmt->execute([
        ':tipo_evento' => $tipo_evento,
        ':id_jogo' => $id_jogo,
        ':id_jogador' => !empty($id_jogador) ? $id_jogador : null,
        ':id_equipa' => $id_equipa
    ]);

    echo json_encode([
        "successo" => true,
        "mensagem" => "Evento registado com sucesso!",
        "id_evento" => $pdo->lastInsertId()
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao registar o evento: " . $e->getMessage()]);
}
?>