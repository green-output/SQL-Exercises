-- SQL SERVER EXERCISES
-- Data source: https://www.kaggle.com/silicon99/dft-accident-data
-- Data in Database format: https://drive.google.com/file/d/1nYlkx9oWqn35Q1ctqrPyzrpvWD0FhOGo/view?usp=sharing

-- SOLUTIONS

--1) How many accidents happened per accident severity?

SELECT Accident_Severity, COUNT(*) AS count_accid 
FROM Accidents
GROUP BY Accident_Severity
ORDER BY Accident_Severity;


--2) What was the severity of the accident with most vehicles involved?

SELECT Accident_Index, Accident_Severity, Number_of_Vehicles 
FROM Accidents
WHERE Number_of_Vehicles IN (SELECT MAX(Number_of_Vehicles) FROM Accidents);


--3) How many casualties occurred between January and April in 2006?

SELECT COUNT(*) AS casualties_count
FROM Casualties 
INNER JOIN Accidents ON Casualties.Accident_Index = Accidents.Accident_Index
WHERE Accidents.Date BETWEEN '2006-01-01' AND '2006-04-30';


--4) What were the top 3 months per year with the most accidents?

WITH tb1 AS (
SELECT year, month, COUNT(*) AS count_accid, ROW_NUMBER() OVER(PARTITION BY year ORDER BY COUNT(*) DESC) AS rk
FROM (
	SELECT *, FORMAT(Date, 'MMMM') AS month, YEAR(Date) AS year
	FROM Accidents
	) AS temp
GROUP BY year, month
)

SELECT * FROM tb1 WHERE rk < 4;


--5) What was the percentage of accidents in urban and rural accidents?

SELECT 
	CASE WHEN urban_or_rural_area = 1 THEN 'Urban' ELSE 'Rural' END area_type, 
	COUNT(*) counter, 
	ROUND(100* (COUNT(*) / SUM(COUNT(*)) OVER()), 1) pct
FROM accidents
WHERE urban_or_rural_area <> 3
GROUP BY urban_or_rural_area;


--6) Which accidents involved three or more casualties from the same age band (ignoring -1 records)?

SELECT DISTINCT accident_index, age_band_of_casualty, cnt
FROM (
		SELECT accident_index, age_band_of_casualty, COUNT(*) cnt
		FROM casualties
		WHERE age_band_of_casualty <> -1
		GROUP BY 1, 2
	)
WHERE cnt >= 3;


--7) What was the average age among casualties per each bike (ID 1) accident with at least 5 victims?

SELECT C.Accident_Index, AVG(C.Age_of_Casualty)::INT AS avg_age 
FROM Casualties AS C
INNER JOIN Vehicles AS V ON C.Accident_Index = V.Accident_Index
WHERE V.Vehicle_Type = 1 AND C.Accident_Index IN (SELECT Accident_Index FROM Casualties GROUP BY Accident_Index HAVING COUNT(*) > 4)
GROUP BY C.Accident_Index;

OPTION 2

SELECT cas.accident_index, AVG(cas.age_of_casualty)::INT
FROM (
		SELECT accident_index FROM accidents WHERE number_of_casualties > 4
) INNER JOIN casualties cas USING("accident_index")
INNER JOIN (SELECT accident_index FROM vehicles WHERE vehicle_type = 1) vh USING("accident_index")
GROUP BY cas.accident_index;


--8) What was the amount of fatal casualties in accidents occurred at roads with 30 km/h speed limit?

SELECT COUNT(cas.casualty_reference) fatal_cnt
FROM (SELECT accident_index FROM accidents WHERE speed_limit = 30) acc 
INNER JOIN (SELECT accident_index, casualty_reference FROM casualties WHERE casualty_severity = 1) cas 
	USING("accident_index");


--9) Among accidents involving only 1 car, dense rank the top 5 engine capacity per driver age band (ignoring -1 records in both fields).

WITH cte1 AS(
SELECT 
	age_band_of_driver, 
	engine_capacity_cc,
	DENSE_RANK() OVER(PARTITION BY age_band_of_driver ORDER BY engine_capacity_cc DESC) rnk
FROM
	(SELECT 
		accident_index, 
		age_band_of_driver, 
		engine_capacity_cc
	FROM vehicles
	WHERE age_band_of_driver <> -1 AND engine_capacity_cc <> -1) tab1
INNER JOIN 
	(SELECT accident_index FROM accidents WHERE number_of_vehicles = 1) acc USING(accident_index)
	)
SELECT * FROM cte1 WHERE rnk < 6 ORDER BY age_band_of_driver;


--10) Which accidents involved different vehicle types while including type n. 23?

SELECT 
	DISTINCT A.Accident_Index, 
	A.Vehicle_Type AS first_vehicle, 
	B.Vehicle_Type AS second_vehicle 
FROM 
	Vehicles AS A, 
	Vehicles AS B
WHERE A.Accident_Index = B.Accident_Index AND 
	A.Vehicle_Type <> B.Vehicle_Type AND 
	A.Vehicle_Type = 23;
