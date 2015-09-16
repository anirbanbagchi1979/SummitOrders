CREATE OR REPLACE PACKAGE xx_mobileDemo_util2 AS

PROCEDURE get_orders
  (p_active_days IN NUMBER
  ,p_customer_id IN NUMBER
  ,xx_order OUT xx_mdx_order_tab
  ,xx_orderline OUT xx_mdx_orderline_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2);
  
--

PROCEDURE get_order_lines
  (p_order_number IN NUMBER
  ,xx_order OUT xx_mdx_order_tab
  ,xx_orderline OUT xx_mdx_orderline_tab 
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2);
  
END xx_mobileDemo_util2;
/

CREATE OR REPLACE PACKAGE BODY xx_mobileDemo_util2 AS

PROCEDURE get_orders
  (p_active_days IN NUMBER
  ,p_customer_id IN NUMBER
  ,xx_order OUT xx_mdx_order_tab
  ,xx_orderline OUT xx_mdx_orderline_tab 
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS

  l_order_from_date DATE;
  l_order_to_date DATE;
  
  i NUMBER:=0;
  j NUMBER:=0;  
  
  l_order_amount NUMBER;
  l_salesrep_name VARCHAR2(240);
  l_order_line_count NUMBER;
  
  l_payment_type varchar2(25);
  l_payment_account_num varchar2(50);
  
  l_credit_rating  hz_customer_profiles.credit_rating%type;  
  
CURSOR orders (p_order_from_date IN DATE,  p_order_to_date IN DATE) IS
select ooh.header_id,
ooh.Order_Number,
ooh.flow_status_code order_status,
ooh.Ordered_Date order_date,
0 Order_Amount,
ooh.transactional_curr_code order_currency,
ooh.check_number,
DECODE(ooh.payment_type_code,'CREDIT_CARD','Credit Card','CHECK','Check',ooh.payment_type_code) payment_type_code, -- feb 19
DECODE(ooh.payment_type_code,'CREDIT_CARD',ooh.credit_card_number,'CHECK',ooh.check_number) payment_instr_number, -- feb 20
ooh.credit_card_code,
ooh.credit_card_number,
ooh.salesrep_id,
ooh.sold_to_org_id customer_id,
hca.account_number,
0 order_line_count,
hp.party_name customer_name,
(hp.address1||', '||hp.city||', '||hp.state||'. '||hp.postal_code) customer_address
FROM oe_order_headers_all ooh
,hz_cust_accounts_all hca
,hz_parties hp
where 1=1
and ooh.order_category_code= 'ORDER'
and ooh.sold_to_org_id = hca.cust_account_id
and hca.party_id= hp.party_id
and ordered_date between p_order_from_date and p_order_to_date
--and ordered_date between '01-JAN-2012' and '28-FEB-2013'
and ooh.sold_to_org_id = DECODE(p_customer_id,0,ooh.sold_to_org_id,p_customer_id)
--and ooh.order_number = 56007
order by ooh.order_number DESC;

CURSOR lines (p_header_id IN NUMBER) IS
SELECT ool.header_id,
ool.line_id,
ool.inventory_item_id item_id,
ool.flow_status_code line_status,
ool.line_number,
ool.shipment_number,
ool.actual_shipment_date Ship_Date,
itm.segment1 Product_Name,
itm.description product_desc,
ool.unit_selling_Price,
ool.ordered_quantity order_Quantity,
(ool.unit_selling_Price*ool.ordered_quantity) Total_line_Amount
from oe_order_lines_all ool
,mtl_system_items itm
where 1=1
and ool.header_id= p_header_id
and ool.inventory_item_id= itm.inventory_item_id
and ool.ship_from_org_id= itm.organization_id
--and 2=1 Feb 20
Order by ool.line_number, ool.shipment_number;
  
BEGIN

  --SELECT MAX(ordered_date) INTO l_order_to_date
  --FROM oe_order_headers_all where order_category_code= 'ORDER';
  
  
 
  l_order_to_date := SYSDATE;

  SELECT (l_order_to_date - p_active_days) INTO l_order_from_date
  FROM dual;
  
  --
  
        xx_order := xx_mdx_order_tab();
  
        IF xx_order IS NOT NULL THEN
             xx_order.DELETE;
        END IF;
        
        xx_orderline := xx_mdx_orderline_tab();
  
        IF xx_orderline IS NOT NULL THEN
             xx_orderline.DELETE;
        END IF;        
        
        FOR ord IN orders (l_order_from_date, l_order_to_date) LOOP  
        
          BEGIN
          
            l_salesrep_name := NULL;
          
            SELECT name INTO l_salesrep_name
            FROM ra_salesreps_all sls
            WHERE sls.salesrep_id = ord.salesrep_id
            AND ROWNUM < 2;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_salesrep_name := NULL;
          END;  

---
          
          BEGIN
          
            l_order_line_count := 0;
          
            SELECT count(1) INTO l_order_line_count
            FROM oe_order_lines_all ool
            WHERE 1=1
            and ool.header_id= ord.header_id;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_order_line_count := 0;
          END;           
          
---
          
          BEGIN
          
            l_order_amount := 0;
          
            SELECT SUM(ool.unit_selling_Price*ool.ordered_quantity) INTO l_order_amount
            FROM oe_order_lines_all ool
            WHERE 1=1
            and ool.header_id= ord.header_id;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_order_line_count := 0;
          END;    
          
          -- get customer rating
          
          BEGIN
            select NVL(prof.credit_rating,'TBD')
            INTO l_credit_rating
            from hz_customer_profiles prof
            where 1=1
            and site_use_id is null
            and status = 'A'
            and cust_account_id = ord.customer_id;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_credit_rating := 'TBD';
          END;     
          
          -- end Customer rating          
        
          xx_order.EXTEND;
          
          i := i + 1;
          
          xx_order(i) := xx_mdx_order_rec
            (header_id => ord.header_id,
            Order_Number => ord.order_number,
            order_Status => ord.order_status,
            Order_Date => ord.order_date,
            Order_Amount => l_order_amount,
            order_Currency => ord.order_currency,
            check_number => ord.payment_instr_number,--ord.check_number,
            credit_card_code => ord.payment_type_code,
            credit_card_number => ord.credit_card_number,
            Payment_Type => ord.payment_type_code,--l_Payment_Type,
            payment_account_num => ord.payment_instr_number,--l_payment_account_num,
            Sales_Rep => l_salesrep_name,
            Customer_ID => ord.customer_id,
            customer_number => ord.account_number,
            customer_name => ord.customer_name,
            order_line_count => l_order_line_count,
            customer_address =>ord.customer_address,
            credit_rating => l_credit_rating,
            customer_comments => NULL
            );
            
            
            --- Order lines 
            
              FOR ln IN lines (ord.header_id) LOOP
              
                xx_orderline.EXTEND;
          
                j := j + 1;
          
                xx_orderline(j) := xx_mdx_orderline_rec
                  (header_id => ord.header_id,
                  line_id => ln.line_id,
                  item_id => ln.item_id,
                  line_status => ln.line_status,
                  line_number => ln.line_number,
                  shipment_number => ln.shipment_number,
                  Ship_Date => ln.ship_date,
                  Product_Name => ln.product_name,
                  product_desc => ln.product_desc,
                  unit_selling_Price => ln.unit_selling_price,
                  order_Quantity => ln.order_quantity,
                  Total_line_Amount => ln.total_line_amount);
              
              END LOOP; -- end lines
              
            
            
            --- end lines
       
        END LOOP;  -- orders
        
        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE; 

END get_orders;

---

PROCEDURE get_order_lines
  (p_order_number IN NUMBER
  ,xx_order OUT xx_mdx_order_tab
  ,xx_orderline OUT xx_mdx_orderline_tab 
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS

  l_order_from_date DATE;
  l_order_to_date DATE;
  
  i NUMBER:=0;
  j NUMBER:=0;  
  
  l_order_amount NUMBER;
  l_salesrep_name VARCHAR2(240);
  l_order_line_count NUMBER;
  
  l_payment_type varchar2(25);
  l_payment_account_num varchar2(50);
  
  l_credit_rating  hz_customer_profiles.credit_rating%type;  
  
CURSOR orders /*(p_order_from_date IN DATE,  p_order_to_date IN DATE) */ IS
select ooh.header_id,
ooh.Order_Number,
ooh.flow_status_code order_status,
ooh.Ordered_Date order_date,
0 Order_Amount,
ooh.transactional_curr_code order_currency,
ooh.check_number,
DECODE(ooh.payment_type_code,'CREDIT_CARD','Credit Card','CHECK','Check',ooh.payment_type_code) payment_type_code, -- feb 19
DECODE(ooh.payment_type_code,'CREDIT_CARD',ooh.credit_card_number,'CHECK',ooh.check_number) payment_instr_number, -- feb 20
ooh.credit_card_code,
ooh.credit_card_number,
ooh.salesrep_id,
ooh.sold_to_org_id customer_id,
hca.account_number,
0 order_line_count,
hp.party_name customer_name,
(hp.address1||', '||hp.city||', '||hp.state||'. '||hp.postal_code) customer_address
FROM oe_order_headers_all ooh
,hz_cust_accounts_all hca
,hz_parties hp
where 1=1
and ooh.order_category_code= 'ORDER'
and ooh.sold_to_org_id = hca.cust_account_id
and hca.party_id= hp.party_id
--and ordered_date between p_order_from_date and p_order_to_date
--and ooh.sold_to_org_id = NVL(p_customer_id,ooh.sold_to_org_id)
and ooh.order_number = p_order_number
order by ooh.order_number;

CURSOR lines (p_header_id IN NUMBER) IS
SELECT ool.header_id,
ool.line_id,
ool.inventory_item_id item_id,
ool.flow_status_code line_status,
ool.line_number,
ool.shipment_number,
ool.actual_shipment_date Ship_Date,
itm.segment1 Product_Name,
itm.description product_desc,
ool.unit_selling_Price,
ool.ordered_quantity order_Quantity,
(ool.unit_selling_Price*ool.ordered_quantity) Total_line_Amount
from oe_order_lines_all ool
,mtl_system_items itm
where 1=1
and ool.header_id= p_header_id
and ool.inventory_item_id= itm.inventory_item_id
and ool.ship_from_org_id= itm.organization_id
Order by ool.line_number, ool.shipment_number;
  
BEGIN

  --SELECT MAX(ordered_date) INTO l_order_to_date
  --FROM oe_order_headers_all where order_category_code= 'ORDER';
  
  --l_order_to_date := SYSDATE;

  --SELECT (l_order_to_date - p_active_days) INTO l_order_from_date
  --FROM dual;
  
  --
  
        xx_order := xx_mdx_order_tab();
  
        IF xx_order IS NOT NULL THEN
             xx_order.DELETE;
        END IF;
        
        xx_orderline := xx_mdx_orderline_tab();
  
        IF xx_orderline IS NOT NULL THEN
             xx_orderline.DELETE;
        END IF;        
        
        FOR ord IN orders /*(l_order_from_date, l_order_to_date)*/ LOOP  
        
          BEGIN
          
            l_salesrep_name := NULL;
          
            SELECT name INTO l_salesrep_name
            FROM ra_salesreps_all sls
            WHERE sls.salesrep_id = ord.salesrep_id
            AND ROWNUM < 2;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_salesrep_name := NULL;
          END;  

---
          
          BEGIN
          
            l_order_line_count := 0;
          
            SELECT count(1) INTO l_order_line_count
            FROM oe_order_lines_all ool
            WHERE 1=1
            and ool.header_id= ord.header_id;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_order_line_count := 0;
          END;           
          
---
          
          BEGIN
          
            l_order_amount := 0;
          
            SELECT SUM(ool.unit_selling_Price*ool.ordered_quantity) INTO l_order_amount
            FROM oe_order_lines_all ool
            WHERE 1=1
            and ool.header_id= ord.header_id;
          
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_order_line_count := 0;
          END;   
          
          -- get customer rating
          
          BEGIN
            select NVL(prof.credit_rating,'TBD')
            INTO l_credit_rating
            from hz_customer_profiles prof
            where 1=1
            and site_use_id is null
            and status = 'A'
            and cust_account_id = ord.customer_id;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_credit_rating := 'TBD';
          END;     
          
          -- end Customer rating
        
          xx_order.EXTEND;
          
          i := i + 1;
          
          xx_order(i) := xx_mdx_order_rec
            (header_id => ord.header_id,
            Order_Number => ord.order_number,
            order_Status => ord.order_status,
            Order_Date => ord.order_date,
            Order_Amount => l_order_amount,
            order_Currency => ord.order_currency,
            check_number => ord.check_number,
            credit_card_code => ord.payment_type_code,
            credit_card_number => ord.payment_instr_number,
            Payment_Type => ord.payment_type_code,--l_Payment_Type,
            payment_account_num => ord.payment_instr_number, --l_payment_account_num,
            Sales_Rep => l_salesrep_name,
            Customer_ID => ord.customer_id,
            customer_number => ord.account_number,
            customer_name => ord.customer_name,
            order_line_count => l_order_line_count,
            customer_address =>ord.customer_address,
            credit_rating => l_credit_rating,
            customer_comments => NULL            
            );
            
            
            --- Order lines 
            
              FOR ln IN lines (ord.header_id) LOOP
              
                xx_orderline.EXTEND;
          
                j := j + 1;
          
                xx_orderline(j) := xx_mdx_orderline_rec
                  (header_id => ord.header_id,
                  line_id => ln.line_id,
                  item_id => ln.item_id,
                  line_status => ln.line_status,
                  line_number => ln.line_number,
                  shipment_number => ln.shipment_number,
                  Ship_Date => ln.ship_date,
                  Product_Name => ln.product_name,
                  product_desc => ln.product_desc,
                  unit_selling_Price => ln.unit_selling_price,
                  order_Quantity => ln.order_quantity,
                  Total_line_Amount => ln.total_line_amount);
              
              END LOOP; -- end lines
              
            
            
            --- end lines
       
        END LOOP;  -- orders
        
        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE; 

END get_order_lines;

END xx_mobileDemo_util2;
/

show errors;
/