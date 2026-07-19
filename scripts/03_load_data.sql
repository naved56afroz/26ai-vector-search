INSERT /*+ APPEND */ INTO fashion_products (
    product_id,
    image_name,
    display_name,
    category,
    description
)
SELECT
    TO_NUMBER(REPLACE(image_name, '.jpg')),
    image_name,
    display_name,
    category,
    display_name || '. ' || description || '. Category: ' || category
FROM fashion_ext
WHERE REGEXP_LIKE(image_name, '^[0-9]+\.jpg$');

COMMIT;