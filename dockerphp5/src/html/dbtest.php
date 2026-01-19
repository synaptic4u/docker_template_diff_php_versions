<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$db = getenv('DB_NAME');

if (!$host || !$user || !$pass || !$db) {
    error_log('Database configuration missing');
    die("Database configuration error");
}

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    error_log('Database connection failed: ' . $conn->connect_error);
    die("Database connection failed");
}

echo "<h2>PHP 5 - Database List</h2>";
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
