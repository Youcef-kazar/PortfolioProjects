/*
Skills Used:

1.   Relational database modeling.
2.   Counting Rows and Items.
3.   Aggregation Functions.
4.   Extreme Value Identification.
5.   Slicing Data.
6.   Limiting Data.
7.   Sorting Data.
8.   Filtering Patterns.
9.   Groupings, Rolling up Data and Filtering in Groups.
10.  Joining tables.
11.  Partitiioning clauses.
12.  Inline views.
13.  Common table expression (CTE).

*/
-- Let's select the databse that we're performing SQL operations into.
USE covid_db;

--Create countries table
SELECT DISTINCT location AS country_name,
                iso_code,
                continent,
                population
INTO   countries
FROM   covid_raw_data
WHERE  continent IS NOT NULL;

--View countries data 
SELECT *
FROM   countries;

--Add an auto increment id column and make it a primary key for creating relationship later on.
ALTER TABLE countries
  ADD country_id INT IDENTITY(1, 1) PRIMARY KEY;

--Check for duplicate country names. The query will return only duplicate rows.
--If no rows were returned, then we have no duplicates.
SELECT *
FROM   (SELECT c.*,
               ROW_NUMBER()
                 OVER (
                   partition BY c.country_name
                   ORDER BY c.country_id) rn
        FROM   countries c) a
WHERE  a.rn > 1;

--Create covid deaths table 
SELECT c.country_id,
       d.date,
       d.total_deaths,
       d.new_deaths
INTO   covid_deaths
FROM   covid_raw_data d,
       countries c
WHERE  d.location = c.country_name
       AND d.continent IS NOT NULL;

--Change columns data types
ALTER TABLE covid_deaths
  ALTER COLUMN total_deaths NUMERIC;

ALTER TABLE covid_deaths
  ALTER COLUMN new_deaths NUMERIC;

-- Create a foreign key constraint on the covid_deaths table to refrence the country table
ALTER TABLE covid_deaths
  ADD FOREIGN KEY (country_id) REFERENCES countries(country_id);

--View the covid_deaths table
SELECT *
FROM   covid_deaths;

--Create covid_cases table 
SELECT c.country_id,
       d.date,
       d.total_cases,
       d.new_cases
INTO   covid_cases
FROM   covid_raw_data d,
       countries c
WHERE  d.location = c.country_name
       AND d.continent IS NOT NULL;

--Change columns data types
ALTER TABLE covid_cases
  ALTER COLUMN total_cases NUMERIC;

ALTER TABLE covid_cases
  ALTER COLUMN new_cases NUMERIC;

-- Create a foreign key constraint on the covid_cases table to refrence the country table
ALTER TABLE covid_cases
  ADD FOREIGN KEY (country_id) REFERENCES countries(country_id);

--View the covid_cases table
SELECT *
FROM   covid_cases;

--Create covid_tests table 
SELECT c.country_id,
       d.date,
       d.total_tests,
       d.new_tests
INTO   covid_tests
FROM   covid_raw_data d,
       countries c
WHERE  d.location = c.country_name
       AND d.continent IS NOT NULL;

--Change columns data types
ALTER TABLE covid_tests
  ALTER COLUMN total_tests NUMERIC;

ALTER TABLE covid_tests
  ALTER COLUMN new_tests NUMERIC;

-- Create a foreign key constraint on the covid_tests table to refrence the country table
ALTER TABLE covid_tests
  ADD FOREIGN KEY (country_id) REFERENCES countries(country_id);

--View the covid_tests table
SELECT *
FROM   covid_tests;

--Create covid_vaccinations table 
SELECT c.country_id,
       d.date,
       d.total_vaccinations,
       d.people_vaccinated,
       d.people_fully_vaccinated,
       d.new_vaccinations
INTO   covid_vaccinations
FROM   covid_raw_data d,
       countries c
WHERE  d.location = c.country_name
       AND d.continent IS NOT NULL;

--
ALTER TABLE covid_vaccinations
  ALTER COLUMN total_vaccinations NUMERIC;

ALTER TABLE covid_vaccinations
  ALTER COLUMN new_vaccinations NUMERIC;

ALTER TABLE covid_vaccinations
  ALTER COLUMN people_vaccinated NUMERIC;

ALTER TABLE covid_vaccinations
  ALTER COLUMN people_fully_vaccinated NUMERIC;

-- Create a foreign key constraint on the covid_vaccinations table to refrence the country table
ALTER TABLE covid_vaccinations
  ADD FOREIGN KEY (country_id) REFERENCES countries(country_id);

--View covid_vaccinations data
SELECT *
FROM   covid_vaccinations;

--See the total number and the percentage of infections by country and population
SELECT cnt.country_name                               AS Country,
       cnt.population,
       Max(cs.total_cases)                            AS Total_cases,
       100 * ( Max(cs.total_cases) / cnt.population ) AS
       Percentage_of_infections
FROM   covid_cases cs
       JOIN countries cnt
         ON cnt.country_id = cs.country_id
GROUP  BY cnt.country_name,
          cnt.population
ORDER  BY 4 DESC;

--See the total number and the percentage of tests by country and population
SELECT cnt.country_name                               AS Country,
       cnt.population,
       Max(ct.total_tests)                            AS Total_cases,
       100 * ( Max(ct.total_tests) / cnt.population ) AS Percentage_of_tests
FROM   covid_tests ct
       JOIN countries cnt
         ON cnt.country_id = ct.country_id
GROUP  BY cnt.country_name,
          cnt.population
ORDER  BY 4 DESC;

--See the total number and the percentage of deaths by country and population
SELECT cnt.country_name                                AS Country,
       cnt.population,
       Max(cd.total_deaths)                            AS Total_deaths,
       100 * ( Max(cd.total_deaths) / cnt.population ) AS Percentage_of_deaths
FROM   covid_deaths cd
       JOIN countries cnt
         ON cnt.country_id = cd.country_id
GROUP  BY cnt.country_name,
          cnt.population
ORDER  BY 4 DESC;

--See the probability of death (deaths vs cases)
WITH covid_cases_by_country
     AS (SELECT cnt.country_name    AS Country,
                Max(cs.total_cases) AS Total_cases
         FROM   countries cnt
                JOIN covid_cases cs
                  ON cnt.country_id = cs.country_id
         GROUP  BY cnt.country_name),
     covid_deaths_by_country
     AS (SELECT cnt.country_name     AS Country,
                Max(cs.total_deaths) AS Total_deaths
         FROM   countries cnt
                JOIN covid_deaths cs
                  ON cnt.country_id = cs.country_id
         GROUP  BY cnt.country_name)
SELECT cdth.country,
       cdth.total_deaths,
       ccs.total_cases,
       100 * ( cdth.total_deaths / ccs.total_cases ) AS Death_propability
FROM   covid_deaths_by_country cdth,
       covid_cases_by_country ccs
WHERE  cdth.country = ccs.country
ORDER  BY 4 DESC

--See the total number and the percentage  of people who received at least one vaccine dose
SELECT cnt.country_name                                     AS Country,
       cnt.population,
       Max(cv.people_vaccinated)                            AS
       People_vaccinated_at_least_one_dose,
       100 * ( Max(cv.people_vaccinated) / cnt.population ) AS
       Percentage_of_vaccinations
FROM   covid_vaccinations cv
       JOIN countries cnt
         ON cnt.country_id = cv.country_id
GROUP  BY cnt.country_name,
          cnt.population
--HAVING Cnt.country_name = 'Algeria'
ORDER  BY 4 DESC;

--Total number and percentage of people who received all doses prescribed by the initial vaccination protocol
SELECT cnt.country_name                                           AS Country,
       cnt.population,
       Max(cv.people_fully_vaccinated)                            AS
       Total_people_fully_vaccinated,
       100 * ( Max(cv.people_fully_vaccinated) / cnt.population ) AS
       Percentage_people_fully_vaccinated
FROM   covid_vaccinations cv
       JOIN countries cnt
         ON cnt.country_id = cv.country_id
GROUP  BY cnt.country_name,
          cnt.population
--HAVING cnt.country_name = 'Algeria'
ORDER  BY 4 DESC;

-- See global cases, deaths and people fully vaccinated 
WITH global_cases
     AS (SELECT cnt.continent,
                Sum(ccs.new_cases) AS Total_cases
         FROM   covid_cases ccs
                JOIN countries cnt
                  ON cnt.country_id = ccs.country_id
         GROUP  BY cnt.continent),
     global_deaths
     AS (SELECT cnt.continent,
                Sum(cdth.new_deaths) AS Total_deaths
         FROM   covid_deaths cdth
                JOIN countries cnt
                  ON cnt.country_id = cdth.country_id
         GROUP  BY cnt.continent),
     global_full_vaccinations
     AS (SELECT cnt.continent,
                Sum(cdth.new_vaccinations) AS Total_vaccinations
         FROM   covid_vaccinations cdth
                JOIN countries cnt
                  ON cnt.country_id = cdth.country_id
         GROUP  BY cnt.continent)
SELECT gc.continent,
       gc.total_cases,
       gdth.total_deaths,
       gfvc.total_vaccinations
FROM   global_cases gc
       JOIN global_deaths gdth
         ON gc.continent = gdth.continent
       JOIN global_full_vaccinations gfvc
         ON gc.continent = gfvc.continent;

--Create view for global data by continent
CREATE VIEW global_cases_deaths_vaccinations
AS
  WITH global_cases
       AS (SELECT cnt.continent,
                  Sum(ccs.new_cases) AS Total_cases
           FROM   covid_cases ccs
                  JOIN countries cnt
                    ON cnt.country_id = ccs.country_id
           GROUP  BY cnt.continent),
       global_deaths
       AS (SELECT cnt.continent,
                  Sum(cdth.new_deaths) AS Total_deaths
           FROM   covid_deaths cdth
                  JOIN countries cnt
                    ON cnt.country_id = cdth.country_id
           GROUP  BY cnt.continent),
       global_full_vaccinations
       AS (SELECT cnt.continent,
                  Sum(cdth.new_vaccinations) AS Total_vaccinations
           FROM   covid_vaccinations cdth
                  JOIN countries cnt
                    ON cnt.country_id = cdth.country_id
           GROUP  BY cnt.continent)
  SELECT gc.continent,
         gc.total_cases,
         gdth.total_deaths,
         gfvc.total_vaccinations
  FROM   global_cases gc
         JOIN global_deaths gdth
           ON gc.continent = gdth.continent
         JOIN global_full_vaccinations gfvc
           ON gc.continent = gfvc.continent;

-- See the global_cases_deaths_vaccinations view data
SELECT*
FROM   global_cases_deaths_vaccinations;

--Create view for global data by country using inline views (subqueries from the queries writen above) 
CREATE VIEW country_cases_deaths_vaccinations
AS
SELECT country_name AS Country,
       ct.total_tests,
       ct.percentage_of_tests,
       cs.total_cases,
       cs.percentage_of_infections,
       cd.total_deaths,
       cd.percentage_of_deaths,
       cv_od.people_vaccinated_at_least_one_dose,
       cv_od.percentage_of_vaccinations,
       pfv.total_people_fully_vaccinated,
       pfv.percentage_people_fully_vaccinated
FROM   countries c,
       (SELECT cnt.country_name                               AS Country,
               cnt.population,
               Max(cs.total_cases)                            AS Total_cases,
               100 * ( Max(cs.total_cases) / cnt.population ) AS Percentage_of_infections
        FROM   covid_cases cs
               JOIN countries cnt
                 ON cnt.country_id = cs.country_id
        GROUP  BY cnt.country_name,
                  cnt.population) cs,
       (SELECT cnt.country_name                               AS Country,
               cnt.population,
               Max(ct.total_tests)                            AS Total_tests,
               100 * ( Max(ct.total_tests) / cnt.population ) AS Percentage_of_tests
        FROM   covid_tests ct
               JOIN countries cnt
                 ON cnt.country_id = ct.country_id
        GROUP  BY cnt.country_name,
                  cnt.population) ct,
       (SELECT cnt.country_name                                AS Country,
               cnt.population,
               Max(cd.total_deaths)                            AS Total_deaths,
               100 * ( Max(cd.total_deaths) / cnt.population ) AS Percentage_of_deaths
        FROM   covid_deaths cd
               JOIN countries cnt
                 ON cnt.country_id = cd.country_id
        GROUP  BY cnt.country_name,
                  cnt.population) cd,
       (SELECT cnt.country_name                                     AS Country,
               cnt.population,
               Max(cv.people_vaccinated)                            AS People_vaccinated_at_least_one_dose,
               100 * ( Max(cv.people_vaccinated) / cnt.population ) AS Percentage_of_vaccinations
        FROM   covid_vaccinations cv
               JOIN countries cnt
                 ON cnt.country_id = cv.country_id
        GROUP  BY cnt.country_name,
                  cnt.population) cv_od,
       (SELECT cnt.country_name                                           AS  Country,
               cnt.population,
               Max(cv.people_fully_vaccinated)                            AS Total_people_fully_vaccinated,
               100 * ( Max(cv.people_fully_vaccinated) / cnt.population ) AS Percentage_people_fully_vaccinated
        FROM   covid_vaccinations cv
               JOIN countries cnt
                 ON cnt.country_id = cv.country_id
        GROUP  BY cnt.country_name,
                  cnt.population) pfv
WHERE  c.country_name = cs.country
       AND c.country_name = ct.country
       AND c.country_name = cd.country
       AND c.country_name = cv_od.country
       AND c.country_name = pfv.country;