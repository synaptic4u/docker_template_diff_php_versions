<?php
$host = getenv('DB_HOST') ?: 'synaptic_db_webPHP7';
$user = getenv('DB_USER') ?: 'synaptic_db_webPHP7';
$pass = getenv('DB_PASSWORD') ?: 'synaptic_db_webPHP7';

$conn = new mysqli($host, $user, $pass);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "<h2>PHP 7 - Database List</h2>";
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
