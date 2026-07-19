from flask import Flask, request, jsonify
import numpy as np
import onnxruntime as ort
from transformers import CLIPProcessor
from PIL import Image
import io
import base64

app = Flask(__name__)

# ---- Load model once at startup ----
print("Loading CLIP model...")
session = ort.InferenceSession(
    "/home/oracle/openai-clip-vit-onnx/model.onnx",
    providers=["CPUExecutionProvider"]
)
processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
print("Model ready.")

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

@app.route("/embed/text", methods=["POST"])
def embed_text():
    data = request.json
    text = data.get("text", "")
    inputs = processor(
        text=[text],
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=77
    )
    onnx_inputs = {
        "input_ids": inputs["input_ids"].numpy(),
        "attention_mask": inputs["attention_mask"].numpy(),
        "pixel_values": np.zeros((1, 3, 224, 224), dtype=np.float32)
    }
    outputs = session.run(None, onnx_inputs)
    names = [o.name for o in session.get_outputs()]
    text_embed = dict(zip(names, outputs))["text_embeds"][0]
    return jsonify({"embedding": text_embed.tolist()})

@app.route("/embed/image", methods=["POST"])
def embed_image():
    data = request.json
    img_b64 = data.get("image_base64", "")
    img_bytes = base64.b64decode(img_b64)
    image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    inputs = processor(
        images=[image],
        return_tensors="pt"
    )
    onnx_inputs = {
        "input_ids": np.zeros((1, 77), dtype=np.int64),
        "attention_mask": np.zeros((1, 77), dtype=np.int64),
        "pixel_values": inputs["pixel_values"].numpy()
    }
    outputs = session.run(None, onnx_inputs)
    names = [o.name for o in session.get_outputs()]
    image_embed = dict(zip(names, outputs))["image_embeds"][0]
    return jsonify({"embedding": image_embed.tolist()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)