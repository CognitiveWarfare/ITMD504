-- Create Database
CREATE DATABASE IF NOT EXISTS inventory_management;
USE inventory_management;

-- Create Categories Table (for better data management)
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert Default Categories
INSERT INTO categories (category_name, description) VALUES 
('Electronics', 'Electronic devices and components'),
('Clothing', 'Apparel and fashion items'),
('Office Supplies', 'Stationery and office equipment'),
('Furniture', 'Furniture and furnishing items'),
('Other', 'Miscellaneous items');

-- Create Inventory Items Table
CREATE TABLE inventory_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(255) NOT NULL,
    category_id INT,
    quantity INT NOT NULL DEFAULT 0,
    description TEXT,
    purchase_price DECIMAL(10, 2),
    selling_price DECIMAL(10, 2),
    low_stock_threshold INT DEFAULT 10,
    location VARCHAR(100),
    supplier VARCHAR(255),
    last_restocked DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- Create Index for Faster Searching
CREATE INDEX idx_item_name ON inventory_items(item_name);
CREATE INDEX idx_category ON inventory_items(category_id);

-- Create Inventory Tracking Table
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT,
    transaction_type ENUM('PURCHASE', 'SALE', 'ADJUSTMENT') NOT NULL,
    quantity INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id INT, -- Placeholder for future user tracking
    notes TEXT,

    FOREIGN KEY (item_id) REFERENCES inventory_items(item_id) ON DELETE CASCADE
);

-- Create Users Table (for future authentication)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'MANAGER', 'VIEWER') DEFAULT 'VIEWER',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stored Procedure for Adding New Inventory Item
DELIMITER //
CREATE PROCEDURE AddInventoryItem(
    IN p_item_name VARCHAR(255),
    IN p_category_name VARCHAR(100),
    IN p_quantity INT,
    IN p_description TEXT,
    IN p_purchase_price DECIMAL(10, 2),
    IN p_selling_price DECIMAL(10, 2)
)
BEGIN
    DECLARE category_id_var INT;

    -- Find or create category
    INSERT INTO categories (category_name) 
    VALUES (p_category_name) 
    ON DUPLICATE KEY UPDATE category_id = LAST_INSERT_ID(category_id);
    
    SET category_id_var = LAST_INSERT_ID();

    -- Insert new inventory item
    INSERT INTO inventory_items (
        item_name, 
        category_id, 
        quantity, 
        description, 
        purchase_price, 
        selling_price
    ) VALUES (
        p_item_name,
        category_id_var,
        p_quantity,
        p_description,
        p_purchase_price,
        p_selling_price
    );

    -- Log the initial inventory transaction
    INSERT INTO inventory_transactions (
        item_id, 
        transaction_type, 
        quantity, 
        notes
    ) VALUES (
        LAST_INSERT_ID(),
        'PURCHASE',
        p_quantity,
        'Initial stock addition'
    );
END //
DELIMITER ;

-- Stored Procedure for Searching Inventory
DELIMITER //
CREATE PROCEDURE SearchInventory(
    IN p_search_term VARCHAR(255),
    IN p_search_type ENUM('NAME', 'CATEGORY', 'ID')
)
BEGIN
    IF p_search_type = 'NAME' THEN
        SELECT 
            i.item_id, 
            i.item_name, 
            c.category_name, 
            i.quantity,
            i.description,
            i.selling_price
        FROM inventory_items i
        LEFT JOIN categories c ON i.category_id = c.category_id
        WHERE i.item_name LIKE CONCAT('%', p_search_term, '%');
    
    ELSEIF p_search_type = 'CATEGORY' THEN
        SELECT 
            i.item_id, 
            i.item_name, 
            c.category_name, 
            i.quantity,
            i.description,
            i.selling_price
        FROM inventory_items i
        LEFT JOIN categories c ON i.category_id = c.category_id
        WHERE c.category_name LIKE CONCAT('%', p_search_term, '%');
    
    ELSEIF p_search_type = 'ID' THEN
        SELECT 
            i.item_id, 
            i.item_name, 
            c.category_name, 
            i.quantity,
            i.description,
            i.selling_price
        FROM inventory_items i
        LEFT JOIN categories c ON i.category_id = c.category_id
        WHERE i.item_id = CAST(p_search_term AS UNSIGNED);
    END IF;
END //
DELIMITER ;

-- Example Data Insertion
CALL AddInventoryItem('Laptop', 'Electronics', 50, 'High-performance business laptop', 799.99, 1099.99);
CALL AddInventoryItem('Office Chair', 'Furniture', 25, 'Ergonomic desk chair', 199.99, 349.99);
CALL AddInventoryItem('Printer', 'Electronics', 15, 'Wireless color printer', 129.99, 249.99);

-- Permissions (example for a read-only user)
CREATE USER 'inventory_reader'@'localhost' IDENTIFIED BY 'read_password';
GRANT SELECT ON inventory_management.* TO 'inventory_reader'@'localhost';

-- Permissions for full access
CREATE USER 'inventory_manager'@'localhost' IDENTIFIED BY 'manager_password';
GRANT ALL PRIVILEGES ON inventory_management.* TO 'inventory_manager'@'localhost';
