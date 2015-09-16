--drop type xx_ql_order_tab;
--/

--drop type xx_ql_order_rec;
--/

CREATE TYPE xx_ql_order_rec as object
(
customer_id VARCHAR2(25),
cust_po_number varchar2(25)
);
/

CREATE TYPE xx_ql_order_tab AS TABLE OF xx_ql_order_rec;
/

--drop type xx_ql_line_tab;
--/

--drop type xx_ql_line_rec;
--/

CREATE TYPE xx_ql_line_rec as object
(
inventory_item_id NUMBER,
order_quantity  NUMBER
);
/

CREATE TYPE xx_ql_line_tab AS TABLE OF xx_ql_line_rec;
/