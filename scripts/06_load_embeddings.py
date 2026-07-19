import csv
import subprocess

DB_CONN     = "vector_user/Oracle_4U@p125n82.pbm.ihost.com:1531/TESTPDB"
ORACLE_HOME = "/u01/db26aixlc"
SQLPLUS     = f"{ORACLE_HOME}/bin/sqlplus"
BATCH_SIZE  = 500

env = {
    "ORACLE_HOME": ORACLE_HOME,
    "PATH": f"{ORACLE_HOME}/bin:/usr/bin:/bin",
    "LIBPATH": f"{ORACLE_HOME}/lib",
}

def run_sql(sql):
    result = subprocess.run(
        [SQLPLUS, "-s", DB_CONN],
        input=sql + "\nEXIT;\n",
        capture_output=True,
        text=True,
        env=env
    )
    if result.stderr.strip():
        print("  ERR:", result.stderr.strip()[:200])

def build_plsql(image_name, embedding, column):
    chunks = [embedding[i:i+2000] for i in range(0, len(embedding), 2000)]
    clob_lines = f"  v_emb := '{chunks[0]}';\n"
    for chunk in chunks[1:]:
        clob_lines += f"  v_emb := v_emb || '{chunk}';\n"
    return f"""
DECLARE
  v_emb CLOB;
BEGIN
{clob_lines}
  UPDATE fashion_products
  SET {column} = TO_VECTOR(v_emb)
  WHERE IMAGE_NAME = '{image_name}';
END;
/
"""

def load_embeddings(csv_path, column):
    print(f"\n=== Loading {column} ({BATCH_SIZE} rows/batch) ===")
    total = 0
    batch_sql = ""
    batch_count = 0

    with open(csv_path, newline='') as f:
        reader = csv.DictReader(f)
        for row in reader:
            total += 1
            image_name = row["image_name"] + ".jpg"
            batch_sql += build_plsql(image_name, row['embedding'], column)
            batch_count += 1

            if batch_count >= BATCH_SIZE:
                batch_sql += "\nCOMMIT;\n"
                run_sql(batch_sql)
                print(f"  {column} progress: {total}")
                batch_sql = ""
                batch_count = 0

    # flush remaining
    if batch_count > 0:
        batch_sql += "\nCOMMIT;\n"
        run_sql(batch_sql)
        print(f"  {column} progress: {total}")

    print(f"{column} done. Total: {total}")

load_embeddings("desc_embeddings.csv",  "DESC_EMBEDDING")
load_embeddings("image_embeddings.csv", "IMAGE_EMBEDDING")

print("\nAll done!")