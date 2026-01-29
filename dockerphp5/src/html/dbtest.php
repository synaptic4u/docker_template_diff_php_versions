<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$db = getenv('DB_NAME');

if (!$host || !$user || !$pass || !$db) {
    error_log('Database configuration missing');
    die("Database configuration error");
}

// SSL connection required
$conn = new mysqli();
$conn->ssl_set(
    getenv('DB_SSL_KEY'),
    getenv('DB_SSL_CERT'), 
    getenv('DB_SSL_CA'),
    null,
    null
);
$ssl_result = $conn->real_connect($host, $user, $pass, $db, 3306, null, MYSQLI_CLIENT_SSL);

if (!$ssl_result) {
    die("SSL connection required but failed: " . $conn->connect_error);
}

if ($conn->connect_error) {
    error_log('Database connection failed: ' . $conn->connect_error);
    die("Database connection failed: " . $conn->connect_error);
}

// Check if SSL is active
$ssl_status = $conn->query("SHOW STATUS LIKE 'Ssl_cipher'");
$ssl_active = false;
if ($ssl_status && $ssl_row = $ssl_status->fetch_assoc()) {
    if (!empty($ssl_row['Value'])) {
        echo "<p><strong>SSL Cipher:</strong> " . htmlspecialchars($ssl_row['Value']) . "</p>";
        $ssl_active = true;
    }
}

echo "<h2>PHP 5 - Database List" . ($ssl_active ? " (SSL Encrypted)" : "") . "</h2>";
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
