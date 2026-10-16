<?php
require_once '../ligacao.php';

header('Content-Type: application/json; charset=utf-8');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");



try {
    $smt = $pdo->query("select id_equipa, nome from Equipa");
    $equipas = $smt->fetchAll();

    echo json_encode($equipas);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Erro ao listar as equipas: " . $e->getMessage()]);
}
?>

