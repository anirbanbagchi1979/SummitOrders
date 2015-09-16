/*drop type xx_md_customer_tab;
/

drop type xx_md_customer_rec;
/

drop type xx_md_order_tab;
/

drop type xx_md_order_rec;
/

drop type xx_md_bom_tab;
/

drop type xx_md_bom_rec;
/

DROP type xx_md_orderstats_tab;
/

DROP type xx_md_orderstats_rec;
/

DROP TABLE xx_md_orders;
/
*/

CREATE TYPE xx_md_customer_rec as object
(
customer_id NUMBER,
party_id NUMBER,
customer_category_code varchar2(100),
customer_number varchar2(100), 
customer_name varchar2(240), 
customer_address varchar2(1000), 
city varchar2(150),
state varchar2(100),
country varchar2(25),
order_date_from DATE, 
order_date_to DATE, 
order_count  NUMBER,
-- summary
payment_type varchar2(50),
account_manager varchar2(240),
credit_rating varchar2(50),
comments varchar2(240)
);
/


CREATE TYPE xx_md_customer_tab AS TABLE OF xx_md_customer_rec;
/


---




CREATE TYPE xx_md_order_rec as object
(
customer_id NUMBER,
order_number NUMBER,
order_status varchar2(25),
order_date DATE,
order_total NUMBER,
item_qty_count NUMBER,
item_most_valued VARCHAR2(50),
item_most_valued_desc VARCHAR2(240)
);
/

CREATE TYPE xx_md_order_tab AS TABLE OF xx_md_order_rec;
/

CREATE TYPE xx_md_bom_rec as object
(level_num NUMBER,
bill_item_name varchar2(100),
bill_item_description varchar2(240),
component_item_name  varchar2(100),
component_item_description  varchar2(240)
);
/

CREATE TYPE xx_md_bom_tab AS TABLE OF xx_md_bom_rec;
/

--

CREATE TYPE xx_md_orderstats_rec as object
(customer_id NUMBER,
order_month varchar2(3),
qtr varchar2(15),
year number,
product varchar2(25),
product_description  varchar2(240),
order_count NUMBER
);
/

CREATE TYPE xx_md_orderstats_tab AS TABLE OF xx_md_orderstats_rec;
/

--


CREATE GLOBAL TEMPORARY TABLE xx_md_orders
        (monthh number,
         yearr number,
         customer_id NUMBER,
         product varchar2(25),
         product_description varchar2(240),
         order_count NUMBER)
      ON COMMIT DELETE ROWS;
/

alter table xx_md_orders add qtr varchar2(15);
/
