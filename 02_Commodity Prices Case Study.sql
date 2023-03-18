/**************************************************************************************************************
Question 1: Get the common commodities between the top 10 costliest commodities of 2019 and 2020.

• Input: price_details: Id, Commodity_Id, Date, Retail_Price, commodities_info: Id, Commodity
• Expected output: Commodity; Take distinct to remove duplicates

***************************************************************************************************************/

USE commodity_db;

WITH year1_summary AS
(
SELECT 
commodity_id, 
MAX(retail_price) as price
FROM price_details
WHERE YEAR(date)=2019
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10
),
year2_summary AS
(
SELECT 
commodity_id, 
MAX(retail_price) as price
FROM price_details
WHERE YEAR(date)=2020
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10
),
common_commodities AS
(
SELECT y1.commodity_id
FROM 
year1_summary AS y1
INNER JOIN
year2_summary AS y2
ON y1.commodity_id=y2.commodity_id
)
SELECT DISTINCT ci.commodity AS common_commodity_list
FROM
common_commodities as cc
INNER JOIN
commodities_info as ci
ON cc.commodity_id=ci.id;


/*********************************************************************************************************************************
Question 2: What is the maximum difference between the prices of a commodity at one place vs the other for the month of Jun 2020?
Which commodity was it for?

• Input: price_details: Id, Region_Id, Commodity_Id, Date and Retail_Price; commodities_info: Id and Commodity
• Expected Output: Commodity | price difference; Retain the info for highest difference

Algorithm: 
• Step 1: Filter Jun 2020 in Date column of price_details
• Step 2: Aggregation - MIN(retail_ price), MAX(retail_price) group by commodity
• Step 3: Compute the difference between the Max and Min retail price
• Step 4: Sort in descending order of price difference; Retain the top most row
*****************************************************************************************************************************/

WITH June_prices AS 
(
SELECT  Commodity_Id, 
		MIN(Retail_price) AS Min_price,
        MAX(Retail_price) AS Max_price 
FROM price_details
WHERE date BETWEEN "2020-06-01" AND "2020-06-30"
GROUP BY Commodity_Id
)
SELECT  ci.commodity,
		Max_price-Min_price AS price_difference
FROM june_prices AS jp
	INNER JOIN commodities_info AS ci
		ON jp.commodity_id=ci.id
ORDER BY price_difference DESC
LIMIT 1;  

-- OR 

SELECT  Commodity, 
		MIN(Retail_price) AS Min_price,
        MAX(Retail_price) AS Max_price,
        MAX(Retail_price)-MIN(Retail_price) AS price_difference
FROM price_details AS pd
	INNER JOIN commodities_info AS ci
		ON pd.commodity_id=ci.id
WHERE date BETWEEN "2020-06-01" AND "2020-06-30"
GROUP BY Commodity_Id
ORDER BY price_difference DESC;

/*****************************************************************************************************************************
Question 3:
Arrange the commodities in order based on the number of varieties in which they are available, with the highest one shown at the top. 
Which is the 3rd commodity in the list?

• Input: commodities_info: Commodity and Variety
• Expected Output: Commodity | Variety count; Sort in descending order of Variety count

Algorithm:
• Step 1: Aggregation - COUNT(DISTINCT variety), group by Commodity
• Step 2: Sort the final table in descending order of Variety count
*************************************************************************************************************************/

SELECT  Commodity,
		COUNT(DISTINCT Variety) AS Number_Variety
FROM commodities_info
GROUP BY Commodity 
ORDER BY Number_Variety DESC,Commodity
LIMIT 10;


/****************************************************************************************************************************
Question 4: In the state with the least number of data points available.
Which commodity has the highest number of data points available?

• Input: price details: Id, region_id, commodity_id region info: Id and State commodities info: Id and Commodity 
• Expected Output: commodity; Expecting only one value as output

Algorithm:
• Step 1: Join region info and price details using the Region_Id from price _details with Id from region_info
• Step 2: From result of Step 1, perform aggregation - COUNT(Id), group by State;
• Step 3: Sort the result based on the record count computed in Step 2 in ascending order; Filter for the top
State
• Step 4: Filter for the state identified from Step 3 from the price details table 
• Step 5: Aggregation - COUNT(Id), group by commodity_id; 
		  Sort in descending order of count 
• Step 6: Filter for top 1 value and join with commodities_info to get the commodity name
**************************************************************************************************************************/

WITH raw_data AS
(
SELECT 
pd.id, pd.commodity_id, ri.state
FROM
price_details as pd
LEFT JOIN
region_info as ri
ON pd.region_id = ri.id
),
state_rec_count AS
(
SELECT state, 
COUNT(id) as state_wise_datapoints
FROM raw_data
GROUP BY state
ORDER BY state_wise_datapoints
LIMIT 1
),
commodity_list AS
(
SELECT 
commodity_id,
COUNT(id) AS record_count
FROM 
raw_data
WHERE state IN (SELECT DISTINCT state FROM state_rec_count)
GROUP BY commodity_id
ORDER BY record_count DESC
)
SELECT 
commodity,
SUM(record_count) AS record_count
FROM
commodity_list AS cl
LEFT JOIN
commodities_info AS ci
ON cl.commodity_id = ci.id
GROUP BY commodity
ORDER BY record_count DESC
LIMIT 1;

/**************************************************************************************************************************
Question 5: What is the price variation of commodities for each city from Jan 2019 to Dec 2020. 
			Which commodity has seen the highest price variation and in which city?
            
• Input: price_details: Id, region_id, commodity_id, date region_info: Id and City commodities_info: Id and Commodity
• Expected output: Commodity | city | Start Price | End Price | Variation absolute | Variation Percentage;  Sort in descending order of variation %     

Algorithm : 
• Step 1: Filter for January 2019 from the Date column of the price_details table.
• Step 2: Filter for December 2020 from the Date column of the price_details table. 
		  Firstly, we filtered the price_details data separately for January 2019 and December 2020. 
          Next, we had two tables onto which we could apply queries to find the price difference and variation.
• Step 3: Do an inner join between the results from Step 1 and Step 2 on region_id and commodity id.
• Step 4: Name the price from Step 1 result as Start Price and Step 2 result as End Price.
• Step 5: Calculate variations in absolute and percentage; Sort the final table in descending order of variation percentage. 
		  After obtaining entries for January 2019 and December 2020, we joined the tables and found the price variation. 
          We also did an inner join to avoid any blank entries. Then, sort the final table in descending order of variation to get maximum variation.
• Step 6: Filter for the first record and join with region_info, commodities_info to get city and commodity name. 
		  Then, we LIMITed the records to one entry and joined it with region_info and commodities_info to get the name of the city and commodity.
***************************************************************************************************************************************************************************************************************************************************/

WITH jan_2019_data AS
(
SELECT *
FROM price_details
WHERE date BETWEEN "2019-01-01" AND  "2019-01-31"
),
dec_2020_data AS
(
SELECT *
FROM price_details
WHERE date BETWEEN "2020-12-01" AND  "2020-12-31"
),
price_variation AS
(
SELECT  j.region_id,
		j.commodity_id,
        j.retail_price AS start_price,
        d.retail_price AS end_price,
        d.retail_price - j.retail_price AS variation,
        ROUND(ABS((d.retail_price - j.retail_price)/j.retail_price)*100,2) AS price_variation_percentage
FROM jan_2019_data AS j
	INNER JOIN dec_2020_data AS d
		ON j.region_id = d.region_id
        AND j.commodity_id=d.commodity_id
ORDER BY price_variation_percentage DESC
LIMIT 1)
SELECT  ri.centre AS city,
        ci.Commodity AS commodity_name,
        start_price,
        end_price,
        variation,
        price_variation_percentage
        
FROM price_variation AS pv
INNER JOIN region_info AS ri 
ON ri.id = pv.region_id
INNER JOIN commodities_info AS ci
ON ci.id = pv.commodity_id;
