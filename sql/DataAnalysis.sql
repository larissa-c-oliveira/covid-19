--Documenta��o dispon�vel em: https://github.com/owid/covid-19-data/tree/master/public/data

--Importa��o do arquivo dispon�vel em: https://covid.ourworldindata.org/data/owid-covid-data.csv
select top 5 *
from  Portfolio..CovidData 

--Como resultado da importa��o s�o colunas no formato texto, precisamos convert�-las para o tipo correto de dado
alter table Portfolio..CovidData alter column [date]  date
go
alter table Portfolio..CovidData alter column [total_cases]  float
go
alter table Portfolio..CovidData alter column [new_cases]  float
go
alter table Portfolio..CovidData alter column [total_deaths]  float
go
alter table Portfolio..CovidData alter column [new_deaths]  float
go
alter table Portfolio..CovidData alter column [total_tests]  float
go
alter table Portfolio..CovidData alter column [new_tests]  float
go
alter table Portfolio..CovidData alter column [people_vaccinated]  float
go
alter table Portfolio..CovidData alter column [people_fully_vaccinated]  float
go
alter table Portfolio..CovidData alter column [population]  float

--Percentual de mortalidade da mais antiga para a mais recente data
select 
		location, 
		date, 
		total_cases, 
		population, 
		new_cases, 
		total_deaths, 
		([total_deaths] / nullif([total_cases], 0))  as percentage_death
from Portfolio..CovidData 
order by 2 

--Percentual da popula��o que contraiu COVID da mais antiga para a mais recente data
select 
		location, 
		date, 
		total_cases, 
		population, 
		new_cases, 
		total_deaths, 
		(total_cases / [population])  as percentage_cases
from Portfolio..CovidData 
order by 2 

--Ranking dos pa�ses com mais n�mero de casos
select 
		location,
		max(total_cases) as highest_cases
from Portfolio..CovidData 
group by location
order by 2 desc 

--Ranking dos pa�ses com o maior n�mero de casos proporcional a popula��o
select  
		location,
		max(total_cases) / max([population])  as highest_percentage_cases
from Portfolio..CovidData 
group by location
order by 2 desc 

--Ranking dos pa�ses com menor n�mero de casos
select 
		location,
		max(total_cases) as lowest_cases
from Portfolio..CovidData 
group by location
order by 2 asc 

--Ranking dos pa�ses com menor n�mero de casos proporcional a popula��o
select  
		location,
		max(total_cases) / max([population])  as lowest_percentage_cases
from Portfolio..CovidData 
group by location
order by 2 asc 

--Mantendo somente dados de pa�ses 
delete 
from Portfolio..CovidData 
where len(continent) = 0

--Removendo pa�ses que n�o tiveram nenhum caso.
delete a
from		Portfolio..CovidData a
inner join 
			(
				select 
						location,
						max(total_cases) as max_cases
				from Portfolio..CovidData 
				group by location
			)					b	on a.location = b.location
where b.max_cases = 0

--Visualizando o total de casos por continente
with tbl as
(
		select 
				continent, 
				location,
				max(total_cases) as tot
		from Portfolio..CovidData
		group by 
				continent, 
				location
)
select
		tbl.continent,
		sum(tbl.tot)
from tbl
group by tbl.continent
order by 2 desc

--Total de novos casos por m�s e ano
select
		format([date], 'yyyy-MM')	as year_month,
		sum(new_cases)				as over_month_cases
from Portfolio..CovidData
group by format([date], 'yyyy-MM')
order by 2 desc

--Total de mortes por m�s e ano
select
		format([date], 'yyyy-MM')	as year_month,
		sum(new_deaths)				as over_month_deaths
from Portfolio..CovidData
group by format([date], 'yyyy-MM')
order by 2 desc;

--Taxa de crescimento por m�s e ano
with tbl as
(
	select
			format([date], 'yyyy-MM')	as year_month,
			sum(new_cases)				as over_month_cases
	from Portfolio..CovidData
	group by format([date], 'yyyy-MM')		
)
select
		year_month,
		over_month_cases,
		over_month_cases - lag(over_month_cases) over (order by year_month asc) as cases_growth,
		(over_month_cases - lag(over_month_cases) over (order by year_month asc))/(lag(over_month_cases) over (order by year_month asc))
																				as percentage_cases_growth
from tbl 


--Outliers pelo percentual da popula��o infectada
with tbl as (
select 
		location, 
		(max(total_cases) / max([population])) as full_total_cases
from Portfolio..CovidData
group by location
)
select
		location,
		full_total_cases,
		ntile(4) over (order by full_total_cases)	as total_cases_quartile
from tbl

--Cria��o da view para alimenta��o do Power BI
use Portfolio
go
create view vwCovidData as
select 
		iso_code,
		continent,
		location, 
		date, 
		total_cases, 
		population, 
		new_cases, 
		total_deaths, 
		new_deaths
from Portfolio..CovidData 


		