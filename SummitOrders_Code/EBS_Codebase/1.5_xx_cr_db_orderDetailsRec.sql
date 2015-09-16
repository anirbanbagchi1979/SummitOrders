/*drop TYPE xx_mdx_order_tab;
/

drop TYPE xx_mdx_order_rec;
/

drop type xx_mdx_orderline_tab;
/

drop type xx_mdx_orderline_rec;
/
*/

CREATE TYPE xx_mdx_order_rec as object
(
header_id number,
Order_Number number,
order_Status varchar2(50),
Order_Date date,
Order_Amount number,
order_Currency varchar2(5),
check_number varchar2(50),
credit_card_code varchar2(50),
credit_card_number varchar2(50),
Payment_Type varchar2(25),
payment_account_num varchar2(50),
Sales_Rep varchar2(150),
Customer_ID number,
customer_number varchar2(25),
customer_name varchar2(240),
order_line_count number,
--
customer_address varchar2(1000), 
credit_rating varchar2(50),
customer_comments varchar2(240)
);
/

CREATE TYPE xx_mdx_order_tab AS TABLE OF xx_mdx_order_rec;

/

CREATE TYPE xx_mdx_orderline_rec as object
(header_id number,
line_id number,
item_id number,
line_status varchar2(50),
line_number number,
shipment_number number,
Ship_Date date,
Product_Name varchar2(25),
product_desc varchar2(240),
unit_selling_Price number,
order_Quantity number,
Total_line_Amount number
);
/

CREATE TYPE xx_mdx_orderline_tab AS TABLE OF xx_mdx_orderline_rec;
/

-- 3/12
-- will be used as an input array for APIs

CREATE TYPE xx_mdx_om_input_rec as object
(order_number number,
order_status varchar2(50)
);
/

CREATE TYPE xx_mdx_om_input_tab AS TABLE OF xx_mdx_om_input_rec;
/

--
--

