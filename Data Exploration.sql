/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


select *
from ProfolioProject..covid_deaths
--where continent is not null
where location like '%India%'
order by 3,4;


--Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from ProfolioProject..covid_deaths
where continent is not null
order by 1, 2;


--Total Cases VS Total Deaths
--Shows likelihood of dying if you contract Covid in your country

select location, date, total_cases, total_deaths, (convert (float, total_deaths)/nullif (convert(float, total_cases),0))*100 as DeathPercentage
from ProfolioProject..covid_deaths
where location like '%India%' and continent is not null
order by 1, 2;


--Total cases vs population
--shows what percentage of population got Covid

select location, date,population, total_cases, (convert (float, total_cases)/nullif (convert(float, population),0))*100 as CasePercentage
from ProfolioProject..covid_deaths
where continent is not null
--where location like '%India%'
order by 1, 2;


--Countries with Highest Infection Rate compared to Population

select location,population, max(total_cases) as HighestIntectionCount, max(convert (float, total_cases)/nullif (convert(float, population),0))*100 as PercentPopulationInfected
from ProfolioProject..covid_deaths
--where location like '%India%'
where continent is not null
group by location, population
order by PercentPopulationInfected desc;


--Continents with the highest death count per population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from ProfolioProject..covid_deaths
where continent is not null
group by location
order by TotalDeathCount desc;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from ProfolioProject..covid_deaths
where continent is not null
group by continent
order by TotalDeathCount desc;


-- GLOBAL NUMBERS

--Total cases, total deaths and Death percentage of every countries.

select location, sum(coalesce(new_cases, 0)) AS total_cases, sum(coalesce(new_deaths, 0)) as total_deaths,
case 
when sum(coalesce(new_cases, 0)) = 0 THEN 0
else (sum(coalesce(new_deaths, 0)) * 100.0 / sum(coalesce(new_cases, 0)))
end as DeathPercentage
from ProfolioProject..covid_deaths
where continent IS NOT NULL
group by location
order by DeathPercentage desc;


--Total population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population,
coalesce(cast(vac.new_vaccinations as bigint), 0) as new_vaccinations
,sum(coalesce(cast(vac.new_vaccinations as bigint), 0)) over (partition by dea.location order by 
dea.location,
dea.date) as cumulative_vaccinations
from ProfolioProject..covid_deaths dea
join ProfolioProject..Covid_vaccination vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null --and dea.location like '%India%'
order by 2, 3;


-- Using CTE to perform Calculation on Partition By in previous query

with PopvsVac(continent, location, population,new_vaccinations, cumulative_vaccinations)
as
(
select dea.continent, dea.location, dea.population,
coalesce(cast(vac.new_vaccinations as bigint), 0) as new_vaccinations
,sum(coalesce(cast(vac.new_vaccinations as bigint), 0)) over (partition by dea.location order by 
dea.location,
dea.date) as cumulative_vaccinations
from ProfolioProject..covid_deaths dea
join ProfolioProject..Covid_vaccination vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null --and dea.location like '%India%'
)
select *, round((cumulative_vaccinations/population)*100,2) as vaccination_percentage
from PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

Drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population,
coalesce(cast(vac.new_vaccinations as bigint), 0) as new_vaccinations
,sum(coalesce(cast(vac.new_vaccinations as bigint), 0)) over (partition by dea.location order by 
dea.location,
dea.date) as cumulative_vaccinations
from ProfolioProject..covid_deaths dea
join ProfolioProject..Covid_vaccination vac
  on dea.location = vac.location
  and dea.date = vac.date
--where dea.continent is not null --and dea.location like '%India%'

select *, (cumulative_vaccinations/population)*100 as vaccination_percentage
from #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

create view
PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population,
coalesce(cast(vac.new_vaccinations as bigint), 0) as new_vaccinations
,sum(coalesce(cast(vac.new_vaccinations as bigint), 0)) over (partition by dea.location order by 
dea.location,
dea.date) as cumulative_vaccinations
from ProfolioProject..covid_deaths dea
join ProfolioProject..Covid_vaccination vac
  on dea.location = vac.location
  and dea.date = vac.date
where dea.continent is not null --and dea.location like '%India%'
