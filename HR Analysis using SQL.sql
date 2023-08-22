# Creating database Humman Resource
Create Database humanresource;

# Using huanresource database as default database  
Use humanresource;

# Checking the data
Select * from hr;

# Data Cleaning --

# Altering the name and dtype of column
Alter Table hr Change Column ï»¿id emp_id Varchar(20);
# Converting dates into right format and dtype
Set sql_safe_updates = 0;
# For Birthdate
Update hr 
Set birthdate = Case
When birthdate like '%/%' Then date_format(str_to_date(birthdate,'%m/%d/%Y'),'%Y-%m-%d')
When birthdate like '%-%' Then date_format(str_to_date(birthdate,'%m-%d-%Y'),'%Y-%m-%d')
Else NULL
END
;
ALTER TABLE hr MODIFY COLUMN birthdate DATE;

# For Hiredate
Update hr 
Set hire_date = Case
When hire_date like '%/%' Then date_format(str_to_date(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
When hire_date like '%-%' Then date_format(str_to_date(hire_date,'%m-%d-%Y'),'%Y-%m-%d')
Else NULL
END
;
ALTER TABLE hr MODIFY COLUMN hire_date DATE;

# For Termination Date
SET @@SESSION.sql_mode='NO_ZERO_DATE,NO_ZERO_IN_DATE';
Update hr
set termdate = date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
where termdate Is Not Null and termdate <> ' ';
ALTER TABLE hr MODIFY COLUMN termdate DATE;

# Adding new column age
Alter Table hr Add Column age INT;
Update hr set age = timestampdiff( Year, birthdate, curdate());

# Some issues with the data are like age<18, even in -ve along with termination dates in future can e due to contracts
Select min(age), max(age) from hr;

Select Count(*) from hr where age<18;

SELECT COUNT(*) FROM hr WHERE termdate is Null;

Describe hr;

# Let's Try answering some questions:
# What is the gender breakdown of employees in the company?
Select gender, Count(*) as Distribution from hr where age>=18 group by gender;

# What is the race/ethnicity breakdown of employees in the company?
Select race, Count(*) as Distribution from hr where age>=18 group by race order by Distribution DESC;

# What is the age distribution of employees in the company?
SELECT 
  CASE 
    WHEN age >= 18 AND age <= 24 THEN '18-24'
    WHEN age >= 25 AND age <= 34 THEN '25-34'
    WHEN age >= 35 AND age <= 44 THEN '35-44'
    WHEN age >= 45 AND age <= 54 THEN '45-54'
    WHEN age >= 55 AND age <= 64 THEN '55-64'
    ELSE '65+' 
  END AS age_group, gender, COUNT(*) AS count FROM hr WHERE age >= 18 GROUP BY age_group, gender ORDER BY age_group, gender;

# How many employees work at headquarters versus remote locations?
SELECT location, COUNT(*) as count FROM hr
WHERE age >= 18 GROUP BY location;

# What is the average length of employment for employees who have been terminated?
SELECT ROUND(AVG(DATEDIFF(termdate, hire_date))/365,0) AS avg_length_of_employment
FROM hr WHERE termdate Is Not Null AND termdate <= CURDATE() AND age >= 18;

# How does the gender distribution vary across departments and job titles?
SELECT department, gender, COUNT(*) as count FROM hr
WHERE age >= 18
GROUP BY department, gender
ORDER BY department;

# What is the distribution of job titles across the company?
SELECT jobtitle, COUNT(*) as count
FROM hr
WHERE age >= 18
GROUP BY jobtitle
ORDER BY jobtitle DESC;

# Which department has the highest turnover rate?
SELECT department, COUNT(*) as total_count, 
    SUM(CASE WHEN termdate <= CURDATE() AND termdate IS NOT NULL THEN 1 ELSE 0 END) as terminated_count, 
    SUM(CASE WHEN termdate IS NOT NULL THEN 1 ELSE 0 END) as active_count,
    (SUM(CASE WHEN termdate <= CURDATE() THEN 1 ELSE 0 END) / COUNT(*)) as termination_rate
FROM hr
WHERE age >= 18
GROUP BY department
ORDER BY termination_rate DESC;

# What is the distribution of employees across locations by city and state?
SELECT location_state, COUNT(*) as count FROM hr
WHERE age >= 18
GROUP BY location_state
ORDER BY count DESC;

# What is the tenure distribution for each department?
SELECT department, ROUND(AVG(DATEDIFF(CURDATE(), termdate)/365),0) as avg_tenure FROM hr
WHERE termdate <= CURDATE() AND termdate <> '0000-00-00' AND age >= 18
GROUP BY department;

# How has the company's employee count changed over time based on hire and term dates?
SELECT year, hires, terminations, (hires - terminations) AS net_change, ROUND(((hires - terminations) / hires * 100), 2) AS net_change_percent
FROM (
    SELECT 
        YEAR(hire_date) AS year, 
        COUNT(*) AS hires, 
        SUM(CASE WHEN termdate IS NOT NULL AND termdate <= CURDATE() THEN 1 ELSE 0 END) AS terminations
    FROM 
        hr
    WHERE age >= 18
    GROUP BY 
        YEAR(hire_date)
) subquery
ORDER BY 
    year ASC;
