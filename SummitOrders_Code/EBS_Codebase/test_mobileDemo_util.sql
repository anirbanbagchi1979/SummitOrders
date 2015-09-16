DECLARE

 l_return_status varchar(240);
 l_return_message varchar(240);
      
  i NUMBER := 0;
  j NUMBER := 0;      
      
   l_hdr xx_ql_order_tab;
   l_lines xx_ql_line_tab;   
   l_order_number  NUMBER:=0;
   
  l_org number := 204; -- Org ID
  l_user number := 1318; -- User ID
  l_resp number := 21623; -- Resp ID
  l_appl number := 660; -- ONT   

BEGIN

  fnd_global.apps_initialize (l_user,l_resp,l_appl);  -- user ID, responsibility ID, application ID 
  mo_global.set_policy_context('S', 204); -- Vision Operations (USA)  
  mo_global.init ('ONT'); 

 l_hdr := xx_ql_order_tab();
 l_hdr.EXTEND;
 
 l_hdr(1) := xx_ql_order_rec (customer_id => 1003, --	United Parcel Service (UPS)
  cust_po_number => TO_CHAR(SYSDATE,'DDMMYYYYHH24MISS')
  );
       

 l_lines := xx_ql_line_tab();
 l_lines.EXTEND;         
         
           
  l_lines(1) := xx_ql_line_rec (
    inventory_item_id => 12031, -- XP9007 Bicycle
    order_quantity => 1); 
    
 l_lines.EXTEND;      
    
  l_lines(2) := xx_ql_line_rec (
    inventory_item_id => 2157,--AS92888 Gloves    
    order_quantity => 1);     
    

 -- dbms_output.put_line('Hdr count= '||l_bom_hdr.COUNT);
 -- dbms_output.put_line('Line count= '||l_bom_lines.COUNT);

  xx_mobileDemo_util3.create_order 
  (p_order_header => l_hdr, 
   p_order_lines => l_lines,
   x_order_number => l_order_number,
   x_return_status => l_return_status, x_return_message => l_return_message);

  dbms_output.put_line('l_return_status '||l_return_status);
  dbms_output.put_line('l_return_message '||l_return_message);
  dbms_output.put_line('l_order_number '||l_order_number);  
  
  COMMIT;

END;
/