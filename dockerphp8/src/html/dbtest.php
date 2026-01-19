<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$db = getenv('DB_NAME');

if (!$host || !$user || !$pass || !$db) {
    error_log('Database configuration missing');
    die("Database configuration error");
}

// Add retry logic since MySQL may need time to start
$conn = null;
$attempts = 0;
$max_attempts = 10;

while ($attempts < $max_attempts && !$conn) {
    $conn = @new mysqli($host, $user, $pass, $db);
    
    if ($conn->connect_error) {
        $attempts++;
        if ($attempts < $max_attempts) {
            sleep(2);
        }
    } else {
        break;
    }
}

if (!$conn || $conn->connect_error) {
    error_log('Database connection failed after retries: ' . ($conn ? $conn->connect_error : "Unable to create connection"));
    die("Database connection failed");
}


echo "<h2>PHP 8 - Database List</h2>";

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
