/********************************************************************************************
Question 1: 
Get the number of orders by the Type of Transaction 
excluding the orders shipped from Sangli and Srinagar. Also, 
exclude the SUSPECTED_FRAUD cases based on the Order Status, and 
sort the result in the descending order based on the number of orders.

•Input: Orders table (Order_Id, Type, Order_City, Order_Status)
•Expected output: Type of Transaction | Orders (Sorted in the descending order of Orders)

Algorithm:
• Step 1: Filter out ‘Sangli’ and ‘Srinagar’ from the city column of the data.
• Step 2: Filter out ‘SUSPECTED_FRAUD ’ from the order_status column of the data.
• Step 3: Aggregation – COUNT(order_id), GROUP BY Transaction_type
• Step 4: Sort the result in the descending order of Orders
*********************************************************************************************/

USE supply_db;

SELECT Type as Type_of_Transaction, COUNT(Order_Id) as Orders
FROM Orders
WHERE Order_City != "Sangli" AND Order_City !=  "Srinagar" AND Order_Status <> "SUSPECTED_FRAUD" 
GROUP BY Type
ORDER BY COUNT(Order_Id) DESC;


/******************************************************************************************************************************
Question 2
Get the list of the Top 3 customers based on the completed orders along with the following details:
Customer Id
Customer First Name
Customer City
Customer State
Number of completed orders
Total Sales

• Input: Orders table (Order_Id and Order_Status), Ordered_items table (Sales), Customer_info table (Id, First_Name, City, State)
• Expected output: Customer Id | Customer First Name | Customer City | Customer State | Completed orders | Total Sales

Algorithm:
• Step 1: Join orders and order_items to get order_id level sales.
• Step 2: Filter out ‘COMPLETE’ orders from the order_status column of the orders table.
• Step 3: Join the result from Step 2 with the Customers table and create a customer id level summary.
• Step 4: Apply Aggregation – COUNT(order_id), SUM(Sales)  and GROUP BY Customer Id, Customer First Name, Customer City and Customer State.
*************************************************************************************************************************************************/

SELECT  Id AS Customer_Id,
		First_Name AS Customer_First_Name,
        City AS Customer_City,
        State AS Customer_State,
        COUNT(DISTINCT o.Order_Id) AS Number_of_completed_orders,
        SUM(Sales) AS Total_Sales
        
FROM customer_info as ci
	INNER JOIN orders AS o
		ON ci.Id = o.Customer_Id
	INNER JOIN ordered_items AS oi
		ON oi.Order_Id = o.Order_Id

WHERE o.Order_Status = "Complete"

GROUP BY Customer_Id,
		 Customer_First_Name,		
         Customer_City
         
ORDER BY Number_of_completed_orders DESC,
		 Total_Sales DESC
LIMIT 3;


/**********************************************************************************************************************************
Question 3:
“Get the order count by the Shipping Mode and the Department Name. Consider departments 
with at least 40 closed/completed orders.”

• Input: orders (order_id, Shipping_Mode and Order_Status) ordered_items, product_info, department (name)
• Expected output: Shipping Mode | Department Name | Orders (Retain departments with at least 40 closed/completed orders)

Algorithm:
• Step 1: Join orders, ordered_items, product_info and department to get all the departments and orders associated with them
• Step 2: Filter out ‘COMPLETE’ and ‘CLOSED’ from the order_status column of the orders table.
• Step 3: Apply Aggregation – COUNT(order_id), GROUP BY department name
• Step 4: In the table mentioned in Step 3, filter out COUNT(order_id)>=40
• Step 5: From Step 1, perform aggregation – COUNT(order_id), GROUP BY Shipping mode and department name. 
		  Retain only those department names that were left over after the filter was applied in Step 4.
***********************************************************************************************************************************/


SELECT  shipping_mode,
		d.name AS Department_name,
        COUNT(ord.order_id) AS order_count
FROM orders AS ord
	INNER JOIN ordered_items AS oi
		ON ord.order_id = oi.order_id
	INNER JOIN product_info AS pi
		ON oi.item_id = pi.product_id
	INNER JOIN department AS d
		ON pi.department_id = d.Id
WHERE order_status IN ("complete","closed")
GROUP BY shipping_mode,department_name
HAVING order_count >=40
ORDER BY order_count DESC;
        


/****************************************************************************************************************************
Question 4:
“Create a new field as shipment compliance based on Real_Shipping_Days and Scheduled_Shipping_Days. 
It should have the following values:

Cancelled shipment: If the Order Status is SUSPECTED_FRAUD or CANCELED
Within schedule: If shipped within the scheduled number of days 
On time: If shipped exactly as per schedule
Up to 2 days of delay: If shipped beyond schedule but delayed by 2 day
Beyond 2 days of delay: If shipped beyond schedule with a delay of more than 2 days
Which shipping mode was observed to have the highest number of delayed orders?”

• Input: orders (order_id, Real_Shipping_Days, Scheduled_Shipping_Days and Shipping_Mode)
• Expected output: order_id | shipment_compliance | shipping_mode | Number of delayed orders

Algorithm:
• Step 1: Create a shipment compliance column based on the given criteria.
• Step 2: Test and confirm if all the cases are handled. Check for null values too.
• Step 3: Filter out the delayed orders only.
• Step 4: Apply Aggregation – COUNT(order_id), GROUP BY shipping mode and sort in descending order of order count and 
		  retain the top-most row.
**************************************************************************************************************************/

WITH shipping_summary AS
(
SELECT  DISTINCT order_id,
		Real_Shipping_Days, 
        Scheduled_Shipping_Days, 
        Shipping_Mode, 
        order_status,

CASE 
	WHEN order_status = 'SUSPECTED_FRAUD' OR order_status = 'CANCELED' THEN 'Cancelled shipment'
	WHEN Real_Shipping_Days<Scheduled_Shipping_Days THEN 'Within schedule'
	WHEN Real_Shipping_Days=Scheduled_Shipping_Days THEN 'On Time'
	WHEN Real_Shipping_Days<=Scheduled_Shipping_Days+2 THEN 'Upto 2 days of delay'
	WHEN Real_Shipping_Days>Scheduled_Shipping_Days+2 THEN 'Beyond 2 days of delay'
ELSE 'Others' 
END AS shipment_compliance

FROM
orders)

SELECT 	order_id,
		shipment_compliance,
		Shipping_mode,
		COUNT(order_id) AS Number_of_delayed_orders
FROM shipping_summary
WHERE shipment_compliance IN ("Upto 2 days of delay","Beyond 2 days of delay")
GROUP BY Shipping_Mode
ORDER BY Number_of_delayed_orders DESC;


/****************************************************************************************************************************
Question 5:
“An order is canceled when the status of the order is either CANCELED or SUSPECTED_FRAUD. 
Obtain the list of states by the order cancellation% and sort them in the descending order of the cancellation%.

Definition: Cancellation% = Cancelled order / Total orders”

• Input: Orders (Order_Id, Order_State and Order_Status)
• Expected output: Order State | Cancellation % (Sort in the descending order of cancellation%)

Algorithm:
• Step 1: Filter out ‘CANCELED’ and ‘SUSPECTED_FRAUD’ from the order_status column of the orders table.
• Step 2: From the result of Step 1, perform aggregation – COUNT(order_id), GROUP BY Order_State.
• Step 3: Create separate aggregation of the orders table to get the total orders - COUNT(order_id), GROUP BY Order_State.
• Step 4: Join the results of Step 2 and Step 3 on Order_State.
• Step 5: Create a new column with the calculation of Cancellation percentage = Cancelled Orders / Total Orders.
• Step 6: Sort the final table in the descending order of Cancellation percentage.
**************************************************************************************************************************/

WITH cancelled_orders_summary AS
(
SELECT
Order_State, 
COUNT(order_id) as cancelled_orders
FROM Orders
WHERE order_status='CANCELED' OR order_status='SUSPECTED_FRAUD'
GROUP BY Order_State

),
total_orders_summary AS
(
SELECT
Order_State, 
COUNT(order_id) as total_orders
FROM Orders
GROUP BY Order_State
)
SELECT 	t.order_state,
		cancelled_orders, 
        total_orders,
        ROUND((COALESCE(c.cancelled_orders,0)/ t.total_orders)*100,2) AS Cancellation_perc
        
        -- Coalesce function is used to handle the Null values. 
        -- The null values are replaced with user-defined values during the expression evaluation process
FROM 
cancelled_orders_summary as c
RIGHT JOIN
total_orders_summary as t
ON c.Order_State=t.Order_state
ORDER BY Cancellation_perc DESC;





