# oracle_26ai_demo

This repository hosts scripts, documents, and related materials to support the Oracle 26ai demo.

---

# 🚀 AI-Powered E-commerce Search on Oracle 26ai (AIX)

Transform a traditional search into **AI-powered semantic + image + hybrid search** using Oracle Vector capabilities — fully on **IBM Power (AIX)**, no GPU, no external vector DB.

---

## ⚡ Prerequisites

*   Oracle 26ai Database (IBM Power + AIX)
*   CLIP (Vision + Language) via ONNX Runtime
*   Flask embedding service
*   Oracle APEX (UI)

---

## 📦 Dataset

To obtain the dataset, execute the following command:

```bash
curl -L -o /tmp/fashion-product-text-images-dataset.zip \
https://www.kaggle.com/api/v1/datasets/download/nirmalsankalana/fashion-product-text-images-dataset
```

## 🏗️ Architecture

![Architecture Diagram]([https://raw.github.ibm.com/Naved-Afroz1/oracle_26ai_demo/7b2e279608696f46edab0a64ba7ff2afba2101cd/images/arch_diag.svg?token=AADSGPFRKA4EV5RBRPKEM7DJYPZUO](https://raw.githubusercontent.com/naved56afroz/26ai-vector-search/refs/heads/main/images/oracle_ai_aix_native_architecture_1.drawio.png))

## 🧱 Setup Flow

1.  **Enable Vector Engine**

    ```sql
    ALTER SYSTEM SET VECTOR_MEMORY_SIZE = 1G SCOPE=SPFILE;
    ALTER SYSTEM SET FILESYSTEMIO_OPTIONS = SETALL SCOPE=SPFILE;
    SHUTDOWN IMMEDIATE;
    STARTUP;
    ```

2.  **Create User & Tablespace**

    *   Create `VECTOR_USER`
    *   Assign tablespace and required privileges

3.  **Load Data**

    *   External table → `fashion_ext`
    *   Main table → `fashion_products`

    Load:

    *   44K+ product records
    *   Images as BLOB

4.  **Generate Embeddings**

    ```bash
    nohup python3 generate_embeddings.py &
    nohup python3 load_embeddings.py &
    ```

5.  **Create Vector Index**

    ```sql
    CREATE VECTOR INDEX fashion_hnsw_desc_embedding_idx ...
    CREATE VECTOR INDEX fashion_hnsw_image_embedding_idx ...
    ```

6.  **Start Embedding Service**

    ```bash
    nohup python3 embedding_service.py &
    ```

7.  **Import APEX App**

    *   Import `app_export.sql`
    *   Run and test:
        *   Text search
        *   Image search
        *   Hybrid search

## 🔍 Search Capabilities

| Mode            | Description                   |
| :-------------- | :---------------------------- |
| Traditional     | LIKE-based keyword match      |
| Text Semantic   | Understands meaning           |
| Image Search    | Visual similarity             |
| Hybrid ⭐       | Best results (text + image)   |

## 💡 Key Highlight

*   Oracle combines AI similarity + structured data in one query
*   Results are relevant and available
*   Shows stock count
*   Supports Notify Me for out-of-stock

## 🧠 Why This Matters

*   No external vector DB
*   No GPU required
*   Runs fully on AIX (enterprise-ready)
*   Single SQL = AI-powered search

## 📂 Execution Order

Scripts are prefixed (01_ → 15_) — run in sequence.

## 🔗 Outcome

A real-world AI search system:

*   Text → Semantic understanding
*   Image → Visual similarity
*   Hybrid → Production-grade accuracy
