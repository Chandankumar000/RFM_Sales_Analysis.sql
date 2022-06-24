/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
  FROM [PortfolioProject].[dbo].[sales_data_sample]

  -- firstly delete unwanted row from dataset

DELETE FROM sales_data_sample WHERE PRODUCTLINE ='' OR PRODUCTLINE IS NULL;


--CHecking unique values
select distinct status from sales_data_sample --Nice one to plot
select distinct year_id from sales_data_sample
select distinct PRODUCTLINE from sales_data_sample ---Nice to plot
select distinct COUNTRY from sales_data_sample ---Nice to plot
select distinct DEALSIZE from sales_data_sample ---Nice to plot
select distinct TERRITORY from sales_data_sample ---Nice to plot





---ANALYSIS
----Let's start by grouping sales by productline

select PRODUCTLINE, round(sum(sales),0) as Revenue
from [sales_data_sample]
group by PRODUCTLINE
order by 2 desc

-- Sales across the year
select year_id,round(sum(sales),0) as Revenue
from sales_data_sample
group by year_id
order by 2 desc;

-- Sales across Dealsize
select  DEALSIZE, round(sum(sales),0) as Revenue
from sales_data_sample
group by  DEALSIZE
order by 2 desc

----What was the best month for sales in a specific year? How much was earned that month? 
Select YEAR_ID,MONTH_ID,round(sum(sales),0) as Revenue
from sales_data_sample
where YEAR_ID = 2004
group by year_id,month_id
order by 3 desc



-- --November seems to be the month, what product do they sell in November, Classic I believe
Select PRODUCTLINE ,round(sum(sales),0) Revenue
from sales_data_sample
where Month_id=11 and YEAR_ID = 2004
group by PRODUCTLINE
order by 2 desc ;



----Who is our best customer (this could be best answered with RFM)
/* Recency-Frequency-Monetary (RFM) analysis is a indexing technique that uses past purchase behavior to segment customers.
 Given a table with purchase transaction data, we calculate a score based on 
 how recently the customer purchased, 
 how often they make purchases and 
 how much they spend in dollars on average on each purchase. 
 Using these scores, we can segment our customer list to:

identify our most loyal customers by segmenting one-time buyers from customers with repeat purchases
increase customer retention and lifetime value
increase average order size, etc.
*/
DROP TABLE IF EXISTS #rfm

;with rfm as(
select CUSTOMERNAME ,
		round(avg(sales),0) as avg_sales, 
		count(ordernumber) as count_order,
		MAX(ORDERDATE) AS last_order_date ,
		(select max(ORDERDATE) from sales_data_sample) max_order_date , 
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample) ) as Recency
from sales_data_sample
group by CUSTOMERNAME
),
rfm_calc as(
select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by count_order desc) rfm_frequency,
		NTILE(4) OVER (order by avg_sales desc) rfm_monetary
from rfm r

)

Select c.*,
			rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
			cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) as rfm_cell_string
     into #rfm
from rfm_calc c

Select * from #rfm

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141,231,221,214) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144,234,124,224) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331,441,431,314,414) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322,241) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432,324,314) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

-- --What products are most often sold together? 
select * from sales_data_sample where ORDERNUMBER =  10411

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data_sample p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 2
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from sales_data_sample s
order by 2 desc


--What city has the highest number of sales in a specific country

select city, sum (sales) Revenue
from sales_data_sample
where country = 'UK'
group by city
order by 2 desc


---What is the best product in United States?

select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from sales_data_sample
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
