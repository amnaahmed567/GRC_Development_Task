INSERT INTO customers
(name,email,registration_date)
VALUES

('Ali','ali@test.com','2025-01-01'),
('Ahmed','ahmed@test.com','2025-02-10'),
('Sara','sara@test.com','2025-03-15'),
('John','john@test.com','2025-04-01');

INSERT INTO categories(category_name,parent_id)
VALUES

('Electronics',NULL),
('Mobiles',1),
('Smartphones',2),
('Computers',1);

INSERT INTO products
(category_id,product_name,price,stock_quantity)

VALUES

(3,'iPhone 15',300000,5),
(3,'Samsung S24',250000,20),
(4,'Laptop Dell',180000,7),
(4,'HP Laptop',150000,15);

INSERT INTO orders
(customer_id,order_date)

VALUES

(1,'2025-05-01'),
(1,'2025-06-01'),
(2,'2025-06-05'),
(3,'2025-07-01');

INSERT INTO order_items
(order_id,product_id,quantity,price)

VALUES

(1,1,1,300000),
(1,2,2,500000),

(2,3,1,180000),

(3,4,1,150000),

(4,2,3,750000);

INSERT INTO payments
(order_id,payment_date,amount,status)

VALUES

(1,'2025-05-02',800000,'paid'),

(2,NULL,180000,'unpaid'),

(3,'2025-06-06',150000,'paid'),

(4,NULL,750000,'pending');