create or replace PROCEDURE store_selected_category(
    p_session_id VARCHAR2,
    p_category   VARCHAR2
) AS
BEGIN
    MERGE INTO fashion_selected_image t
    USING DUAL
    ON (t.session_id = p_session_id)
    WHEN MATCHED THEN
        UPDATE SET t.selected_category = p_category,
                   t.selected_at = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
        INSERT (session_id, product_id, selected_category)
        VALUES (p_session_id, NULL, p_category);
END;
/