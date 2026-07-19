CREATE TABLE "FASHION_EXT" 
   (	"IMAGE_NAME" VARCHAR2(500), 
	"DESCRIPTION" VARCHAR2(4000), 
	"DISPLAY_NAME" VARCHAR2(1000), 
	"CATEGORY" VARCHAR2(500)
   ) 
   ORGANIZATION EXTERNAL 
    ( TYPE ORACLE_LOADER
      DEFAULT DIRECTORY "DATA_DIR"
      ACCESS PARAMETERS
      ( RECORDS DELIMITED BY NEWLINE
        SKIP 1
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
        (
            image_name      CHAR(500),
            description     CHAR(4000),
            display_name    CHAR(1000),
            category        CHAR(500)
        )
    )
      LOCATION
       ( 'data.csv'
       )
    )
   REJECT LIMIT UNLIMITED ;