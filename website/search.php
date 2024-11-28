<?php
// Database connection details
require_once 'config.php';  // Move credentials to a separate config file

// Create connection
$conn = new mysqli($host, $user, $pass, $db);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['error' => "Connection failed: " . $conn->connect_error]));
}

try {
    // Prepare SQL query to get all items from the inventory_items table
    $sql = "SELECT i.item_id, i.item_name, c.category_name, i.quantity
            FROM inventory_items i
            LEFT JOIN categories c ON i.category_id = c.category_id";

    // Prepare the statement
    $stmt = $conn->prepare($sql);
    $stmt->execute();

    // Get the result
    $result = $stmt->get_result();

    // Format results as HTML table
    $output = "<div class='results-table-container'>";
    $output .= "<table class='results-table'>";
    $output .= "<thead><tr><th>Item Name</th><th>Category</th><th>Quantity</th></tr></thead><tbody>";

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $output .= "<tr>";
            $output .= "<td>" . htmlspecialchars($row['item_name']) . "</td>";
            $output .= "<td>" . htmlspecialchars($row['category_name']) . "</td>";
            $output .= "<td>" . htmlspecialchars($row['quantity']) . "</td>";
            $output .= "</tr>";
        }
    } else {
        $output .= "<tr><td colspan='3'>No results found</td></tr>";
    }

    $output .= "</tbody></table>";
    $output .= "</div>";  // Close the container div
    echo $output;

} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
} finally {
    // Close statement and connection
    $stmt->close();
    $conn->close();
}
?>

