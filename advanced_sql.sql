SELECT
    job_title_short AS title,
    job_location AS location,
    job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'EST' AS datetime,
    EXTRACT(DAY FROM job_posted_date) AS date_day,
    EXTRACT(MONTH FROM job_posted_date) AS date_month
FROM job_postings_fact
LIMIT 5;

/*to get monthly trend of job postings */

SELECT 
    COUNT(job_id) AS job_count,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM
    job_postings_fact
GROUP BY
    month;

/*to get monthly trend of Data Analyst */
SELECT 
    COUNT(job_id) AS data_analyst_count,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    month
ORDER BY
    data_analyst_count DESC;

/*1. write a query to find the average salary both yearly(salary_year_avg) and hourly
(salary_hour_avg) for job postings that were posted after june 1, 2023. 
Group the results by job schedule type.*/
SELECT
    AVG(salary_year_avg) AS avg_year_salary,
    AVG(salary_hour_avg) AS avg_hour_salary,
    job_schedule_type
FROM
    job_postings_fact
WHERE
    job_posted_date > '2023-06-01'
GROUP BY
    job_schedule_type


/* Write a query to count the number of job postings for each month in 2023,
adjusting the job_posted_date to be in 'America/New_York' time zone before 
extracting(hint) the month. Assume the job_posted_date is stored in UTC. 
Group by and order by the month.*/
SELECT 
    COUNT(job_postings_fact.job_id) AS job_count,
    EXTRACT(MONTH FROM (job_posted_date AT TIME ZONE 'America/New_York')) AS month
FROM job_postings_fact
WHERE
    EXTRACT(YEAR FROM (job_posted_date AT TIME ZONE 'America/New_York')) = 2023
GROUP BY 
    EXTRACT(MONTH FROM (job_posted_date AT TIME ZONE 'America/New_York'))
ORDER BY
    EXTRACT(MONTH FROM (job_posted_date AT TIME ZONE 'America/New_York'))


/* Write a query to find companies (include company name) that have posted jobs
offering health insurance, where these postings were made in the second quarter of 2023.
Use date extraction to filter by quarter*/
SELECT 
    company_dim.name AS company_name,
    job_postings_fact.job_id,
    EXTRACT(quarter FROM job_posted_date) AS quarter_date
FROM company_dim LEFT JOIN  job_postings_fact ON company_dim.company_id = job_postings_fact.company_id
WHERE
    job_health_insurance = TRUE AND EXTRACT(YEAR FROM job_posted_date) = 2023
    AND EXTRACT(QUARTER FROM job_posted_date) = 2
ORDER BY 
    company_name;

-- PRACTICE PROBLEM 6:
-- CREATE TABLE JAN 2023 JOBS, FEB 2023 JOBS, AND MARCH 2023 JOBS 

CREATE TABLE jan_jobs AS
            SELECT *
            FROM job_postings_fact
            WHERE EXTRACT(MONTH FROM job_posted_date) = 1

CREATE TABLE feb_jobs AS
            SELECT *
            FROM job_postings_fact
            WHERE EXTRACT(MONTH FROM job_posted_date) = 2

CREATE TABLE march_jobs AS
            SELECT *
            FROM job_postings_fact
            WHERE EXTRACT(MONTH FROM job_posted_date) = 3

-- Test
SELECT 
    job_posted_date,
    job_title_short,
    job_health_insurance
FROM
    march_jobs;

-- CASE expression
/* Label new column as follows:
    - 'Anywhere' jobs as 'Remote'
    - 'New York, NY' jobs as 'Local'
    - Otherwise 'Onsite' 
    Also count jobs in each category*/

SELECT
    job_title_short,
    job_location,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact;

SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact
GROUP BY
    location_category;

-- For Data Analyst
SELECT
    COUNT(job_id) AS number_of_jobs,
    CASE
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'Onsite'
    END AS location_category
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    location_category;

/* I want to categorize the salaries from each job posting. To see if it fits in my desired salary range.
• Put salary into different buckets
• Define what's a high, standard, or low salary with our own conditions
• Why? It is easy to determine which job postings are worth looking at based on salary.
Bucketing is a common practice in data analysis when viewing categories.
• I only want to look at data analyst roles
• Order from highest to lowest. (highest - 960000, lowest - 15000,  , 250000 < 550000, <550000)*/

SELECT 
    job_title_short,
    CASE 
     WHEN salary_year_avg < 250000 THEN 'low'
     WHEN salary_year_avg < 550000 THEN 'standard'
     ELSE 'high'
    END AS salary_range
FROM
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
ORDER BY
    salary_year_avg DESC;

-- SUBQUERY

SELECT *
FROM ( -- subquery starts here
        SELECT *
            FROM job_postings_fact
            WHERE EXTRACT(MONTH FROM job_posted_date) = 1
            ) AS january_jobs;
            -- subquery ends here --

-- CTE

WITH janury_jobs AS ( -- CTE STARTS HERE
     SELECT *
            FROM job_postings_fact
            WHERE EXTRACT(MONTH FROM job_posted_date) = 1
            ) -- CTE ENDS HERE
SELECT *
FROM janury_jobs;

-- Find the companies that are offering jobs that don't have requirements 
-- for a degree.

SELECT DISTINCT
    company_dim.name AS company_name,
    company_dim.company_id
FROM 
    company_dim LEFT JOIN job_postings_fact
    ON company_dim.company_id = job_postings_fact.company_id
WHERE 
    job_no_degree_mention = TRUE
ORDER BY
    company_dim.company_id;

-- Same using subquery.
SELECT 
    company_id,
    name AS company_name
FROM 
    company_dim
WHERE company_id IN (
    SELECT 
        company_id
    FROM 
        job_postings_fact
    WHERE 
        job_no_degree_mention = TRUE)
ORDER BY 
    company_id;

-- CTE EXAMPLE --
/*
Find the companies that have the most job openings.
- Get the total number of job postings per company_id
- Return the total number of jobs with the company name
*/

WITH company_job_count AS (
    SELECT
            company_id,
            COUNT(*) AS total_jobs
    FROM
            job_postings_fact
    GROUP BY 
            company_id
)

SELECT
    company_dim.name AS company_name,
    company_job_count.total_jobs
FROM company_dim
    LEFT JOIN company_job_count 
    ON company_dim.company_id = company_job_count.company_id
ORDER BY 
    total_jobs DESC;

/*Identify the top 5 skills that are most frequently mentioned in job postings.
use a subquery to find the skill IDs with the highest counts in the skills_job_dim
table and then join this result with the skills_dim table to get the skill names.*/

SELECT 
    skills_dim.skills AS skill_name,
    skills_dim.skill_id,
    skill_count.total_skill
FROM (SELECT 
        skill_id,
        COUNT(*) AS total_skill
    FROM
        skills_job_dim
    GROUP BY 
        skill_id 
    ORDER BY
        total_skill DESC
    LIMIT 5
            ) AS skill_count 
    INNER JOIN skills_dim ON skill_count.skill_id = skills_dim.skill_id
    ORDER BY
        skill_count.total_skill DESC;

/*Determine the size category ('Small, 'Medium, or 'Large") for each company by first 
identifying the number of job postings they have. Use a subquery to calculate the total job postings
per company. A company is considered 'Small" if it has less than 10 job postings, 'Medium' 
if the number of job postings is between 10 and 50, and "Large" if it has more than 50 job postings.
imPlement a subquery to aggregate job counts per company before classifying them based on size*/


SELECT
    company_id,
    total_jobs,
    CASE 
        WHEN total_jobs < 10 THEN 'Small'
        WHEN total_jobs < 50 THEN 'Medium'
        ELSE 'Large'
    END AS company_size_category
FROM (SELECT
        company_id,
        COUNT(*) AS total_jobs
    FROM
        job_postings_fact
    GROUP BY 
    company_id

) AS company_jobs;

/* Find the count of the number of remote job postings per skill
    - Display the top 5 skills by their demand in remote jobs
    - Include skill ID, name, and count of postings requiring the skill*/

WITH job_categories AS(
            SELECT
                job_id,
                CASE
                    WHEN job_location = 'Anywhere' THEN 'Remote'
                    WHEN job_location = 'New York, NY' THEN 'Local'
                    ELSE 'Onsite'
                END AS location_category
            FROM
                job_postings_fact
            WHERE 
                job_location = 'Anywhere') 

SELECT 
    skills_job_dim.skill_id,
    skills_dim.skills AS skill_name,
    COUNT(skills_job_dim.job_id) AS posting_count
FROM 
    job_categories INNER JOIN skills_job_dim
    ON job_categories.job_id = skills_job_dim.job_id
    INNER JOIN skills_dim ON skills_job_dim.skill_id = skills_dim.skill_id
WHERE 
    location_category = 'Remote'
GROUP BY
    skills_job_dim.skill_id, skills_dim.skills
ORDER BY
    posting_count DESC
LIMIT 5;

/* PRACTICE 7 Find the count of the number of remote job postings per skill
    - Display the top 5 skills by their demand in remote jobs
    - Include skill ID, name, and count of postings requiring the skill*/

WITH job_skill_count AS (SELECT  
                            skills_job_dim.skill_id,
                            COUNT(*) AS job_count
                        FROM 
                            skills_job_dim INNER JOIN job_postings_fact
                        ON skills_job_dim.job_id = job_postings_fact.job_id
                        WHERE
                            job_work_from_home = TRUE
                        GROUP BY
                            skills_job_dim.skill_id
)

SELECT
    skills_dim.skill_id,
    job_skill_count.job_count,
    skills_dim.skills
FROM job_skill_count INNER JOIN skills_dim
    ON job_skill_count.skill_id = skills_dim.skill_id
ORDER BY
    job_skill_count.job_count DESC
LIMIT 5;


-- UNION ALL

-- get jobs and companies from january
SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    jan_jobs

UNION ALL

-- get jobs and companies from february
SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    feb_jobs

UNION ALL

-- get jobs and companies from march
SELECT 
    job_title_short,
    company_id,
    job_location
FROM
    march_jobs;

/* 
Find job postings from the first quarter that have a salary greater than 
$70k
- Combine job postings tables from the first quarter of 2023 (jan-mar)
- Gets job postings with an average yearly salary > $70,000*/

SELECT 
    quarter1_job_postings.job_title_short,
    quarter1_job_postings.job_location,
    quarter1_job_postings.job_via,
    quarter1_job_postings.job_posted_date::DATE
FROM (
    SELECT *
    FROM jan_jobs
    UNION ALL
    SELECT *
    FROM feb_jobs
    UNION ALL
    SELECT *
    FROM march_jobs) AS quarter1_job_postings
WHERE
    salary_year_avg > 70000;

/* To this display salary and care about Data Analyst jobs.*/

SELECT 
    quarter1_job_postings.job_title_short,
    quarter1_job_postings.job_location,
    quarter1_job_postings.job_via,
    quarter1_job_postings.job_posted_date::DATE,
    quarter1_job_postings.salary_year_avg
FROM (
    SELECT *
    FROM jan_jobs
    UNION ALL
    SELECT *
    FROM feb_jobs
    UNION ALL
    SELECT *
    FROM march_jobs) AS quarter1_job_postings
WHERE
    salary_year_avg > 70000 AND quarter1_job_postings.job_title_short = 'Data Analyst'
ORDER BY
    quarter1_job_postings.salary_year_avg DESC






















