create or replace FUNCTION get_upload_image_embedding(p_session_id IN VARCHAR2)
RETURN VECTOR
IS
    l_blob BLOB;
BEGIN
    IF p_session_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT image_blob INTO l_blob
    FROM image_search_temp
    WHERE session_id = p_session_id
    AND created_on = (SELECT MAX(created_on) FROM image_search_temp WHERE session_id = p_session_id);

    RETURN get_image_embedding(l_blob);
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
    WHEN OTHERS THEN RETURN NULL;
END;
/