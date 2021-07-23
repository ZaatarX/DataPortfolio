--Selecting the data I'll be using
SELECT
    [location],
    [date],
    [total_cases],
    [new_cases],
    [total_deaths],
    [population]
FROM
    ['Covid-Deaths$']
ORDER BY
    1,
    2;

--Total Cases vs Total Deaths
SELECT
    [location],
    [date],
    [total_cases],
    [total_deaths],
    ROUND((total_deaths / total_cases) * 100, 2) AS DeathRate
FROM
    ['Covid-Deaths$']
ORDER BY
    1,
    2;

--Likelyhood of dying in Brazil
SELECT
    [location],
    [date],
    [total_cases],
    [total_deaths],
    ROUND((total_deaths / total_cases) * 100, 2) AS DeathRate
FROM
    ['Covid-Deaths$']
WHERE
    [location] = 'Brazil'
ORDER BY
    1,
    2;

--How far has covid spread out in Brazil?
SELECT
    [location],
    [date],
    population,
    total_cases,
    ROUND((total_cases / population) * 100, 2) AS InfectionRate
FROM
    ['Covid-Deaths$']
WHERE
    [location] = 'Brazil';

-- Which country has the highest infecction rate?
SELECT
    [location],
    population,
    ROUND(MAX((total_cases / population)) * 100, 2) AS InfectionRate
FROM
    ['Covid-Deaths$']
GROUP BY
    [location],
    population
ORDER BY
    3 DESC;

----------------------- --
--                      --
--CONTINENTS DRILL DOWN --
--                      --
----------------------- --
-- How are each continent doing so far?
SELECT
    [location],
    MAX(CAST(total_deaths AS int)) AS TotalCount
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NULL
GROUP BY
    [location]
ORDER BY
    TotalCount DESC;

--Deathrate by Continent per population
SELECT
    [location],
    ROUND(MAX(total_deaths / population) * 100, 2) AS DeathRate
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NOT NULL
GROUP BY
    [location]
ORDER BY
    2 DESC;

--Likelyhood of dying in each continent if you catch Covid as per the latest date
SELECT
    [location],
    MAX([date]) as LastestDate,
    MAX(ROUND((total_deaths / total_cases) * 100, 2)) AS DeathRate
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NULL
GROUP BY
    [location]
ORDER BY
    3 DESC;

--How far has covid spread out in each continent?
SELECT
    [location],
    MAX(total_cases) AS TotalCases,
    MAX(ROUND((total_cases / population) * 100, 2)) AS InfectionRate
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NULL
GROUP BY
    [location]
ORDER BY
    3 DESC;

----------------------- --
--                      --
--  GLOBAL DRILL DOWN   --
--                      --
----------------------- --
-- Global death rate per day
SELECT
    [date],
    SUM(new_cases) AS TotalCases,
    SUM(CAST(new_deaths AS int)) AS TotalDeaths,
    SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathRate
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NOT NULL
GROUP BY
    [date]
ORDER BY
    1 DESC;

-- Global total
SELECT
    SUM(new_cases) AS TotalCases,
    SUM(CAST(new_deaths AS int)) AS TotalDeaths,
    SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathRate
FROM
    ['Covid-Deaths$']
WHERE
    continent IS NOT NULL
ORDER BY
    1,
    2 DESC;

----------------------- --
--                      --
--     JOIN TABLES      --
--                      --
----------------------- --
--First join; simple select all
SELECT
    *
FROM
    ['Covid-Deaths$'] dt
    JOIN ['Covid-Vacc$'] vac ON dt.[location] = vac.[location]
    AND dt.[date] = vac.[date];

-- Population vs Vaccination per day
SELECT
    dt.continent,
    dt.[location],
    dt.[date],
    dt.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS int)) OVER (
        PARTITION BY dt.[location]
        ORDER BY
            dt.[location],
            dt.[date]
    ) AS TotalVaccinatedByDay
FROM
    ['Covid-Deaths$'] dt
    JOIN ['Covid-Vacc$'] vac ON dt.[location] = vac.[location]
    AND dt.[date] = vac.[date]
WHERE
    dt.continent IS NOT NULL
ORDER BY
    2,
    3 DESC;

-- Rate of vaccinated population by country using CTE
WITH PopByVacc (
    continent,
    location,
    date,
    population,
    vaccination,
    TotalVaccinatedByDay
) AS (
    SELECT
        dt.continent,
        dt.[location],
        dt.[date],
        dt.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS int)) OVER (
            PARTITION BY dt.[location]
            ORDER BY
                dt.[location],
                dt.[date]
        ) AS TotalVaccinatedByDay
    FROM
        ['Covid-Deaths$'] dt
        JOIN ['Covid-Vacc$'] vac ON dt.[location] = vac.[location]
        AND dt.[date] = vac.[date]
    WHERE
        dt.continent IS NOT NULL
)
SELECT
    *,
    (TotalVaccinatedByDay / population) * 100
FROM
    PopByVacc;

-- Rate of vaccinated population by country using Temporary Table
-- Creating the table
DROP TABLE IF EXISTS #PercentPopVacc
CREATE TABLE #PercentPopVacc(
continet nvarchar(255),
location nvarchar(255),
date DATETIME,
population NUMERIC,
vaccination NUMERIC,
TotalVaccinatedByDay NUMERIC
);

-- Inserting the selected data from my join tables
INSERT INTO
    #PercentPopVacc SELECT
    dt.continent,
    dt.[location],
    dt.[date],
    dt.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS int)) OVER (
        PARTITION BY dt.[location]
        ORDER BY
            dt.[location],
            dt.[date]
    ) AS TotalVaccinatedByDay
FROM
    ['Covid-Deaths$'] dt
    JOIN ['Covid-Vacc$'] vac ON dt.[location] = vac.[location]
    AND dt.[date] = vac.[date]
WHERE
    dt.continent IS NOT NULL;

-- Selecting the data
SELECT
    *,
    (TotalVaccinatedByDay / population) * 100
FROM
    #PercentPopVacc
ORDER BY
    1 DESC;

----------------------- --
--                      --
--    CREATING VIEWS    --
--                      --
----------------------- --
-- Creating a view for the last query
GO
    CREATE VIEW PercentPopVacc AS
SELECT
    dt.continent,
    dt.[location],
    dt.[date],
    dt.population,
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (
        PARTITION BY dt.[location]
        ORDER BY
            dt.[location],
            dt.[date]
    ) AS TotalVaccinatedByDay
FROM
    ['Covid-Deaths$'] dt
    JOIN ['Covid-Vacc$'] vac ON dt.[location] = vac.[location]
    AND dt.[date] = vac.[date]
WHERE
    dt.continent IS NOT NULL;