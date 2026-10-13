<?php
require_once '../ligacao.php';

header('Access-Control-Allow-Origin: http://localhost:50249'); 
header('Access-Control-Allow-Methods: GET, POST, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    $sql = "SELECT 
                j.id_jogo, 
                j.estado, 
                ec.id_equipa As id_equipa_casa, 
                ec.nome AS nome_equipa_casa,
                ef.id_equipa As id_equipa_fora,
                ef.nome AS nome_equipa_fora
            FROM Jogo j
            JOIN Equipa ec ON j.id_equipa_casa = ec.id_equipa
            JOIN Equipa ef ON j.id_equipa_fora = ef.id_equipa";
    $smt = $pdo->query($sql);
    $jogos = $smt->fetchAll();

    echo json_encode($jogos);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao listar os jogos: " . $e->getMessage()]);
}
?>

