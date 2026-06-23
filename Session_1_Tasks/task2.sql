-- =====================================================================
--  ABC Inc. — Employees / Departments / Salaries / Projects
--  MySQL 8.0+   |   Schema + seed data + Part 1 (Tasks 1-7) + Part 2 (8-12)
-- =====================================================================

DROP DATABASE IF EXISTS abc_inc;
CREATE DATABASE abc_inc;
USE abc_inc;

-- Needed so non-SUPER users can create functions when binary logging is on.
-- (Safe to leave; if you lack privileges, ask your DBA or run as admin.)
SET GLOBAL log_bin_trust_function_creators = 1;

-- =====================================================================
--  SCHEMA
-- =====================================================================

CREATE TABLE departments (
    dept_id    INT AUTO_INCREMENT PRIMARY KEY,
    dept_name  VARCHAR(100) NOT NULL
);

-- employees has TWO foreign keys:
--   dept_id    -> departments  (each employee belongs to a department)
--   manager_id -> employees    (self-reference; a manager is also an employee)
CREATE TABLE employees (
    emp_id     INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    dept_id    INT,
    manager_id INT,
    hire_date  DATE NOT NULL,
    is_active  TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_emp_dept    FOREIGN KEY (dept_id)    REFERENCES departments(dept_id),
    CONSTRAINT fk_emp_manager FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- One current salary row per employee. Some employees may have NO row
-- (so we can test "include employees with no salary record").
-- amount is stored in the unit given by salary_type.
CREATE TABLE salaries (
    salary_id   INT AUTO_INCREMENT PRIMARY KEY,
    emp_id      INT NOT NULL UNIQUE,
    amount      DECIMAL(12,2) NOT NULL,
    salary_type ENUM('monthly','annual') NOT NULL,
    CONSTRAINT fk_sal_emp FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

CREATE TABLE projects (
    project_id   INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'Active'
);

-- Many-to-many between employees and projects, plus hours logged.
CREATE TABLE project_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id        INT NOT NULL,
    project_id    INT NOT NULL,
    hours_logged  INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_pa_emp     FOREIGN KEY (emp_id)     REFERENCES employees(emp_id),
    CONSTRAINT fk_pa_project FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

-- =====================================================================
--  SEED DATA  (deliberately includes edge cases each task needs)
-- =====================================================================

INSERT INTO departments (dept_id, dept_name) VALUES
    (1, 'Engineering'),
    (2, 'Sales'),
    (3, 'Human Resources'),
    (4, 'Finance'),
    (5, 'Marketing');          -- Marketing has ZERO employees (tests Task 2)

INSERT INTO employees (emp_id, name, dept_id, manager_id, hire_date, is_active) VALUES
    (1, 'Alice Khan',   1, NULL, '2015-03-01', 1),   -- no manager (tests Task 5)
    (2, 'Bob Ahmed',    1, 1,    '2018-06-15', 1),
    (3, 'Carol Iqbal',  1, 1,    '2019-01-20', 1),
    (4, 'Dave Malik',   1, 2,    '2020-09-10', 1),
    (5, 'Eve Raza',     2, 1,    '2017-11-05', 1),
    (6, 'Frank Shah',   2, 5,    '2021-02-01', 1),
    (7, 'Grace Noor',   3, 1,    '2016-07-23', 1),   -- on no project (tests Task 3)
    (8, 'Heidi Aslam',  4, 1,    '2022-04-12', 1);   -- no salary + no project

INSERT INTO salaries (emp_id, amount, salary_type) VALUES
    (1, 200000.00, 'annual'),
    (2,   9000.00, 'monthly'),
    (3,  95000.00, 'annual'),
    (4,   7000.00, 'monthly'),
    (5, 120000.00, 'annual'),
    (6,   6000.00, 'monthly'),
    (7,  80000.00, 'annual');
    -- emp 8 (Heidi) intentionally has NO salary row

INSERT INTO projects (project_id, project_name, status) VALUES
    (1, 'Apollo', 'Active'),
    (2, 'Zephyr', 'Active'),
    (3, 'Helios', 'Active'),
    (4, 'Orion',  'Active');

INSERT INTO project_assignments (emp_id, project_id, hours_logged) VALUES
    -- Apollo has 5 employees -> the only project with > 3 (tests Task 6)
    (1, 1, 120), (2, 1, 100), (3, 1, 90), (4, 1, 80), (5, 1, 60),
    (2, 2, 50),  (3, 2, 40),
    (4, 3, 30),  (6, 3, 70),
    (1, 4, 20);
    -- Grace (7) and Heidi (8) are on no project (tests Task 3)


-- =====================================================================
--  PART 1 — Joins, COUNT, GROUP BY, ORDER BY
-- =====================================================================

-- Task 1 — Employee & salary list (LEFT JOIN keeps employees with no salary)
SELECT e.name, d.dept_name, s.amount AS current_salary, s.salary_type
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id
LEFT JOIN salaries   s ON s.emp_id  = e.emp_id;

-- Task 2 — Department headcount including empty departments
--   Start FROM departments, LEFT JOIN employees, COUNT(e.emp_id) so 0 shows as 0.
SELECT d.dept_name, COUNT(e.emp_id) AS headcount
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id
ORDER BY headcount DESC;

-- Task 3 — Employees on no project (anti-join: LEFT JOIN ... WHERE right IS NULL)
SELECT e.name, d.dept_name, e.hire_date
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id
LEFT JOIN project_assignments pa ON pa.emp_id = e.emp_id
WHERE pa.assignment_id IS NULL;

-- Task 4 — Department salary summary (amounts annualised so totals are meaningful)
SELECT d.dept_name,
       SUM(CASE WHEN s.salary_type='monthly' THEN s.amount*12 ELSE s.amount END) AS total_salary,
       AVG(CASE WHEN s.salary_type='monthly' THEN s.amount*12 ELSE s.amount END) AS avg_salary,
       COUNT(DISTINCT e.emp_id) AS employee_count
FROM departments d
JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN salaries s ON s.emp_id = e.emp_id
GROUP BY d.dept_id, d.dept_name
ORDER BY total_salary DESC;

-- Task 5 — Employee & manager (self LEFT JOIN; managerless employees still show)
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON m.emp_id = e.manager_id;

-- Task 6 — Projects with > 3 employees (HAVING filters AFTER grouping)
SELECT p.project_name,
       COUNT(pa.emp_id)      AS employee_count,
       SUM(pa.hours_logged)  AS total_hours
FROM projects p
JOIN project_assignments pa ON pa.project_id = p.project_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(pa.emp_id) > 3
ORDER BY total_hours DESC;

-- Task 7 — Department x Project matrix INCLUDING zero combinations
--   CROSS JOIN makes every dept-project pair (so zeros appear).
--   The LEFT JOIN must tie the assignment's EMPLOYEE to the department,
--   otherwise every project's assignments get counted under every dept.
SELECT d.dept_name, p.project_name, COUNT(ep.emp_id) AS emp_count
FROM departments d
CROSS JOIN projects p
LEFT JOIN (
        SELECT pa.project_id, e.emp_id, e.dept_id
        FROM project_assignments pa
        JOIN employees e ON e.emp_id = pa.emp_id
    ) ep ON ep.project_id = p.project_id
        AND ep.dept_id    = d.dept_id
GROUP BY d.dept_id, d.dept_name, p.project_id, p.project_name
ORDER BY d.dept_name, p.project_name;


-- =====================================================================
--  PART 2 — Functions, Stored Procedures
-- =====================================================================

DELIMITER $$

-- Task 8 — Scalar function: full years of tenure
DROP FUNCTION IF EXISTS fn_get_emp_tenure $$
CREATE FUNCTION fn_get_emp_tenure(p_emp_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_hire DATE;
    SELECT hire_date INTO v_hire FROM employees WHERE emp_id = p_emp_id;
    IF v_hire IS NULL THEN
        RETURN NULL;                 -- no such employee
    END IF;
    RETURN TIMESTAMPDIFF(YEAR, v_hire, CURDATE());
END $$

-- Task 9 — Scalar function: current ANNUAL salary (0 if none)
DROP FUNCTION IF EXISTS fn_annual_salary $$
CREATE FUNCTION fn_annual_salary(p_emp_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_amount DECIMAL(12,2);
    DECLARE v_type   VARCHAR(10);
    SELECT amount, salary_type INTO v_amount, v_type
    FROM salaries WHERE emp_id = p_emp_id;
    IF v_amount IS NULL THEN
        RETURN 0;                    -- no salary record
    END IF;
    IF v_type = 'monthly' THEN
        RETURN v_amount * 12;
    ELSE
        RETURN v_amount;
    END IF;
END $$

-- Task 11 — Stored procedure: department salary report
--   Returns a result set AND four OUT parameters.
DROP PROCEDURE IF EXISTS sp_dept_salary_report $$
CREATE PROCEDURE sp_dept_salary_report(
    IN  p_dept_id      INT,
    OUT p_emp_count    INT,
    OUT p_total_salary DECIMAL(15,2),
    OUT p_avg_salary   DECIMAL(15,2),
    OUT p_top_earner   VARCHAR(100)
)
BEGIN
    -- (1) result set: employees in the department with their annual salary
    SELECT e.emp_id, e.name,
           fn_annual_salary(e.emp_id) AS annual_salary
    FROM employees e
    WHERE e.dept_id = p_dept_id;

    -- (2) aggregates into output parameters
    SELECT COUNT(e.emp_id),
           COALESCE(SUM(fn_annual_salary(e.emp_id)), 0),
           COALESCE(AVG(NULLIF(fn_annual_salary(e.emp_id),0)), 0)
    INTO p_emp_count, p_total_salary, p_avg_salary
    FROM employees e
    WHERE e.dept_id = p_dept_id;

    -- (3) highest earner's name
    SET p_top_earner = NULL;
    SELECT e.name INTO p_top_earner
    FROM employees e
    WHERE e.dept_id = p_dept_id
    ORDER BY fn_annual_salary(e.emp_id) DESC
    LIMIT 1;
END $$

-- Task 12 — Stored procedure: give a whole department a % raise, transactional
DROP PROCEDURE IF EXISTS sp_give_raise $$
CREATE PROCEDURE sp_give_raise(
    IN p_dept_id INT,
    IN p_pct     DECIMAL(5,2)
)
BEGIN
    -- If ANY statement errors, roll back and report instead of crashing.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error: raise failed. Transaction rolled back.' AS message;
    END;

    START TRANSACTION;
        UPDATE salaries s
        JOIN employees e ON e.emp_id = s.emp_id
        SET s.amount = s.amount * (1 + p_pct/100)
        WHERE e.dept_id = p_dept_id
          AND e.is_active = 1;
    COMMIT;

    SELECT CONCAT('Applied ', p_pct, '% raise to active employees in department ',
                  p_dept_id, '.') AS message;
END $$

DELIMITER ;

-- =====================================================================
--  Task 10 — "Table-valued function + CROSS APPLY"  (MySQL adaptation)
-- =====================================================================
--  MySQL has NO inline table-valued functions and NO CROSS APPLY
--  (those are SQL Server features). A MySQL function can only return a
--  single scalar value. The equivalent of "for every department, return
--  its employees with salary and tenure" is simply a JOIN query:

SELECT d.dept_id, d.dept_name,
       e.emp_id, e.name,
       fn_annual_salary(e.emp_id)   AS annual_salary,
       fn_get_emp_tenure(e.emp_id)  AS tenure_years
FROM departments d
JOIN employees e ON e.dept_id = d.dept_id
ORDER BY d.dept_id, e.emp_id;

--  If you want the closest analogue to CROSS APPLY, MySQL 8.0.14+ has
--  LATERAL, which lets a subquery reference the outer table:

SELECT d.dept_name, x.name, x.annual_salary, x.tenure_years
FROM departments d
JOIN LATERAL (
    SELECT e.name,
           fn_annual_salary(e.emp_id)  AS annual_salary,
           fn_get_emp_tenure(e.emp_id) AS tenure_years
    FROM employees e
    WHERE e.dept_id = d.dept_id
) AS x
ORDER BY d.dept_name;


-- =====================================================================
--  TEST CALLS
-- =====================================================================

-- Task 8 test
SELECT e.name, fn_get_emp_tenure(e.emp_id) AS tenure_years FROM employees e;

-- Task 9 test
SELECT e.name, fn_annual_salary(e.emp_id) AS annual_salary FROM employees e;

-- Task 11 test
CALL sp_dept_salary_report(1, @cnt, @total, @avg, @top);
SELECT @cnt AS emp_count, @total AS total_salary, @avg AS avg_salary, @top AS top_earner;

-- Task 12 test (give Engineering a 10% raise, then look at the result)
CALL sp_give_raise(1, 10);
SELECT e.name, fn_annual_salary(e.emp_id) AS annual_salary
FROM employees e WHERE e.dept_id = 1;