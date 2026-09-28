<?php
require_once '../ligacao.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $smt = $pdo->query("select id_equipa, nome from Equipa");
    $equipas = $smt->fetchAll();

    echo json_encode($equipas);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao listar as equipas: " . $e->getMessage()]);
}
?>

