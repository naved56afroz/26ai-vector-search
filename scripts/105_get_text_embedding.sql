create or replace FUNCTION get_text_embedding(p_text IN VARCHAR2)
RETURN VECTOR
IS
    l_http_req  UTL_HTTP.REQ;
    l_http_resp UTL_HTTP.RESP;
    l_url       VARCHAR2(200) := 'http://localhost:5001/embed/text';
    l_body      VARCHAR2(32767);
    l_response  CLOB := '';
    l_buffer    VARCHAR2(32767);
    l_vector    VECTOR;
BEGIN
    -- Build JSON body
    l_body := '{"text": "' || REPLACE(p_text, '"', '\"') || '"}';

    -- Make HTTP POST request
    UTL_HTTP.SET_TRANSFER_TIMEOUT(60);
    l_http_req := UTL_HTTP.BEGIN_REQUEST(l_url, 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
    UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', LENGTH(l_body));
    UTL_HTTP.WRITE_TEXT(l_http_req, l_body);

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

    -- Extract embedding array from {"embedding": [...]}
    l_response := SUBSTR(l_response,
                         INSTR(l_response, '['),
                         INSTR(l_response, ']') - INSTR(l_response, '[') + 1);

    -- Convert to VECTOR
    l_vector := TO_VECTOR(l_response);
    RETURN l_vector;

EXCEPTION
    WHEN OTHERS THEN
        UTL_HTTP.END_RESPONSE(l_http_resp);
        RAISE;
END;
/