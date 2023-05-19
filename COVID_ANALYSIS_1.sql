SELECT * FROM INDIANCOLLEGES..CovidDeaths$
SELECT * FROM INDIANCOLLEGES..CovidVaccinations$

--table of total cases at each point of time

SELECT location,date,total_cases,total_deaths FROM INDIANCOLLEGES..CovidDeaths$ ORDER BY 1,2

--percentage of people who died compared to total number of cases
SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as deathpercases FROM INDIANCOLLEGES..CovidDeaths$ ORDER BY 1,2

--covid details in india

SELECT location,date,total_cases,total_deaths FROM INDIANCOLLEGES..CovidDeaths$ WHERE location LIKE '%India%' ORDER BY 1,2
 
 --percentage of people in india affected by the disease from early 2020 to 2021
 SELECT location,date,total_cases,total_deaths,population,(total_cases/population)*100 as percentageofpopulation_affected FROM INDIANCOLLEGES..CovidDeaths$ WHERE location LIKE '%India%' ORDER BY 1,2

--Maximum percentage of people affected in each country

SELECT  location,MAX((total_cases/population))*100 as percentageofpopulation_affected FROM INDIANCOLLEGES..CovidDeaths$ GROUP BY location ORDER BY 2 DESC

--The number of deaths due to covid in each country
SELECT location,MAX(cast(total_deaths as int) )as overall_deaths FROM INDIANCOLLEGES..CovidDeaths$ GROUP BY location ORDER BY overall_deaths DESC

--deaths per each country compared with their gdp as well as hospital beds
SELECT  location,date,(total_deaths/population)*100 as percentageofpopulation_died ,gdp_per_capita FROM INDIANCOLLEGES..CovidDeaths$  ORDER BY 3 DESC

-- DROPPING THE DATE AND REPLACING WITH RIGHT FORMAT
ALTER TABLE INDIANCOLLEGES..CovidDeaths$
ADD date_converted Date;


UPDATE INDIANCOLLEGES..CovidDeaths$
SET date_converted=CONVERT(Date,date)

ALTER TABLE INDIANCOLLEGES..CovidDeaths$
DROP COLUMN date

ALTER TABLE INDIANCOLLEGES..CovidDeaths$
ADD total_death_converted int;

UPDATE INDIANCOLLEGES..CovidDeaths$
SET total_death_converted=CONVERT(int,total_deaths)

--THE TOTAL DEATHS IN EACH CONTINENT

SELECT continent,MAX(total_death_converted) as total_deaths FROM INDIANCOLLEGES..CovidDeaths$  
WHERE continent is not null 
GROUP BY continent  
ORDER BY 2 DESC

--FIND THE MAX NUMBER OF NEW CASES IN EACH COUNTRY AND THE DATE ON WHICH IT HIT MAX NUMBER
SELECT date_converted, location,MAX(CONVERT(int,new_cases)) OVER (PARTITION BY location,date_converted) FROM INDIANCOLLEGES..CovidDeaths$  
WHERE continent is not null
ORDER BY 3 DESC

--FINDING OVERALL EFFECT GLOBALLY

SELECT date_converted, location,MAX(CONVERT(int,new_cases)) OVER (PARTITION BY location,date_converted) FROM INDIANCOLLEGES..CovidDeaths$  
WHERE continent is not null
ORDER BY 3 DESC

--FIND THE PROBALITY OF DEATH IF AFFECTED BY COVID IN EACH COUNTRY
SELECT location,(MAX(cast(total_deaths as int) )/MAX(total_deaths))*100 as death_percentage FROM INDIANCOLLEGES..CovidDeaths$ GROUP BY location ORDER BY overall_deaths DESC

--Lets look at vaccinations GLOBALLY WITH RESPECT TO LOCATION
SELECT location,SUM(CONVERT(int,new_vaccinations)) AS total_vaccinations FROM INDIANCOLLEGES..CovidDeaths$ GROUP BY location ORDER BY 1

--PEOPLE VACCINATED WITH DATE IN EaCH COUNTRY
SELECT location,date,new_vaccinations,SUM(CONVERT(INT,new_vaccinations)) OVER (PARTITION BY location ORDER BY date) 
AS VACCINATION_TILLDATE FROM INDIANCOLLEGES..CovidVaccinations$ WHERE continent is not NULL ORDER BY 1

--PERCENTAGE OF PEOPLE VACCINATED IN INDIA AT GIVEN DATE USING CTE
WITH CTE_PERCENTAGEPEOPLEVACCINATED_INDIA (location ,date,new_vaccination,population,vaccination_tilldate) AS(
SELECT a.location,a.date,a.new_vaccinations,MAX(b.population) OVER (ORDER BY b.location),
SUM(CONVERT(INT,a.new_vaccinations)) OVER (PARTITION BY a.location ORDER BY a.date) 
AS VACCINATION_TILLDATE FROM INDIANCOLLEGES..CovidVaccinations$ a JOIN INDIANCOLLEGES..CovidDeaths$ b 
ON a.location=b.location AND a.date=b.date_converted
WHERE b.continent is not NULL)
SELECT location,date,(vaccination_tilldate/population)*100 AS PERCENTPOPULATION_VACCINATED FROM CTE_PERCENTAGEPEOPLEVACCINATED WHERE location='India'


--PERCENTAGE OF PEOPLE VACCINATED ALL OVER THE WORLD AT GIVEN DATE USING CTE
WITH CTE_PERCENTAGEPEOPLEVACCINATED (location ,date,new_vaccination,population,vaccination_tilldate) AS(
SELECT a.location,a.date,a.new_vaccinations,MAX(b.population) OVER (ORDER BY b.location),
SUM(CONVERT(INT,a.new_vaccinations)) OVER (PARTITION BY a.location ORDER BY a.date) 
AS VACCINATION_TILLDATE FROM INDIANCOLLEGES..CovidVaccinations$ a JOIN INDIANCOLLEGES..CovidDeaths$ b 
ON a.location=b.location AND a.date=b.date_converted
WHERE b.continent is not NULL)
SELECT location,date,(vaccination_tilldate/population)*100 AS PERCENTPOPULATION_VACCINATED FROM CTE_PERCENTAGEPEOPLEVACCINATED 

--MAKING A TEMP TABLE TO STORE THIS DATA

DROP TABLE IF EXISTS #PERCENTPOPULATIONVACCINATED
CREATE TABLE #PERCENTPOPULATIONVACCINATED
(location nvarchar(255) ,
date datetime,
new_vaccination numeric,
population numeric,
vaccination_tilldate numeric)

INSERT INTO #PERCENTPOPULATIONVACCINATED
SELECT a.location,a.date,a.new_vaccinations,MAX(b.population) OVER (ORDER BY b.location),
SUM(CONVERT(INT,a.new_vaccinations)) OVER (PARTITION BY a.location ORDER BY a.date) 
AS VACCINATION_TILLDATE FROM INDIANCOLLEGES..CovidVaccinations$ a JOIN INDIANCOLLEGES..CovidDeaths$ b 
ON a.location=b.location AND a.date=b.date_converted
WHERE b.continent is not NULL

SELECT * FROM #PERCENTPOPULATIONVACCINATED