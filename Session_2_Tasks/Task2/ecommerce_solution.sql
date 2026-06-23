
/* ============================================================================
   SECTION 3 - PART 1: JOINS, AGGREGATION & FILTERING (Tasks 1-7)
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- Task 1: All customers with total orders + total spent (incl. non-buyers)
-- FIX: COUNT(DISTINCT o.order_id). Because we also join order_items, an order
--      with 2 line items would otherwise be counted twice.
-- ---------------------------------------------------------------------------
SELECT  c.customer_id,
        c.name,
        COUNT(DISTINCT o.order_id)                   AS total_orders,
        COALESCE(SUM(oi.quantity * oi.price), 0)     AS total_spent
FROM        customers   c
LEFT JOIN   orders      o  ON c.customer_id = o.customer_id
LEFT JOIN   order_items oi ON o.order_id    = oi.order_id
GROUP BY    c.customer_id, c.name
ORDER BY    total_spent DESC;


-- ---------------------------------------------------------------------------
-- Task 2: Customers with > 3 orders AND at least one unpaid order
-- ---------------------------------------------------------------------------
SELECT  c.name,
        COUNT(DISTINCT o.order_id)                                AS total_orders,
        SUM(CASE WHEN p.status = 'unpaid' THEN 1 ELSE 0 END)      AS unpaid_orders
FROM        customers c
INNER JOIN  orders    o ON c.customer_id = o.customer_id
INNER JOIN  payments  p ON o.order_id    = p.order_id
GROUP BY    c.customer_id, c.name
HAVING      total_orders > 3
       AND  unpaid_orders > 0;


-- ---------------------------------------------------------------------------
-- Task 3: Per product -> distinct customers, units sold, revenue (desc)
-- ---------------------------------------------------------------------------
SELECT  p.product_name,
        COUNT(DISTINCT o.customer_id)        AS distinct_customers,
        SUM(oi.quantity)                     AS units_sold,
        SUM(oi.quantity * oi.price)          AS revenue
FROM        products    p
INNER JOIN  order_items oi ON p.product_id = oi.product_id
INNER JOIN  orders      o  ON o.order_id    = oi.order_id
GROUP BY    p.product_id, p.product_name
ORDER BY    revenue DESC;


-- ---------------------------------------------------------------------------
-- Task 4: Each order with payment status + days from order to payment
-- (NULL if not yet paid). DATEDIFF(later, earlier) in MySQL = number of days.
-- ---------------------------------------------------------------------------
SELECT  o.order_id,
        o.order_date,
        p.status                                          AS payment_status,
        CASE WHEN p.payment_date IS NULL THEN NULL
             ELSE DATEDIFF(p.payment_date, o.order_date)
        END                                               AS payment_days
FROM        orders   o
LEFT JOIN   payments p ON o.order_id = p.order_id
ORDER BY    o.order_id;


-- ---------------------------------------------------------------------------
-- Task 5: Top 3 best-selling products per category (by units)
-- ROW_NUMBER gives exactly 3 per category (use RANK instead if you want ties).
-- ---------------------------------------------------------------------------
WITH product_rank AS (
    SELECT  c.category_id,
            c.category_name,
            p.product_name,
            SUM(oi.quantity) AS total_units,
            ROW_NUMBER() OVER (PARTITION BY c.category_id
                               ORDER BY SUM(oi.quantity) DESC) AS ranking
    FROM        products    p
    INNER JOIN  categories  c  ON p.category_id = c.category_id
    INNER JOIN  order_items oi ON p.product_id  = oi.product_id
    GROUP BY    c.category_id, c.category_name, p.product_id, p.product_name
)
SELECT  category_name, product_name, total_units, ranking
FROM    product_rank
WHERE   ranking <= 3
ORDER BY category_name, ranking;


-- ---------------------------------------------------------------------------
-- Task 6: Label each customer vs the average customer spend
-- The CTE is referenced 3 times; the subqueries recompute the overall average.
-- (Exact 'Average' equality rarely matches on decimals - that's expected.)
-- ---------------------------------------------------------------------------
WITH customer_total AS (
    SELECT  c.customer_id,
            c.name,
            COALESCE(SUM(oi.quantity * oi.price), 0) AS total_spent
    FROM        customers   c
    LEFT JOIN   orders      o  ON c.customer_id = o.customer_id
    LEFT JOIN   order_items oi ON o.order_id    = oi.order_id
    GROUP BY    c.customer_id, c.name
)
SELECT  name,
        total_spent,
        CASE
            WHEN total_spent >  (SELECT AVG(total_spent) FROM customer_total) THEN 'Above Average'
            WHEN total_spent =  (SELECT AVG(total_spent) FROM customer_total) THEN 'Average'
            ELSE 'Below Average'
        END AS spending_band
FROM    customer_total
ORDER BY total_spent DESC;


-- ---------------------------------------------------------------------------
-- Task 7: Monthly revenue for the last 12 months + running cumulative total
-- FIX 1: %Y (4-digit year) instead of %y, so months sort correctly.
-- FIX 2: WHERE filter so it really is the *last 12 months*.
-- SUM() OVER (ORDER BY ...) keeps every row and accumulates -> running total.
-- ---------------------------------------------------------------------------
WITH monthly_sales AS (
    SELECT  DATE_FORMAT(o.order_date, '%Y-%m')   AS sales_month,
            SUM(oi.quantity * oi.price)          AS revenue
    FROM        orders      o
    INNER JOIN  order_items oi ON o.order_id = oi.order_id
    WHERE   o.order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY    sales_month
)
SELECT  sales_month,
        revenue,
        SUM(revenue) OVER (ORDER BY sales_month) AS cumulative_total
FROM    monthly_sales
ORDER BY sales_month;


/* ============================================================================
   SECTION 4 - PART 2: CTEs, VIEWS & INDEXES (Tasks 8-11)
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- Task 8: Customers whose first order was within 7 days of registering
-- (BETWEEN 0 AND 7 also guards against any first order before registration.)
-- ---------------------------------------------------------------------------
WITH first_order AS (
    SELECT  c.customer_id,
            c.name,
            c.registration_date,
            MIN(o.order_date) AS first_order_date
    FROM        customers c
    INNER JOIN  orders    o ON c.customer_id = o.customer_id
    GROUP BY    c.customer_id, c.name, c.registration_date
)
SELECT  name,
        registration_date,
        first_order_date,
        DATEDIFF(first_order_date, registration_date) AS gap_days
FROM    first_order
WHERE   DATEDIFF(first_order_date, registration_date) BETWEEN 0 AND 7
ORDER BY gap_days;


-- ---------------------------------------------------------------------------
-- Task 9: Recursive CTE -> full category path  (e.g. Electronics > Mobiles > Smartphones)
-- FIX: CAST the anchor's full_path to CHAR(500). A recursive column takes its
--      data type from the anchor row; without the cast the growing path string
--      can be truncated (a classic MySQL recursive-CTE gotcha).
-- ---------------------------------------------------------------------------
WITH RECURSIVE category_tree AS (
    -- anchor member: top-level categories (no parent)
    SELECT  category_id,
            category_name,
            parent_id,
            CAST(category_name AS CHAR(500)) AS full_path
    FROM    categories
    WHERE   parent_id IS NULL

    UNION ALL

    -- recursive member: attach each child onto its parent's path
    SELECT  c.category_id,
            c.category_name,
            c.parent_id,
            CONCAT(ct.full_path, ' > ', c.category_name)
    FROM        categories    c
    INNER JOIN  category_tree ct ON c.parent_id = ct.category_id
)
SELECT  category_id, category_name, full_path
FROM    category_tree
ORDER BY full_path;


-- ---------------------------------------------------------------------------
-- Task 10: View of customer order summary, then top 10 by spending
-- FIX: COUNT(DISTINCT o.order_id) again (same double-count trap as Task 1).
-- ---------------------------------------------------------------------------
CREATE VIEW vw_customer_order_summary AS
SELECT  c.customer_id,
        c.name,
        COUNT(DISTINCT o.order_id)                AS total_orders,
        COALESCE(SUM(oi.quantity * oi.price), 0)  AS total_spent,
        MAX(o.order_date)                         AS latest_order
FROM        customers   c
LEFT JOIN   orders      o  ON c.customer_id = o.customer_id
LEFT JOIN   order_items oi ON o.order_id    = oi.order_id
GROUP BY    c.customer_id, c.name;

-- Query the view (MySQL uses LIMIT, not TOP)
SELECT *
FROM   vw_customer_order_summary
ORDER BY total_spent DESC
LIMIT 10;


-- ---------------------------------------------------------------------------
-- Task 11: Index to speed up the Task 3 revenue report + plan comparison
-- Run the EXPLAIN BEFORE, then create the index, then EXPLAIN AGAIN and compare.
-- (On a tiny sample table the optimiser may still scan; on large data the
--  full scan becomes an index lookup. Use EXPLAIN ANALYZE to also see timings.)
-- ---------------------------------------------------------------------------

-- (a) BEFORE the index:
EXPLAIN
SELECT  p.product_name, SUM(oi.quantity * oi.price) AS revenue
FROM        products    p
INNER JOIN  order_items oi ON p.product_id = oi.product_id
GROUP BY    p.product_id, p.product_name;

-- (b) Create the index. The plain one speeds up the join;
--     the second (commented) is a *covering* index for this exact query.
CREATE INDEX idx_order_items_product ON order_items(product_id);
-- CREATE INDEX idx_order_items_cover ON order_items(product_id, quantity, price);

-- (c) AFTER the index (compare the 'type' / 'key' / 'rows' columns to step a):
EXPLAIN
SELECT  p.product_name, SUM(oi.quantity * oi.price) AS revenue
FROM        products    p
INNER JOIN  order_items oi ON p.product_id = oi.product_id
GROUP BY    p.product_id, p.product_name;


/* ============================================================================
   SECTION 5 - PART 3: FUNCTIONS, PROCEDURES & CURSORS (Tasks 12-18)
   ============================================================================ */

-- ---------------------------------------------------------------------------
-- Task 12: Scalar function -> a customer's lifetime value (PAID orders only)
-- FIX: READS SQL DATA instead of DETERMINISTIC. A function that reads tables is
--      NOT deterministic; READS SQL DATA is the correct characteristic and also
--      satisfies binary-logging restrictions on function creation.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE FUNCTION fn_customer_lifetime_value(p_customer_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT COALESCE(SUM(oi.quantity * oi.price), 0)
    INTO   v_total
    FROM        orders      o
    INNER JOIN  order_items oi ON o.order_id = oi.order_id
    INNER JOIN  payments    p  ON o.order_id = p.order_id
    WHERE   o.customer_id = p_customer_id
      AND   p.status = 'paid';

    RETURN v_total;   -- COALESCE guarantees 0 (never NULL) for customers with no paid orders
END $$
DELIMITER ;

-- Test (edge case = customer with no paid orders returns 0):
SELECT fn_customer_lifetime_value(1) AS alice_ltv,
       fn_customer_lifetime_value(6) AS frank_ltv;


-- ---------------------------------------------------------------------------
-- Task 13: Scalar function -> discounted order total
--   >10000 -> 10% off,  >5000 -> 5% off,  else 0%
-- FIX: READS SQL DATA; COALESCE so an empty/invalid order returns 0 not NULL.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE FUNCTION fn_order_discount(p_order_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT COALESCE(SUM(quantity * price), 0)
    INTO   v_total
    FROM   order_items
    WHERE  order_id = p_order_id;

    IF v_total > 10000 THEN
        SET v_total = v_total * 0.90;
    ELSEIF v_total > 5000 THEN
        SET v_total = v_total * 0.95;
    END IF;

    RETURN v_total;
END $$
DELIMITER ;

-- Test all three tiers: order 2 = 13500 (10%), order 3 = 5694.30 (5%), order 1 = 1920 (0%)
SELECT fn_order_discount(2) AS tier_10pct,
       fn_order_discount(3) AS tier_5pct,
       fn_order_discount(1) AS tier_0pct;


-- ---------------------------------------------------------------------------
-- Task 14: "Orders in a date range" with customer, item count and total.
-- NOTE: MySQL has NO table-valued functions and NO CROSS APPLY, so the inline
--       TVF is implemented as a stored procedure (the standard MySQL substitute).
--       A LATERAL-based equivalent of CROSS APPLY is shown afterwards.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_orders_by_date_range(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT  o.order_id,
            c.name                       AS customer_name,
            SUM(oi.quantity)             AS total_items,
            SUM(oi.quantity * oi.price)  AS order_total
    FROM        orders      o
    INNER JOIN  customers   c  ON o.customer_id = c.customer_id
    INNER JOIN  order_items oi ON o.order_id    = oi.order_id
    WHERE   o.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY    o.order_id, c.name
    ORDER BY    o.order_id;
END $$
DELIMITER ;

CALL sp_orders_by_date_range(DATE_SUB(CURDATE(), INTERVAL 12 MONTH), CURDATE());

-- MySQL equivalent of CROSS APPLY "monthly snapshot": LATERAL derived table.
-- For every order, the LATERAL block is evaluated using that order's columns.
SELECT  o.order_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        agg.total_items,
        agg.order_total
FROM    orders o
JOIN LATERAL (
        SELECT SUM(oi.quantity)            AS total_items,
               SUM(oi.quantity * oi.price) AS order_total
        FROM   order_items oi
        WHERE  oi.order_id = o.order_id
) AS agg ON TRUE
ORDER BY order_month, o.order_id;


-- ---------------------------------------------------------------------------
-- Task 15: sp_place_order  -  full order workflow in ONE transaction
-- FIX (important): the original would NOT roll back on a bad product id, because
--   "INSERT ... SELECT ... WHERE product_id = pid" simply inserts 0 rows (no error).
--   Here we validate first and SIGNAL an error, which the handler catches and
--   rolls back - so passing an invalid product id correctly undoes everything.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_place_order(
    IN p_customer_id INT,
    IN p_product_id  INT,
    IN p_quantity    INT
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_price    DECIMAL(12,2);
    DECLARE v_stock    INT;

    -- Any SQL error (including the SIGNALs below) -> roll back the whole order
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Order failed - transaction rolled back' AS message;
    END;

    START TRANSACTION;

    -- Validate the product (this is what makes the rollback test work)
    SELECT price, stock_quantity
    INTO   v_price, v_stock
    FROM   products
    WHERE  product_id = p_product_id;

    IF v_price IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product id';
    END IF;

    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    -- 1) create the order
    INSERT INTO orders (customer_id, order_date)
    VALUES (p_customer_id, CURDATE());
    SET v_order_id = LAST_INSERT_ID();

    -- 2) insert the order item (price captured from the product)
    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (v_order_id, p_product_id, p_quantity, v_price);

    -- 3) deduct stock
    UPDATE products
    SET    stock_quantity = stock_quantity - p_quantity
    WHERE  product_id = p_product_id;

    -- 4) record a pending payment
    INSERT INTO payments (order_id, status)
    VALUES (v_order_id, 'pending');

    COMMIT;
    SELECT 'Order created successfully' AS message, v_order_id AS order_id;
END $$
DELIMITER ;

-- Success case:
CALL sp_place_order(1, 2, 3);
-- Failure case (invalid product id 999) -> everything rolls back:
CALL sp_place_order(1, 999, 1);


-- ---------------------------------------------------------------------------
-- BONUS for Task 15: real "list of products" version using a JSON parameter.
-- The task asked for a LIST of product ids + quantities; MySQL has no arrays,
-- so we pass JSON and loop. Requires MySQL 8.0.4+.
-- Example: '[{"product_id":1,"qty":2},{"product_id":3,"qty":1}]'
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_place_order_multi(
    IN p_customer_id INT,
    IN p_items       JSON
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_idx      INT DEFAULT 0;
    DECLARE v_count    INT;
    DECLARE v_pid      INT;
    DECLARE v_qty      INT;
    DECLARE v_price    DECIMAL(12,2);
    DECLARE v_stock    INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Order failed - transaction rolled back' AS message;
    END;

    START TRANSACTION;

    INSERT INTO orders (customer_id, order_date) VALUES (p_customer_id, CURDATE());
    SET v_order_id = LAST_INSERT_ID();

    SET v_count = JSON_LENGTH(p_items);

    WHILE v_idx < v_count DO
        SET v_pid = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_idx, '].product_id')));
        SET v_qty = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_idx, '].qty')));

        SELECT price, stock_quantity INTO v_price, v_stock
        FROM   products WHERE product_id = v_pid;

        IF v_price IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid product id';
        END IF;
        IF v_stock < v_qty THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
        END IF;

        INSERT INTO order_items (order_id, product_id, quantity, price)
        VALUES (v_order_id, v_pid, v_qty, v_price);

        UPDATE products SET stock_quantity = stock_quantity - v_qty
        WHERE  product_id = v_pid;

        SET v_idx = v_idx + 1;
    END WHILE;

    INSERT INTO payments (order_id, status) VALUES (v_order_id, 'pending');

    COMMIT;
    SELECT 'Order created successfully' AS message, v_order_id AS order_id;
END $$
DELIMITER ;

CALL sp_place_order_multi(1, '[{"product_id":1,"qty":1},{"product_id":3,"qty":2}]');


-- ---------------------------------------------------------------------------
-- Task 16: sp_monthly_sales_report
--   OUT params: total orders + total revenue
--   Result set 1: top 5 products by units
--   Result set 2: top 3 customers by spending
-- FIX: COALESCE on revenue so a month with no sales returns 0 instead of NULL.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_monthly_sales_report(
    IN  p_year         INT,
    IN  p_month        INT,
    OUT p_total_orders  INT,
    OUT p_total_revenue DECIMAL(12,2)
)
BEGIN
    -- Totals into the OUT parameters
    SELECT  COUNT(DISTINCT o.order_id),
            COALESCE(SUM(oi.quantity * oi.price), 0)
    INTO    p_total_orders, p_total_revenue
    FROM        orders      o
    INNER JOIN  order_items oi ON o.order_id = oi.order_id
    WHERE   YEAR(o.order_date)  = p_year
      AND   MONTH(o.order_date) = p_month;

    -- Result set 1: top 5 products by units sold
    SELECT  p.product_name,
            SUM(oi.quantity) AS units_sold
    FROM        products    p
    INNER JOIN  order_items oi ON p.product_id = oi.product_id
    INNER JOIN  orders      o  ON oi.order_id  = o.order_id
    WHERE   YEAR(o.order_date)  = p_year
      AND   MONTH(o.order_date) = p_month
    GROUP BY    p.product_id, p.product_name
    ORDER BY    units_sold DESC
    LIMIT 5;

    -- Result set 2: top 3 customers by spending
    SELECT  c.name,
            SUM(oi.quantity * oi.price) AS spending
    FROM        customers   c
    INNER JOIN  orders      o  ON c.customer_id = o.customer_id
    INNER JOIN  order_items oi ON o.order_id    = oi.order_id
    WHERE   YEAR(o.order_date)  = p_year
      AND   MONTH(o.order_date) = p_month
    GROUP BY    c.customer_id, c.name
    ORDER BY    spending DESC
    LIMIT 3;
END $$
DELIMITER ;

-- Test (use a month that has data, e.g. last month):
CALL sp_monthly_sales_report(YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
                             MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)),
                             @orders, @revenue);
SELECT @orders AS total_orders, @revenue AS total_revenue;


-- ---------------------------------------------------------------------------
-- Task 17: Cursor -> insert a restock alert for every product with stock < 10
-- Declaration order is mandatory in MySQL: variables, then cursor, then handler.
-- alert_timestamp is filled automatically by its DEFAULT CURRENT_TIMESTAMP.
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_restock_alerts()
BEGIN
    DECLARE v_done  INT DEFAULT 0;
    DECLARE v_name  VARCHAR(100);
    DECLARE v_stock INT;

    DECLARE cur CURSOR FOR
        SELECT product_name, stock_quantity
        FROM   products
        WHERE  stock_quantity < 10;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_name, v_stock;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        INSERT INTO RestockAlerts (product_name, current_stock)
        VALUES (v_name, v_stock);
    END LOOP;
    CLOSE cur;
END $$
DELIMITER ;

CALL sp_restock_alerts();
SELECT * FROM RestockAlerts;


-- ---------------------------------------------------------------------------
-- Task 18: Cursor over the last 12 months, calling sp_monthly_sales_report for
--          each one, archiving the totals into MonthlySalesAudit.
-- The months are generated by a recursive CTE (n = 0..11) used as the cursor
-- source. We DELETE first so re-running keeps the archive at exactly 12 rows.
--
-- Heads-up: because sp_monthly_sales_report also SELECTs its top-5/top-3 lists,
-- calling it 12 times here also emits those result sets - that is expected.
-- (If you only want the 12 archive rows and no extra output, replace the CALL
--  with the same COUNT/SUM query inlined - see the commented note below.)
-- ---------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_monthly_audit()
BEGIN
    DECLARE v_done    INT DEFAULT 0;
    DECLARE v_year    INT;
    DECLARE v_month   INT;
    DECLARE v_orders  INT;
    DECLARE v_revenue DECIMAL(12,2);

    DECLARE month_cursor CURSOR FOR
        WITH RECURSIVE month_seq (n) AS (
            SELECT 0
            UNION ALL
            SELECT n + 1 FROM month_seq WHERE n < 11
        )
        SELECT  YEAR(DATE_SUB(CURDATE(),  INTERVAL n MONTH)) AS yr,
                MONTH(DATE_SUB(CURDATE(), INTERVAL n MONTH)) AS mo
        FROM    month_seq;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DELETE FROM MonthlySalesAudit;   -- clear previous run -> guarantees 12 rows

    OPEN month_cursor;
    month_loop: LOOP
        FETCH month_cursor INTO v_year, v_month;
        IF v_done = 1 THEN
            LEAVE month_loop;
        END IF;

        -- call the Task 16 procedure to get this month's totals via OUT params
        CALL sp_monthly_sales_report(v_year, v_month, v_orders, v_revenue);

        INSERT INTO MonthlySalesAudit (sales_month, total_orders, revenue)
        VALUES (CONCAT(v_year, '-', LPAD(v_month, 2, '0')),
                COALESCE(v_orders, 0),
                COALESCE(v_revenue, 0));
    END LOOP;
    CLOSE month_cursor;
END $$
DELIMITER ;

CALL sp_monthly_audit();

-- The archive should now hold 12 rows. Find the highest-revenue month:
SELECT *
FROM   MonthlySalesAudit
ORDER BY revenue DESC
LIMIT 1;

-- Confirm 12 rows exist (submission checklist):
SELECT COUNT(*) AS audit_row_count FROM MonthlySalesAudit;

/* ============================================================================
   END OF FILE
   ============================================================================ */
