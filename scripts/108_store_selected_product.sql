create or replace PROCEDURE store_selected_product(
  p_session_id IN VARCHAR2,
  p_product_id IN NUMBER
) AS
BEGIN
  MERGE INTO fashion_selected_image tgt
  USING DUAL
  ON (tgt.session_id = p_session_id)
  WHEN MATCHED THEN
    UPDATE SET tgt.product_id = p_product_id
  WHEN NOT MATCHED THEN
    INSERT (session_id, product_id)
    VALUES (p_session_id, p_product_id);
  COMMIT;
END;
/