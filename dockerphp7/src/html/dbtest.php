<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$db = getenv('DB_NAME');

if (!$host || !$user || !$pass || !$db) {
    error_log('Database configuration missing');
    die("Database configuration error");
}

$conn = new mysqli();
$conn->ssl_set(
    getenv('DB_SSL_KEY'),
    getenv('DB_SSL_CERT'), 
    getenv('DB_SSL_CA'),
    null,
    null
);
$conn->real_connect($host, $user, $pass, $db, 3306, null, MYSQLI_CLIENT_SSL);

if ($conn->connect_error) {
    error_log('Database SSL connection failed: ' . $conn->connect_error);
    die("Database SSL connection failed");
}

// Verify SSL connection
$ssl_status = $conn->query("SHOW STATUS LIKE 'Ssl_cipher'");
if ($ssl_status && $ssl_row = $ssl_status->fetch_assoc()) {
    echo "<p><strong>SSL Cipher:</strong> " . htmlspecialchars($ssl_row['Value']) . "</p>";
}

echo "<h2>PHP 7 - Database List (SSL Encrypted)</h2>";
$result = $conn->query("SHOW DATABASES");

if ($result) {
    echo "<h3>Available Databases:</h3>";
    echo "<ul>";
    while ($row = $result->fetch_assoc()) {
        echo "<li>" . htmlspecialchars($row['Database']) . "</li>";
    }
    echo "</ul>";
} else {
    echo "<p>Error: " . htmlspecialchars($conn->error) . "</p>";
}

$conn->close();
?>
