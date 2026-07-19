SET SERVEROUTPUT ON

DECLARE
    v_bfile   BFILE;
    v_blob    BLOB;
    v_count   NUMBER := 0;
BEGIN
    FOR r IN (
        SELECT product_id, image_name
        FROM fashion_products
        WHERE image_blob IS NULL
    )
    LOOP
        v_bfile := BFILENAME('IMG_DIR', r.image_name);

        UPDATE fashion_products
        SET image_blob = EMPTY_BLOB()
        WHERE product_id = r.product_id
        RETURNING image_blob INTO v_blob;

        DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);

        DBMS_LOB.LOADFROMFILE(
            dest_lob    => v_blob,
            src_lob     => v_bfile,
            amount      => DBMS_LOB.GETLENGTH(v_bfile)
        );

        DBMS_LOB.CLOSE(v_bfile);

        v_count := v_count + 1;

        IF MOD(v_count, 2000) = 0 THEN
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Committed: ' || v_count);
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Completed. Total Loaded: ' || v_count);
END;
/