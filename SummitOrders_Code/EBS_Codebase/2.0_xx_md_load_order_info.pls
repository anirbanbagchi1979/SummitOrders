CREATE OR REPLACE PACKAGE xx_mobileDemo_util AS

PROCEDURE get_active_customers
  (p_active_days IN NUMBER
  ,xx_customer OUT xx_md_customer_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2);
  
---  
  
PROCEDURE get_customer_summary
  (p_active_days IN NUMBER
  ,p_customer_id IN NUMBER
  ,p_order_count IN NUMBER
  ,xx_customer OUT xx_md_customer_tab
  ,xx_customer_orders OUT xx_md_order_tab  
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2); 
  
---  
  
PROCEDURE get_bom
  (p_bill_item_name IN VARCHAR2
  ,xx_bom OUT xx_md_bom_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2);  
  
---

PROCEDURE get_customer_order_stats
  (p_customer_id IN NUMBER
  ,p_from_date IN DATE
  ,p_to_date IN DATE
  ,xx_order_stats OUT xx_md_orderstats_tab  
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2);
 
END xx_mobileDemo_util;
/

CREATE OR REPLACE PACKAGE BODY xx_mobileDemo_util AS


PROCEDURE get_active_customers
  (p_active_days IN NUMBER
  ,xx_customer OUT xx_md_customer_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS

  l_order_from_date DATE;
  l_order_to_date DATE;
  i NUMBER:=0;
  
CURSOR customers (p_order_from_date IN DATE,  p_order_to_date IN DATE) IS
SELECT hca.cust_account_id
,hca.party_id
,hp.party_name
,(hp.address1||', '||hp.city||', '||hp.state||'. '||hp.postal_code) customer_address
,hp.city
,DECODE(hp.state,NULL,hp.province,hp.state) state
,hp.country
,COUNT(1) order_count
from oe_order_headers_all ooh
,hz_cust_accounts_all hca
,hz_parties hp
where 1=1
and ordered_date between p_order_from_date and p_order_to_date
and order_category_code= 'ORDER'
and ooh.sold_to_org_id= hca.cust_account_id
and hca.party_id= hp.party_id
group by hca.cust_account_id
,hca.party_id
,hp.party_name
,(hp.address1||', '||hp.city||', '||hp.state||'. '||hp.postal_code)
,hp.city
,DECODE(hp.state,NULL,hp.province,hp.state)
,hp.country
order by hp.party_name ASC;
  
BEGIN

  --SELECT MAX(ordered_date) INTO l_order_to_date
  --FROM oe_order_headers_all where order_category_code= 'ORDER';
  
  l_order_to_date := SYSDATE;

  -- commented on july 11 2013
  -- let the From date = '01-JAN-2012' or better 31 Dec 2011
  --SELECT (l_order_to_date - p_active_days) INTO l_order_from_date
  --FROM dual;
  --
  
  l_order_from_date := TO_DATE('31-DEC-2011');
  
        xx_customer := xx_md_customer_tab();
  
        IF xx_customer IS NOT NULL THEN
             xx_customer.DELETE;
        END IF;
        
        FOR cu IN customers (l_order_from_date, l_order_to_date) LOOP     
        
          xx_customer.EXTEND;
          
          i := i + 1;
          
          xx_customer(i) := xx_md_customer_rec
            (customer_id => cu.cust_account_id,
            party_id => cu.party_id,
            customer_category_code => NULL,
            customer_number => NULL,
            customer_name => cu.party_name,
            customer_address => cu.customer_address,
            city => cu.city,
            state => cu.state,
            country => cu.country,
            order_date_from => l_order_from_date,
            order_date_to => l_order_to_date,
            order_count  => cu.order_count,
            payment_type => NULL,
            account_manager => NULL,
            credit_rating => NULL,
            comments => NULL
            );
       
        END LOOP;  -- customers
        
        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE; 

END get_active_customers;

---

PROCEDURE get_customer_summary
  (p_active_days IN NUMBER
  ,p_customer_id IN NUMBER
  ,p_order_count IN NUMBER
  ,xx_customer OUT xx_md_customer_tab
  ,xx_customer_orders OUT xx_md_order_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS

  l_order_from_date DATE;
  l_order_to_date DATE;
  i NUMBER:=0;  
  l_credit_rating  hz_customer_profiles.credit_rating%type;
  l_collector_id NUMBER:=0;
  l_account_manager  ar_collectors.name%TYPE;  
 
CURSOR customers IS
SELECT hca.cust_account_id
,hca.account_number
,hca.party_id
,hp.party_name
,(hp.address1||', '||hp.city||', '||hp.state||'. '||hp.postal_code) customer_address
,hp.city
,DECODE(hp.state,NULL,hp.province,hp.state) state
,hp.country
from hz_cust_accounts_all hca
,hz_parties hp
where 1=1
and hca.cust_account_id= p_customer_id
and hca.party_id= hp.party_id;

CURSOR orders (p_order_from_date IN DATE,  p_order_to_date IN DATE) IS
select ooh.order_number
,ooh.header_id
--,DECODE(ooh.flow_status_code,'CLOSED','Closed','Open') order_status
,initcap(ooh.flow_status_code) order_status
,ooh.ordered_date
,SUM(ool.ordered_quantity) item_qty_count
,SUM(ool.unit_selling_price*ool.ordered_quantity) order_total
from oe_order_headers_all ooh
,oe_order_lines_all ool
,mtl_system_items itm
where 1=1
and ooh.order_category_code= 'ORDER'
and ooh.header_id= ool.header_id
and ooh.ordered_date between p_order_from_date and p_order_to_date
and ooh.sold_to_org_id= p_customer_id
and ool.inventory_item_id= itm.inventory_item_id
and ool.ship_from_org_id= itm.organization_id
GROUP BY ooh.order_number
,ooh.header_id
,ooh.flow_status_code
,ooh.ordered_date
ORDER BY ooh.ordered_date DESC;

CURSOR most_val_itm (p_header_id IN NUMBER) IS
select ool.unit_selling_price
,itm.segment1 item_name
,itm.description item_description
from oe_order_lines_all ool
,mtl_system_items itm
where 1=1
and ool.inventory_item_id= itm.inventory_item_id
and ool.ship_from_org_id= itm.organization_id
and ool.header_id= p_header_id
ORDER by ool.unit_selling_price DESC;

-- feb 18
CURSOR get_pay_method IS
select receipt_method_id
from ar_cust_receipt_methods_v 
where 1=1
and primary_flag= 'Y'
and customer_id= p_customer_id--3347 
order by creation_date desc;
-- feb 18

l_item_name mtl_system_items.segment1%type;
l_item_description mtl_system_items.description%type;
l_active_days NUMBER:= 1095; -- set to 3 years/1095 days
l_payment_type varchar2(50);

  
BEGIN

        xx_customer := xx_md_customer_tab();   
        
        FOR cu IN customers LOOP  
        
          -- feb 18
          BEGIN
          
            FOR x IN get_pay_method LOOP            
                SELECT name INTO l_payment_type
                FROM ar_receipt_methods where receipt_method_id= x.receipt_method_id;            
            
              EXIT; -- after the latest occurence
              
            END LOOP; -- get_pay_method
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_payment_type := NULL;
          END;
          -- feb 18          

          BEGIN
            select NVL(prof.credit_rating,'TBD'), collector_id
            INTO l_credit_rating, l_collector_id
            from hz_customer_profiles prof
            where 1=1
            and site_use_id is null
            and status = 'A'
            and cust_account_id = p_customer_id;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_credit_rating := 'TBD';
          END;
          
          
          BEGIN          
           select name INTO l_account_manager
            from ar_collectors 
            where collector_id= l_collector_id;   
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_account_manager := 'TBD';
          END;
        
          xx_customer.EXTEND;
          
          i := i + 1;
          
          xx_customer(i) := xx_md_customer_rec
            (customer_id => p_customer_id,
            party_id => cu.party_id,
            customer_category_code => NULL,
            customer_number => cu.account_number,
            customer_name => cu.party_name,
            customer_address => cu.customer_address,
            city => cu.city,
            state => cu.state,
            country => cu.country,            
            order_date_from => l_order_from_date,
            order_date_to => l_order_to_date,
            order_count  => 0,
            payment_type => l_payment_type,
            account_manager => l_account_manager,
            credit_rating => l_credit_rating,
            comments => NULL
            );
       
        END LOOP;  -- customers
        
--  get last set of orders based on parameter p_order_count
--
 


  SELECT MAX(ordered_date) INTO l_order_to_date
  FROM oe_order_headers_all ooh where order_category_code= 'ORDER'
  AND ooh.sold_to_org_id = p_customer_id;
  
  
  IF p_active_days <= 0 THEN
    SELECT (l_order_to_date - l_active_days) INTO l_order_from_date
    FROM dual;
  ELSE  
    SELECT (l_order_to_date - p_active_days) INTO l_order_from_date
    FROM dual;    
  END IF;
  
  --SELECT MAX(ordered_date) INTO l_order_to_date
  --FROM oe_order_headers_all where order_category_code= 'ORDER';
  
  --l_order_to_date := SYSDATE;

  --SELECT (l_order_to_date - p_active_days) INTO l_order_from_date
  --FROM dual;
  
  --  



        xx_customer_orders := xx_md_order_tab();
  
        IF xx_customer_orders IS NOT NULL THEN
          xx_customer_orders.DELETE;
        END IF;
        
        i := 0;
        
        FOR ord IN orders (l_order_from_date, l_order_to_date) LOOP
        
          xx_customer_orders.EXTEND;
          
          i := i + 1;
          
            FOR im IN most_val_itm (ord.header_id) LOOP            
              l_item_name := im.item_name;
              l_item_description := im.item_description;   
              EXIT; 
            END LOOP; -- item_most_valued
          
          xx_customer_orders(i) := xx_md_order_rec
            (customer_id => p_customer_id,
             order_number => ord.order_number,
             order_status => ord.order_status,
             order_date => ord.ordered_date,
             order_total => ord.order_total,
             item_qty_count => ord.item_qty_count,
             item_most_valued => l_item_name,
             item_most_valued_desc => l_item_description);
             
             l_item_name := NULL;
             l_item_description := NULL;
             
          IF i = p_order_count THEN
            EXIT;
          END IF;  
       
        END LOOP;  -- orders        


        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE;
  
END get_customer_summary;

PROCEDURE get_bom
  (p_bill_item_name IN VARCHAR2
  ,xx_bom OUT xx_md_bom_tab
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS
  
CURSOR bom IS
SELECT level level_num
 ,bomc.bill_item_name
 ,billItm.description bill_description
 ,bomc.component_item_name
 ,itm.description comp_description
FROM apps.bomfg_bom_components bomc
  ,mtl_system_items itm
  ,mtl_system_items billItm
WHERE 1=1
and itm.segment1= bomc.component_item_name
and itm.organization_id= 204
--
and billItm.segment1= bomc.bill_item_name
and billItm.organization_id= 204
start with bill_item_name = p_bill_item_name
connect by prior component_item_name = bill_item_name and level = 1
group by level, bill_item_name, component_item_name, itm.description, billItm.description;

  i NUMBER:=0;
  
BEGIN

        xx_bom := xx_md_bom_tab();
  
        IF xx_bom IS NOT NULL THEN
          xx_bom.DELETE;
        END IF;
        
        i := 0;
        
        FOR bb IN bom LOOP
        
            xx_bom.EXTEND;
          
            i := i + 1;          
         
            xx_bom(i) := xx_md_bom_rec
              (level_num => bb.level_num,
              bill_item_name => bb.bill_item_name,
              bill_item_description => bb.bill_description,
              component_item_name => bb.component_item_name,
              component_item_description => bb.comp_description);
              
        END LOOP; -- end bom loop      

        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE;
    
END get_bom;

--

PROCEDURE get_customer_order_stats
  (p_customer_id IN NUMBER
  ,p_from_date IN DATE
  ,p_to_date IN DATE  
  ,xx_order_stats OUT xx_md_orderstats_tab  
  ,x_return_status OUT VARCHAR2
  ,x_return_message OUT VARCHAR2) IS
  
CURSOR orders IS
  SELECT customer_id
  --,monthh
  ,yearr
  ,product
  ,product_description
  ,qtr
  ,SUM(order_count) order_count
  FROM xx_md_orders
  WHERE 1=1
  --and product = 'AS92888'
  --GROUP BY yearr,qtr, product, product_description,customer_id
  GROUP BY customer_id, yearr, qtr, product, product_description
  order by customer_id, yearr, qtr, product  
  ;

  i  NUMBER:=0;
  l_qtr VARCHAR2(25) := NULL;
  
BEGIN

  DELETE FROM xx_md_orders;

  INSERT INTO xx_md_orders
  (customer_id,monthh,yearr,product,product_description,order_count,qtr)
  SELECT ooh.sold_to_org_id customer_id
  ,TO_CHAR(ooh.ordered_date,'MM')
  ,TO_CHAR(ooh.ordered_date,'YYYY')
  ,itm.segment1 product
  ,itm.description product_description
  ,(ool.ordered_quantity)
  ,DECODE(
  TO_CHAR(ooh.ordered_date,'MM'), 
  1,'Q1',2,'Q1',3,'Q1',
  4,'Q2',5,'Q2',6,'Q2',
  7,'Q3',8,'Q3',9,'Q3',
  10,'Q4',11,'Q4',12,'Q4')      
  FROM oe_order_headers_all ooh
  ,oe_order_lines_all ool
  ,mtl_system_items itm
  WHERE 1=1
  and ooh.order_category_code= 'ORDER'
  and ooh.flow_status_code <> 'CANCELLED' -- added Feb 13 2013
  and ooh.header_id= ool.header_id
  and ooh.ordered_date between p_from_date and p_to_date
  and ooh.sold_to_org_id= p_customer_id
  and ool.inventory_item_id= itm.inventory_item_id
  and ool.ship_from_org_id= itm.organization_id
  ORDER BY ooh.ordered_date;

        xx_order_stats := xx_md_orderstats_tab();
  
        IF xx_order_stats IS NOT NULL THEN
             xx_order_stats.DELETE;
        END IF;
        
        FOR ord IN orders LOOP     
        
          xx_order_stats.EXTEND;
          
          i := i + 1;
          
          /*
          IF ord.monthh IN (1,2,3) THEN
            l_qtr := 'Q1';
          ELSIF ord.monthh IN (4,5,6) THEN
            l_qtr := 'Q2';            
          ELSIF ord.monthh IN (7,8,9) THEN
            l_qtr := 'Q3';     
          ELSIF ord.monthh IN (10,11,12) THEN
            l_qtr := 'Q4';              
          END IF;  
          */
          
          xx_order_stats(i) := xx_md_orderstats_rec
            (customer_id => ord.customer_id,
            order_month => null,
            qtr => ord.qtr,
            year => ord.yearr,
            product => ord.product,
            product_description => ord.product_description,
            order_count => ord.order_count);
            
          --IF i = 5 THEN
            --EXIT;
          --END IF;
       
        END LOOP;  -- orders
        
        x_return_status := 'S';
        x_return_message := 'SUCCESS'; 
        
EXCEPTION
  WHEN OTHERS THEN
    x_return_status := 'E';
    x_return_message := SUBSTR(SQLERRM,1,150);
    RAISE; 
END get_customer_order_stats;

END xx_mobileDemo_util;
/


SHOW ERRORS;
/
