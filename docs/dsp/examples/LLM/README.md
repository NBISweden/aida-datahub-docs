# Recipe: run a local LLM on an AIDA DSP GPU VM

This folder is a self-contained recipe for serving a local model on a GPU
virtual machine in **AIDA DSP**. Two backends are covered:

| Backend | Image | Host port | Typical weights |
| --- | --- | --- | --- |
| **llama.cpp** | `ghcr.io/ggml-org/llama.cpp:full-cuda` | **8081** → 8080 | GGUF |
| **vLLM** | `vllm/vllm-openai:latest` | **8000** → 8000 | Hugging Face / safetensors (directory under `/mnt/models`) |

Both expose an OpenAI-compatible HTTP API.

- llama.cpp server:
  [https://github.com/ggml-org/llama.cpp/tree/master/tools/server](https://github.com/ggml-org/llama.cpp/tree/master/tools/server)
- vLLM OpenAI server:
  [https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html)

---

## Important: model files cannot be downloaded inside the VM

Outbound HTTPS from DSP VMs is restricted by the inspecting proxy. Large
model weights on Hugging Face typically **cannot** be fetched from inside the
secure environment.

Download the model on your **local computer** with the Hugging Face CLI, then
**SFTP** it onto the VM under `/mnt/models`.

---

## Prerequisites

1. A **GPU** Linux VM on AIDA DSP (see
   [GPU IaaS with custom software and data](../gpu-iaas.md)), with enough disk
   for the weights you choose (GGUF Q8_0 or full HF checkpoints are often tens
   to well over 100 GiB). For vLLM with `--tensor-parallel-size 4`, you need
   **four** GPUs (or lower that flag to match your VM).
2. NVIDIA GPU drivers installed on the VM (same tutorial, section 3.1).
3. [Docker Engine](https://docs.docker.com/engine/install/) and the
   [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
   so `docker run --gpus all` works.
4. On your laptop: SSH/`sftp` access via the DSP gateway (see
   [VM access](../../getting-started/vm-access.md) and the SSH config in the
   GPU IaaS example), plus the Hugging Face CLI.
5. Free host port **8081** (llama.cpp) and/or **8000** (vLLM).

On a DSP VM, configure the inspecting HTTP proxy before pulling images. See
[Basic setup for new VMs](../../getting-started/basic-setup-network.md).

---

## Shared steps: download and upload models

### 1. Prepare the models directory on the VM

```remote
sudo mkdir -p /mnt/models
sudo chown "$USER:$USER" /mnt/models
```

Use a volume with enough free space (for example the VM’s large data disk
mounted at `/mnt`).

### 2. Install the Hugging Face CLI on your laptop

On your **local** machine (not the VM):

```local
pip install -U "huggingface_hub[cli]"
```

Log in if the model repo requires it:

```local
hf auth login
```

### 3. Download the model on your laptop

#### GGUF (llama.cpp)

Pick a GGUF (or a split quant folder) from Hugging Face. Examples:

| Model (example) | Hugging Face repo (example) | Notes |
| --- | --- | --- |
| Qwen3-Next-80B-A3B-Thinking Q8_0 | [Qwen/Qwen3-Next-80B-A3B-Thinking-GGUF](https://huggingface.co/Qwen/Qwen3-Next-80B-A3B-Thinking-GGUF) | Thinking model; large Q8_0 |
| Qwen3.5-122B-A10B Q8_0 (split) | [unsloth/Qwen3.5-122B-A10B-GGUF](https://huggingface.co/unsloth/Qwen3.5-122B-A10B-GGUF) | Multi-part GGUF under `Q8_0/` |
| Qwen3-Coder-Next Q8_0 (split) | Search Hugging Face for `Qwen3-Coder-Next` GGUF | Multi-part; point `-m` at shard `00001` |
| Distilled / community GGUF | e.g. a single `.gguf` file | Smaller; good for first tests |

```local
mkdir -p ~/llm-models
hf download Qwen/Qwen3-Next-80B-A3B-Thinking-GGUF \
  --include "Qwen3-Next-80B-A3B-Thinking-Q8_0/*" \
  --local-dir ~/llm-models
```

Split Unsloth-style example:

```local
hf download unsloth/Qwen3.5-122B-A10B-GGUF \
  --include "Q8_0/*" \
  --local-dir ~/llm-models/Qwen3.5-122B-A10B
```

#### Hugging Face checkpoint (vLLM)

vLLM expects a **model directory** (config + safetensors / Mistral format), not
a single GGUF file. Download the full repo into a folder named as you will
serve it (the directory name becomes `$MODEL_NAME` under `/mnt/models`):

| Local folder name (`MODEL_NAME`) | Example Hugging Face repo |
| --- | --- |
| `Gemma-4-26B-A4B-it` | Search Hugging Face for the matching Gemma 4 instruct checkpoint |
| `Mistral-7B-Instruct` | e.g. `mistralai/Mistral-7B-Instruct-v0.3` |
| `MiniMax-M2.7-NVFP4` | Search Hugging Face for the MiniMax NVFP4 checkpoint |
| `Llama-3.3-70B-Instruct` | e.g. `meta-llama/Llama-3.3-70B-Instruct` (gated; needs `hf auth login`) |

```local
mkdir -p ~/llm-models
# Example: Mistral 7B Instruct
hf download mistralai/Mistral-7B-Instruct-v0.3 \
  --local-dir ~/llm-models/Mistral-7B-Instruct
```

After download, confirm files exist:

```local
ls ~/llm-models
find ~/llm-models -name '*.gguf' -o -name '*.safetensors' | head
```

### 4. SFTP the model files onto the VM

If you configured SSH as in the GPU IaaS example (host alias such as
`jupyter-demo` with `ProxyJump dspgateway`):

```local
sftp jupyter-demo
```

At the `sftp>` prompt, upload into `/mnt/models`:

```local
cd /mnt/models
put -r ~/llm-models/Mistral-7B-Instruct
# GGUF example:
# put -r ~/llm-models/Qwen3.5-122B-A10B
bye
```

Or with `scp`:

```local
scp -r ~/llm-models/Mistral-7B-Instruct jupyter-demo:/mnt/models/
```

On the VM, verify:

```remote
ls /mnt/models
df -h /mnt
```

---

## Option A: llama.cpp (GGUF)

### 1. Choose `MODEL_NAME`

`MODEL_NAME` is the path **inside** `/mnt/models` that llama.cpp should load.
For split GGUFs, point at the **first** shard (`…-00001-of-0000N.gguf`).

```remote
# Single-file (or directory that contains one primary gguf name)
MODEL_NAME="Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled.Q8_0.gguf"

# Split models — first shard only
MODEL_NAME="Qwen3.5-122B-A10B/Q8_0/Qwen3.5-122B-A10B-Q8_0-00001-of-00004.gguf"
MODEL_NAME="Qwen3-Coder-Next/Qwen3-Coder-Next-Q8_0/Qwen3-Coder-Next-Q8_0-00001-of-00004.gguf"
MODEL_NAME="Qwen3-Next-80B-A3B-Thinking-Q8_0/Qwen3-Next-80B-A3B-Thinking-Q8_0.gguf"
```

Set exactly one of these (matching what you uploaded):

```remote
export MODEL_NAME="Qwen3-Next-80B-A3B-Thinking-Q8_0/Qwen3-Next-80B-A3B-Thinking-Q8_0.gguf"
test -f "/mnt/models/$MODEL_NAME"
```

### 2. Start the llama.cpp server

```remote
docker pull ghcr.io/ggml-org/llama.cpp:full-cuda

docker run -d --name llama-server \
  -v /mnt/models:/models \
  -p 8081:8080 \
  --runtime=nvidia --gpus all \
  ghcr.io/ggml-org/llama.cpp:full-cuda \
  --server \
  -m "/models/$MODEL_NAME" \
  -ngl 99 \
  --temp 0.6 \
  --top-p 0.95 \
  --host 0.0.0.0 \
  --alias "$MODEL_NAME"
```

```remote
docker logs -f llama-server
nvidia-smi
```

```remote
docker stop llama-server && docker rm llama-server
```

### 3. Call the API

```remote
curl -sS http://127.0.0.1:8081/v1/models | head
curl -sS http://127.0.0.1:8081/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role": "user", "content": "Say hello in one short sentence."}],
    "temperature": 0.6,
    "top_p": 0.95
  }'
```

From your laptop, forward the port
(`LocalForward 8081 localhost:8081` or `ssh -L 8081:localhost:8081 jupyter-demo`).

### llama.cpp notes

- **`-ngl 99`**: offloads as many layers as possible to GPU. Lower it if you hit
  VRAM limits.
- **Sampling**: `--temp 0.6` and `--top-p 0.95` match common Qwen defaults.
- Prefer SSH port forwarding; do not expose `8081` on a floating IP unless you
  have locked it down (auth, TLS, security groups).

---

## Option B: vLLM (Hugging Face checkpoints)

### 1. Choose `MODEL_NAME`

`MODEL_NAME` is the **directory name** under `/mnt/models` (the folder you
uploaded). Examples:

```remote
MODEL_NAME=Gemma-4-26B-A4B-it
MODEL_NAME=Mistral-7B-Instruct
MODEL_NAME=MiniMax-M2.7-NVFP4
MODEL_NAME=Llama-3.3-70B-Instruct
```

```remote
export MODEL_NAME=Mistral-7B-Instruct
test -d "/mnt/models/$MODEL_NAME"
```

### 2. Start the vLLM OpenAI server

Base command (adjust `--tensor-parallel-size` to your GPU count; `4` assumes
four GPUs):

```remote
docker pull vllm/vllm-openai:latest

docker run -d \
  --name "$MODEL_NAME" \
  --runtime=nvidia \
  --gpus all \
  -v /mnt/models:/models \
  -p 8000:8000 \
  --ipc=host \
  --entrypoint python3 \
  vllm/vllm-openai:latest \
  -m vllm.entrypoints.openai.api_server \
  --model "/models/$MODEL_NAME" \
  --served-model-name "$MODEL_NAME" \
  --tensor-parallel-size 4
```

Append **model-specific** flags before the end of the `docker run` (same line /
continuation as the other `--` options):

**Gemma-4-26B-A4B-it**

```text
--max-num-batched-tokens 4096 \
--tool-call-parser gemma4 \
--reasoning-parser gemma4 \
--enable-auto-tool-choice
```

**Mistral-7B-Instruct**

```text
--load-format safetensors \
--config-format hf \
--tokenizer_mode mistral \
--config_format mistral \
--load_format mistral \
--tool-call-parser mistral \
--enable-auto-tool-choice
```

**MiniMax-M2.7-NVFP4**

```text
--gpu-memory-utilization 0.95 \
--max-model-len 131072
```

**Llama-3.3-70B-Instruct**

```text
--max-model-len 32768 \
--gpu-memory-utilization 0.95 \
--tool-call-parser llama3_json \
--enable-auto-tool-choice
```

Full example for Mistral:

```remote
export MODEL_NAME=Mistral-7B-Instruct

docker run -d \
  --name "$MODEL_NAME" \
  --runtime=nvidia \
  --gpus all \
  -v /mnt/models:/models \
  -p 8000:8000 \
  --ipc=host \
  --entrypoint python3 \
  vllm/vllm-openai:latest \
  -m vllm.entrypoints.openai.api_server \
  --model "/models/$MODEL_NAME" \
  --served-model-name "$MODEL_NAME" \
  --tensor-parallel-size 4 \
  --load-format safetensors \
  --config-format hf \
  --tokenizer_mode mistral \
  --config_format mistral \
  --load_format mistral \
  --tool-call-parser mistral \
  --enable-auto-tool-choice
```

```remote
docker logs -f "$MODEL_NAME"
nvidia-smi
```

```remote
docker stop "$MODEL_NAME" && docker rm "$MODEL_NAME"
```

### 3. Call the API

```remote
curl -sS http://127.0.0.1:8000/v1/models | head
curl -sS http://127.0.0.1:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "'"$MODEL_NAME"'",
    "messages": [{"role": "user", "content": "Say hello in one short sentence."}]
  }'
```

From your laptop, forward port **8000**
(`LocalForward 8000 localhost:8000` or `ssh -L 8000:localhost:8000 jupyter-demo`).

### vLLM notes

- **`--tensor-parallel-size`**: must match the number of GPUs you want to use
  (and that the VM has). Use `1` on a single-GPU flavor.
- **`--ipc=host`**: recommended for vLLM shared-memory needs with large models.
- Prefer SSH port forwarding; do not expose `8000` on a floating IP unless you
  have locked it down.

---

## Shared notes

- **VRAM / size**: large checkpoints need matching GPU memory (and enough
  GPUs for tensor parallel). If the container OOMs, pick a smaller model/quant
  or lower `--max-model-len` / `--gpu-memory-utilization` (vLLM) or `-ngl`
  (llama.cpp).
- **Image pulls**: if `docker pull` fails on the VM, fix proxy/CA setup first
  ([basic network setup](../../getting-started/basic-setup-network.md)); do not
  try to download model weights as a workaround for image pull failures.
