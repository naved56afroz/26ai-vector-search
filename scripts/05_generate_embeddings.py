import csv
import os
import numpy as np
import onnxruntime as ort
from transformers import CLIPProcessor
from PIL import Image
import io

# ---- Config ----
CSV_PATH    = "/home/oracle/dataset/data.csv"
IMG_DIR     = "/home/oracle/dataset/data"
MODEL_PATH  = "/home/oracle/openai-clip-vit-onnx/model.onnx"
DESC_OUT    = "desc_embeddings.csv"
IMAGE_OUT   = "image_embeddings.csv"
BATCH_SIZE  = 32

# ---- Load model ----
print("Loading CLIP model...")
session = ort.InferenceSession(MODEL_PATH, providers=["CPUExecutionProvider"])
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
print("Model loaded.")

# ---- Read CSV ----
rows = []
with open(CSV_PATH, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        rows.append(row)

print(f"Total rows: {len(rows)}")

# ---- Helper: embed texts in batch ----
def embed_texts(texts):
    inputs = processor(
        text=texts,
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=77
    )
    onnx_inputs = {
        "input_ids": inputs["input_ids"].numpy(),
        "attention_mask": inputs["attention_mask"].numpy(),
        "pixel_values": np.zeros((len(texts), 3, 224, 224), dtype=np.float32)
    }
    outputs = session.run(None, onnx_inputs)
    names = [o.name for o in session.get_outputs()]
    return dict(zip(names, outputs))["text_embeds"]

# ---- Helper: embed images in batch ----
def embed_images(image_paths):
    images = []
    valid_paths = []
    for p in image_paths:
        try:
            images.append(Image.open(p).convert("RGB"))
            valid_paths.append(p)
        except Exception as e:
            print(f"  SKIP image {p}: {e}")
    if not images:
        return [], []
    inputs = processor(
        images=images,
        return_tensors="pt",
        padding=True
    )
    onnx_inputs = {
        "input_ids": np.zeros((len(images), 77), dtype=np.int64),
        "attention_mask": np.zeros((len(images), 77), dtype=np.int64),
        "pixel_values": inputs["pixel_values"].numpy()
    }
    outputs = session.run(None, onnx_inputs)
    names = [o.name for o in session.get_outputs()]
    return dict(zip(names, outputs))["image_embeds"], valid_paths

# ---- Generate DESC embeddings ----
print("\n--- Generating description embeddings ---")
with open(DESC_OUT, "w", newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["image_name", "embedding"])

    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i+BATCH_SIZE]
        texts = [r["description"] for r in batch]
        image_names = [os.path.splitext(r["image"])[0] for r in batch]  # strip .jpg

        embeds = embed_texts(texts)
        for name, emb in zip(image_names, embeds):
            writer.writerow([name, emb.tolist()])

        print(f"  Desc: {min(i+BATCH_SIZE, len(rows))}/{len(rows)}")

print(f"Saved: {DESC_OUT}")

# ---- Generate IMAGE embeddings ----
print("\n--- Generating image embeddings ---")
with open(IMAGE_OUT, "w", newline='', encoding='utf-8') as f_out:
    writer = csv.writer(f_out)
    writer.writerow(["image_name", "embedding"])

    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i:i+BATCH_SIZE]
        paths = [os.path.join(IMG_DIR, r["image"]) for r in batch]
        image_names = [os.path.splitext(r["image"])[0] for r in batch]

        embeds, valid_paths = embed_images(paths)
        if len(embeds) == 0:
            continue

        valid_names = [os.path.splitext(os.path.basename(p))[0] for p in valid_paths]
        for name, emb in zip(valid_names, embeds):
            writer.writerow([name, emb.tolist()])

        print(f"  Image: {min(i+BATCH_SIZE, len(rows))}/{len(rows)}")

print(f"Saved: {IMAGE_OUT}")
print("\nDone!")
EOF