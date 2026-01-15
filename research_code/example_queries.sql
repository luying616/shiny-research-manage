-- Research Database Query Example
-- Author: Research Team
-- Date: 2026-01-15
-- Category: database-queries

-- Create a sample research subjects table
CREATE TABLE IF NOT EXISTS research_subjects (
    subject_id INT PRIMARY KEY,
    age INT,
    group_name VARCHAR(50),
    measurement_value DECIMAL(10, 2),
    collection_date DATE
);

-- Insert sample data
INSERT INTO research_subjects (subject_id, age, group_name, measurement_value, collection_date) VALUES
    (1, 25, 'Control', 85.5, '2026-01-01'),
    (2, 30, 'Treatment', 92.3, '2026-01-02'),
    (3, 28, 'Control', 88.1, '2026-01-03'),
    (4, 35, 'Treatment', 95.7, '2026-01-04'),
    (5, 27, 'Control', 86.9, '2026-01-05');

-- Query: Calculate average measurement by group
SELECT 
    group_name,
    COUNT(*) as subject_count,
    AVG(measurement_value) as avg_measurement,
    MIN(measurement_value) as min_measurement,
    MAX(measurement_value) as max_measurement,
    STDDEV(measurement_value) as std_measurement
FROM research_subjects
GROUP BY group_name
ORDER BY group_name;

-- Query: Find subjects with above-average measurements
SELECT 
    subject_id,
    age,
    group_name,
    measurement_value
FROM research_subjects
WHERE measurement_value > (SELECT AVG(measurement_value) FROM research_subjects)
ORDER BY measurement_value DESC;

-- Query: Monthly summary statistics
SELECT 
    DATE_FORMAT(collection_date, '%Y-%m') as month,
    COUNT(*) as measurements,
    AVG(measurement_value) as monthly_avg
FROM research_subjects
GROUP BY DATE_FORMAT(collection_date, '%Y-%m')
ORDER BY month;
