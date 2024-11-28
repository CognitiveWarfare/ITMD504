<?php
// Database connection details
require_once 'config.php';

// Create connection
$conn = new mysqli($host, $user, $pass, $db);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['error' => "Connection failed: " . $conn->connect_error]));
}

try {
    // Get and validate form data
    $item_name = trim($_POST['item_name'] ?? '');
    $category = trim($_POST['category'] ?? '');
    $quantity = intval($_POST['quantity'] ?? 0);
    $description = trim($_POST['description'] ?? '');

    // Validate input
    if (empty($item_name)) {
        throw new Exception('Item name is required');
    }
    if (empty($category)) {
        throw new Exception('Category is required');
    }
    if ($quantity < 0) {
        throw new Exception('Quantity must be 0 or greater');
    }

    // Get the category_id from the categories table
    $category_sql = "SELECT category_id FROM categories WHERE category_name = ?";
    $stmt = $conn->prepare($category_sql);
    $stmt->bind_param("s", $category);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows == 0) {
        throw new Exception("Invalid category selected");
    }

    $stmt->bind_result($category_id);
    $stmt->fetch();
    $stmt->close();

    // Prepare SQL statement for inserting the inventory item
    $sql = "INSERT INTO inventory_items (item_name, category_id, quantity, description) VALUES (?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ssis", $item_name, $category_id, $quantity, $description);

    // Execute and check result
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Item added successfully!',
            'id' => $conn->insert_id
        ]);
    } else {
        throw new Exception("Error adding item: " . $stmt->error);
    }

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
} finally {
    $stmt->close();
    $conn->close();
}
?>

