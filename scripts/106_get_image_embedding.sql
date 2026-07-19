create or replace FUNCTION get_image_embedding(p_image IN BLOB)
RETURN VECTOR
IS
    l_http_req   UTL_HTTP.REQ;
    l_http_resp  UTL_HTTP.RESP;
    l_url        VARCHAR2(200) := 'http://localhost:5001/embed/image';
    l_b64        CLOB;
    l_body       CLOB;
    l_response   CLOB := '';
    l_buffer     VARCHAR2(32767);
    l_raw        RAW(16000);
    l_offset     INTEGER := 1;
    l_amount     INTEGER;
    l_len        INTEGER;
    l_vector     VECTOR;
    l_chunk      VARCHAR2(32767);
    l_clob_len   INTEGER;
    l_clob_off   INTEGER;
    l_read_amt   INTEGER;
BEGIN
    -- Initialize temporary CLOBs
    DBMS_LOB.CREATETEMPORARY(l_b64,  TRUE);
    DBMS_LOB.CREATETEMPORARY(l_body, TRUE);

    l_len := DBMS_LOB.GETLENGTH(p_image);

    -- Convert BLOB to base64 in chunks
    WHILE l_offset <= l_len LOOP
        l_amount := LEAST(11250, l_len - l_offset + 1);
        DBMS_LOB.READ(p_image, l_amount, l_offset, l_raw);
        DBMS_LOB.APPEND(l_b64,
            TO_CLOB(UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(l_raw))));
        l_offset := l_offset + l_amount;
    END LOOP;

    -- Remove newlines
    l_b64 := REPLACE(REPLACE(l_b64, CHR(10), ''), CHR(13), '');

    -- Build JSON body
    DBMS_LOB.APPEND(l_body, TO_CLOB('{"image_base64": "'));
    DBMS_LOB.APPEND(l_body, l_b64);
    DBMS_LOB.APPEND(l_body, TO_CLOB('"}'));

    -- Make HTTP POST
    UTL_HTTP.SET_TRANSFER_TIMEOUT(120);
    l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(l_http_req, 'Transfer-Encoding', 'chunked');

    -- Write body in chunks
    l_clob_len := DBMS_LOB.GETLENGTH(l_body);
    l_clob_off := 1;
    WHILE l_clob_off <= l_clob_len LOOP
        l_read_amt := LEAST(32767, l_clob_len - l_clob_off + 1);
        l_chunk := DBMS_LOB.SUBSTR(l_body, l_read_amt, l_clob_off);
        UTL_HTTP.WRITE_TEXT(l_http_req, l_chunk);
        l_clob_off := l_clob_off + l_read_amt;
    END LOOP;

    -- Get response
    l_http_resp := UTL_HTTP.GET_RESPONSE(l_http_req);
    BEGIN
        LOOP
            UTL_HTTP.READ_TEXT(l_http_resp, l_buffer, 32767);
            l_response := l_response || l_buffer;
        END LOOP;
    EXCEPTION
        WHEN UTL_HTTP.END_OF_BODY THEN
            UTL_HTTP.END_RESPONSE(l_http_resp);
    END;

    -- Cleanup temp CLOBs
    DBMS_LOB.FREETEMPORARY(l_b64);
    DBMS_LOB.FREETEMPORARY(l_body);

    -- Extract embedding array
    l_response := SUBSTR(l_response,
                         INSTR(l_response, '['),
                         INSTR(l_response, ']') - INSTR(l_response, '[') + 1);

    l_vector := TO_VECTOR(l_response);
    RETURN l_vector;

EXCEPTION
    WHEN OTHERS THEN
        BEGIN UTL_HTTP.END_RESPONSE(l_http_resp); EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN DBMS_LOB.FREETEMPORARY(l_b64);      EXCEPTION WHEN OTHERS THEN NULL; END;
        BEGIN DBMS_LOB.FREETEMPORARY(l_body);     EXCEPTION WHEN OTHERS THEN NULL; END;
        RAISE;
END;
/