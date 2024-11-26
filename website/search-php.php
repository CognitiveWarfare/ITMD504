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
    // Get search parameters
    $search_term = $_GET['search_term'] ?? '';
    $search_type = $_GET['search_type'] ?? 'name';

    // Validate search type
    $valid_search_types = ['name', 'category', 'id'];
    if (!in_array($search_type, $valid_search_types)) {
        throw new Exception('Invalid search type');
    }

    // Prepare SQL statement based on search type
    switch ($search_type) {
        case 'id':
            $sql = "SELECT * FROM inventory WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $search_term);
            break;
        case 'category':
            $sql = "SELECT * FROM inventory WHERE category LIKE ?";
            $stmt = $conn->prepare($sql);
            $search_param = "%$search_term%";
            $stmt->bind_param("s", $search_param);
            break;
        default:  // name
            $sql = "SELECT * FROM inventory WHERE item_name LIKE ?";
            $stmt = $conn->prepare($sql);
            $search_param = "%$search_term%";
            $stmt->bind_param("s", $search_param);
    }

    // Execute query
    $stmt->execute();
    $result = $stmt->get_result();

    // Format results as HTML table
    $output = "<table class='results-table'>";
    $output .= "<thead><tr><th>Item ID</th><th>Item Name</th><th>Category</th><th>Quantity</th><th>Actions</th></tr></thead><tbody>";
    
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $output .= "<tr>";
            $output .= "<td>" . htmlspecialchars($row['id']) . "</td>";
            $output .= "<td>" . htmlspecialchars($row['item_name']) . "</td>";
            $output .= "<td>" . htmlspecialchars($row['category']) . "</td>";
            $output .= "<td>" . htmlspecialchars($row['quantity']) . "</td>";
            $output .= "<td><button onclick='editItem(" . $row['id'] . ")'>Edit</button></td>";
            $output .= "</tr>";
        }
    } else {
        $output .= "<tr><td colspan='5'>No results found</td></tr>";
    }
    
    $output .= "</tbody></table>";
    echo $output;

} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
} finally {
    $stmt->close();
    $conn->close();
}
?>
