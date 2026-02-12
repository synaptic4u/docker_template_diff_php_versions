<?php
// Example SSL MySQL connection for PHP 8
$host = $_ENV['DB_HOST'];
$username = $_ENV['DB_USER'];
$password = $_ENV['DB_PASSWORD'];
$database = $_ENV['DB_NAME'];
$ssl_ca = $_ENV['DB_SSL_CA'];
$ssl_cert = $_ENV['DB_SSL_CERT'];
$ssl_key = $_ENV['DB_SSL_KEY'];

// Using PDO with SSL
$dsn = "mysql:host={$host};dbname={$database};charset=utf8mb4";
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::MYSQL_ATTR_SSL_CA => $ssl_ca,
    PDO::MYSQL_ATTR_SSL_CERT => $ssl_cert,
    PDO::MYSQL_ATTR_SSL_KEY => $ssl_key,
    PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);
    echo "Connected successfully with SSL encryption\n";
    
    // Verify SSL connection
    $stmt = $pdo->query("SHOW STATUS LIKE 'Ssl_cipher'");
    $result = $stmt->fetch();
    if ($result) {
        echo "SSL Cipher: " . $result['Value'] . "\n";
    }
} catch (PDOException $e) {
    die('Connection failed: ' . $e->getMessage());
}
?>