<?php
$host = 'synaptic_db_webPHP7';
$user = 'synaptic_db_webPHP7';
$pass = 'synaptic_db_webPHP7';

$conn = new mysqli($host, $user, $pass);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "<h2>PHP 7 - Database List</h2>";
$result = $conn->query("SHOW DATABASES");

echo "<ul>";
while ($row = $result->fetch_assoc()) {
    echo "<li>" . $row['Database'] . "</li>";
}
echo "</ul>";

$conn->close();
?>
