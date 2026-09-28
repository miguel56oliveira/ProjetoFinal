<?php
require_once '../ligacao.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $sql = "SELECT 
                j.id_jogo, 
                j.estado, 
                ec.nome AS id_equipa_casa, 
                ef.nome AS id_equipa_fora
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

