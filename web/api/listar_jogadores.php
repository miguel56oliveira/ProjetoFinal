<?php

require_once '../ligacao.php';

header('Access-Control-Allow-Origin: http://localhost:50249'); 
header('Access-Control-Allow-Methods: GET, POST, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type'); 
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    $sql = "SELECT id_jogador, nome, numero_camisola, id_equipa 
            FROM Jogador
            ORDER BY id_equipa, numero_camisola";
            
    $smt = $pdo->query($sql);

    echo json_encode($smt->fetchAll(PDO::FETCH_ASSOC));

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao listar os jogadores."]);
}
?>

