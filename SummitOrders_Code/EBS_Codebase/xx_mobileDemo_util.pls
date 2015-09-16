CREATE OR REPLACE PACKAGE xx_mobileDemo_util3 AS

  PROCEDURE create_order (p_order_header IN xx_ql_order_tab, p_order_lines IN xx_ql_line_tab, 
  x_order_number OUT NUMBER,
  x_return_status OUT VARCHAR2, x_return_message OUT VARCHAR2);
                
  
END xx_mobileDemo_util3;
/


CREATE OR REPLACE PACKAGE BODY xx_mobileDemo_util3 AS
  
  PROCEDURE create_order (p_order_header IN xx_ql_order_tab, p_order_lines IN xx_ql_line_tab, 
  x_order_number OUT NUMBER,
  x_return_status OUT VARCHAR2, x_return_message OUT VARCHAR2) IS 
      
      i                          NUMBER := 0;
      j                          NUMBER := 0;      
      
   l_hdr xx_ql_order_tab;
   l_lines xx_ql_line_tab;   
   
  l_api_version_number NUMBER := 1;
  l_return_status VARCHAR2(2000);
  l_msg_count NUMBER;
  l_msg_data VARCHAR2(2000);
  l_xxstatus VARCHAR2(1000);

  l_debug_level number := 1; -- OM DEBUG LEVEL (MAX 5)
  l_org number := 204; -- Org ID
  l_user number := 1318; -- User ID
  l_resp number := 21623; -- Resp ID
  l_appl number := 660; -- ONT

  l_header_rec oe_order_pub.header_rec_type;
  l_line_tbl oe_order_pub.line_tbl_type;
  l_action_request_tbl oe_order_pub.Request_Tbl_Type;

-- Out

  l_header_rec_out oe_order_pub.header_rec_type;
  l_header_val_rec_out oe_order_pub.header_val_rec_type;
  l_header_adj_tbl_out oe_order_pub.header_adj_tbl_type;
  l_header_adj_val_tbl_out oe_order_pub.header_adj_val_tbl_type;
  l_header_price_att_tbl_out oe_order_pub.header_price_att_tbl_type;
  l_header_adj_att_tbl_out oe_order_pub.header_adj_att_tbl_type;
  l_header_adj_assoc_tbl_out oe_order_pub.header_adj_assoc_tbl_type;
  l_header_scredit_tbl_out oe_order_pub.header_scredit_tbl_type;
  l_header_scredit_val_tbl_out oe_order_pub.header_scredit_val_tbl_type;
  l_line_tbl_out oe_order_pub.line_tbl_type;
  l_line_val_tbl_out oe_order_pub.line_val_tbl_type;
  l_line_adj_tbl_out oe_order_pub.line_adj_tbl_type;
  l_line_adj_val_tbl_out oe_order_pub.line_adj_val_tbl_type;
  l_line_price_att_tbl_out oe_order_pub.line_price_att_tbl_type;
  l_line_adj_att_tbl_out oe_order_pub.line_adj_att_tbl_type;
  l_line_adj_assoc_tbl_out oe_order_pub.line_adj_assoc_tbl_type;
  l_line_scredit_tbl_out oe_order_pub.line_scredit_tbl_type;
  l_line_scredit_val_tbl_out oe_order_pub.line_scredit_val_tbl_type;
  l_lot_serial_tbl_out oe_order_pub.lot_serial_tbl_type;
  l_lot_serial_val_tbl_out oe_order_pub.lot_serial_val_tbl_type;
  l_action_request_tbl_out oe_order_pub.request_tbl_type;
  l_msg_index NUMBER;
  l_data VARCHAR2(2000);
  l_loop_count NUMBER;
  l_debug_file VARCHAR2(200);

-- Book API Variables
  b_return_status VARCHAR2(200);
  b_msg_count NUMBER;
  b_msg_data VARCHAR2(2000);
  
--

  l_customer_id hz_cust_accounts_all.cust_account_id%TYPE:=0;
  l_party_id hz_cust_accounts_all.party_id%TYPE:=0; 
  l_item_id  NUMBER:=0;
  l_list_price  NUMBER:=0;
  l_return_prc_status VARCHAR2(2000);
  l_return_prc_message VARCHAR2(2000);  

BEGIN

 i := 1;
 
 l_hdr := xx_ql_order_tab();
 
 l_hdr := p_order_header;
 
 l_lines := xx_ql_line_tab();
 
 l_lines := p_order_lines;
 
 IF (l_debug_level > 0) THEN
   l_debug_file := OE_DEBUG_PUB.Set_Debug_Mode('FILE');
   oe_debug_pub.initialize;
   oe_debug_pub.setdebuglevel(l_debug_level);
   Oe_Msg_Pub.initialize;
 END IF; 
 
-- Order header

 l_header_rec := oe_order_pub.G_MISS_HEADER_REC;
 l_header_rec.operation := OE_GLOBALS.G_OPR_CREATE; 
 l_header_rec.order_type_id := 1000; -- STANDARD
 
 l_header_rec.sold_to_org_id := l_hdr(i).customer_id;
-- l_header_rec.ship_to_org_id := 1425;
 
 l_header_rec.price_list_id := 1000; -- Corporate
 l_header_rec.pricing_date := SYSDATE;
 l_header_rec.transactional_curr_code := 'USD';
 l_header_rec.flow_status_code := 'ENTERED';
 l_header_rec.cust_po_number := l_hdr(i).cust_po_number;
 l_header_rec.order_source_id := 0; 
 
 -- Book order upon creation
  l_action_request_tbl(1) := oe_order_pub.G_MISS_REQUEST_REC;
  l_action_request_tbl(1).request_type := oe_globals.g_book_order;
  l_action_request_tbl(1).entity_code := oe_globals.g_entity_header; 
 -- end Book order 
 
 
-- Order lines
 
 j := 1;
 
 FOR j IN 1 .. l_lines.COUNT LOOP 

   l_line_tbl(j) := oe_order_pub.G_MISS_LINE_REC;
   l_line_tbl(j).operation := OE_GLOBALS.G_OPR_CREATE;
   
   l_line_tbl(j).inventory_item_id := l_lines(j).inventory_item_id;
   
   l_line_tbl(j).ordered_quantity := l_lines(j).order_quantity;
   --l_line_tbl(j).unit_selling_price := l_lines(j).unit_requested_price;
   --l_line_tbl(j).unit_list_price := l_list_price;
  -- l_line_tbl(j).ship_to_org_id := 1425;
   
   l_line_tbl(j).tax_code := 'Location';
   l_line_tbl(1).shipping_method_code := 'DHL';   -- Jan 16 2013
   --l_line_tbl(j).calculate_price_flag := 'N';   

 END LOOP;

OE_ORDER_PUB.Process_Order
( p_api_version_number => l_api_version_number,
p_header_rec => l_header_rec,
p_line_tbl => l_line_tbl,
p_action_request_tbl => l_action_request_tbl,
--OUT variables
x_header_rec => l_header_rec_out,
x_header_val_rec => l_header_val_rec_out,
x_header_adj_tbl => l_header_adj_tbl_out,
x_header_adj_val_tbl => l_header_adj_val_tbl_out,
x_header_price_att_tbl => l_header_price_att_tbl_out,
x_header_adj_att_tbl => l_header_adj_att_tbl_out,
x_header_adj_assoc_tbl => l_header_adj_assoc_tbl_out,
x_header_scredit_tbl => l_header_scredit_tbl_out,
x_header_scredit_val_tbl => l_header_scredit_val_tbl_out,
x_line_tbl => l_line_tbl_out,
x_line_val_tbl => l_line_val_tbl_out,
x_line_adj_tbl => l_line_adj_tbl_out,
x_line_adj_val_tbl => l_line_adj_val_tbl_out,
x_line_price_att_tbl => l_line_price_att_tbl_out,
x_line_adj_att_tbl => l_line_adj_att_tbl_out,
x_line_adj_assoc_tbl => l_line_adj_assoc_tbl_out,
x_line_scredit_tbl => l_line_scredit_tbl_out,
x_line_scredit_val_tbl => l_line_scredit_val_tbl_out,
x_lot_serial_tbl => l_lot_serial_tbl_out,
x_lot_serial_val_tbl => l_lot_serial_val_tbl_out,
x_action_request_tbl => l_action_request_tbl_out,
x_return_status => l_return_status,
x_msg_count => l_msg_count,
x_msg_data => l_msg_data);

IF l_return_status = FND_API.G_RET_STS_SUCCESS then
  --dbms_output.put_line('Return status is success');
  --dbms_output.put_line('l_debug_level '||l_debug_level);
  x_return_status := 'S';
  x_return_message := 'SUCCESS';
 
  --COMMIT;
 
ELSE
  --dbms_output.put_line('Return status failure'); 
  --ROLLBACK;
  x_return_status := 'E';
  x_return_message := 'FAILURE';  
 
END IF;

IF (l_debug_level > 0) THEN
  dbms_output.put_line('l_return_status ' ||l_return_status);
  dbms_output.put_line('l_msg_data ' ||l_msg_data);
  dbms_output.put_line('l_msg_count '||l_msg_count);
  dbms_output.put_line('Order Number= ' ||l_header_rec_out.order_number);
  dbms_output.put_line('Order Hdr ID= '||l_header_rec_out.header_id);
  dbms_output.put_line('Cust PO Number= '||l_header_rec_out.cust_po_number);
  
  x_order_number := l_header_rec_out.order_number;
  x_return_status := l_return_status;  
  
END IF;

-- Print Error

IF (l_debug_level > 0) THEN

  FOR i IN 1 .. l_msg_count LOOP
    Oe_Msg_Pub.get(
    p_msg_index => i
    ,p_encoded => Fnd_Api.G_FALSE
    ,p_data => l_data
    ,p_msg_index_out => l_msg_index);
    DBMS_OUTPUT.PUT_LINE('Msg ' ||l_data);
    DBMS_OUTPUT.PUT_LINE('Msg index ' ||l_msg_index);
  END LOOP;

END IF;

END create_order;

END xx_mobileDemo_util3;
/

SHOW ERRORS;
/