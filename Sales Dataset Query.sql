---Inspecting Data
select * from [dbo].[sales_data_sample]

---Checking Unique values
select distinct status from [dbo].[sales_data_sample] ---nice one to plot
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---nice one to plot
select distinct COUNTRY FROM [dbo].[sales_data_sample] ---nice one to plot
SELECT DISTINCT DEALSIZE FROM [dbo].[sales_data_sample] ---nice one to plot
SELECT DISTINCT TERRITORY FROM [dbo].[sales_data_sample] ---nice one to plot


SELECT DISTINCT MONTH_ID from [dbo].[sales_data_sample]
WHERE year_id = 2005

---ANALYSIS
---Let's start by grouping sales by productline

select PRODUCTLINE, sum(sales) revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

select YEAR_ID, sum(sales) revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select DEALSIZE, sum(sales) revenue
from [dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc

---What was the best month for sales in a specific year? how much was earned that month?
select MONTH_ID, sum(sales) revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
WHERE year_id = 2004
group by MONTH_ID
order by 2 desc

---November seems to be the month, what product do they sell in november, classic i believe
select MONTH_ID, sum(sales) revenue, count(ORDERNUMBER) Frequency
from [dbo].[sales_data_sample]
WHERE year_id = 2004 and MONTH_ID = 11  ---CHANGE YEAR TO SEE THE REST
group by MONTH_ID, PRODUCTLINE
order by 3 DESC

---WHO IS OR BEST COSTUMER (this could be the best answer with RFM)
drop table if exists #rfm
;with rfm as 
(
	select CUSTOMERNAME,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonmetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, MAX(ORDERDATE),(select max(ORDERDATE) from [dbo].[sales_data_sample])) recency
	from [portfolioDB].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as 
(
	select r.*,
		NTILE(4) over (order by recency) rfm_recency,
		NTILE(4) over (order by Frequency) rfm_frequency,
		NTILE(4) over (order by MonetaryValue) rfm_monetary
	from rfm r
)
select
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	case
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers' ---lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344) then 'slipping away,cannot lose' ---(big spenders who haven't purchased lately)slipping away
		when rfm_cell_string in (311,411,331) then 'new customers'
		when rfm_cell_string in (222,223,233,322) then 'potential churners'
		when rfm_cell_string in (323,333,321,422,332,432) then 'active'  --(customers who buy oftyen & recently, but at low price points)
		when rfm_cell_string in (433,434,443,444) then 'loyal'
	end rfm_segment

from #rfm


---what products are most often sold together?
--select * from [dbo].[sales_data_sample] where ORDERNUMBER = 10411

select distinct ORDERNUMBER,stuff(

	(select ',' + PRODUCTCODE 
		from [dbo].[sales_data_sample] p
		where ORDERNUMBER in 
			(
				select ORDERNUMBER 
				from (
						select ORDERNUMBER, count(*) rn
						from [portfolioDB].[dbo].[sales_data_sample]
						where STATUS = 'Shipped'
						group by ORDERNUMBER 
					)m
					where rn = 3
			)
			and p.ORDERNUMBER = s.ORDERNUMBER
			for xml path(''))
			
			, 1, 1, '') ProductCodes
		
		FROM [dbo].[sales_data_sample] s
		order by 2 desc
		