CREATE DATABASE ecommerce_training;

CREATE TABLE customers
(
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    registration_date DATE NOT NULL
);

CREATE TABLE categories
(
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100),
    parent_id INT NULL,

    FOREIGN KEY(parent_id)
    REFERENCES categories(category_id)
);

CREATE TABLE products
(
    product_id INT AUTO_INCREMENT PRIMARY KEY,

    category_id INT,

    product_name VARCHAR(100),

    price DECIMAL(10,2),

    stock_quantity INT,

    FOREIGN KEY(category_id)
    REFERENCES categories(category_id)
);

CREATE TABLE orders
(
    order_id INT AUTO_INCREMENT PRIMARY KEY,

    customer_id INT,

    order_date DATE,

    FOREIGN KEY(customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE order_items
(
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,

    order_id INT,

    product_id INT,

    quantity INT,

    price DECIMAL(10,2),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),

    FOREIGN KEY(product_id)
    REFERENCES products(product_id)
);

CREATE TABLE payments
(
    payment_id INT AUTO_INCREMENT PRIMARY KEY,

    order_id INT,

    payment_date DATE,

    amount DECIMAL(10,2),

    status ENUM('paid','unpaid','pending'),

    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE RestockAlerts
(
    alert_id INT AUTO_INCREMENT PRIMARY KEY,

    product_name VARCHAR(100),

    current_stock INT,

    alert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE MonthlySalesAudit
(
    id INT AUTO_INCREMENT PRIMARY KEY,

    sales_month DATE,

    total_orders INT,

    revenue DECIMAL(12,2)
);

