---
name: vllm
description: Reference for using vLLM. Use when setting up vLLM inference (online or offline), configuring the server, debugging OOM/performance issues, or choosing quantization. Can also be invoked with /vllm.
---

# vLLM Reference

## Installation

```bash
uv pip install vllm --torch-backend=auto
```

## Offline Batch Inference

```python
from vllm import LLM, SamplingParams

llm = LLM(model="meta-llama/Llama-3-8B-Instruct")
sampling_params = SamplingParams(temperature=1.0, top_p=1.0)

prompts = ["Hello, my name is", "The future of AI is"]
outputs = llm.generate(prompts, sampling_params)

for output in outputs:
    print(f"Prompt: {output.prompt!r}, Generated: {output.outputs[0].text!r}")
```

For chat/instruct models, use `llm.chat` instead of `llm.generate`:
```python
messages_list = [[{"role": "user", "content": prompt}] for prompt in prompts]
outputs = llm.chat(messages_list, sampling_params)
```

Note: by default vLLM applies `generation_config.json` from the HuggingFace repo if it exists. To use vLLM defaults instead: `LLM(model=..., generation_config="vllm")`.

## OpenAI-Compatible Server

```bash
vllm serve Qwen/Qwen2.5-1.5B-Instruct
```

Server starts at `http://localhost:8000`. Override with `--host` and `--port`.

### Query with curl

```bash
# Chat completions
curl http://localhost:8000/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "Qwen/Qwen2.5-1.5B-Instruct",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Who won the world series in 2020?"}
        ]
    }'

# Text completions
curl http://localhost:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{"model": "Qwen/Qwen2.5-1.5B-Instruct", "prompt": "San Francisco is a", "max_tokens": 7}'
```

### Query with OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="EMPTY")
response = client.chat.completions.create(
    model="Qwen/Qwen2.5-1.5B-Instruct",
    messages=[{"role": "user", "content": "Hello!"}],
)
print(response.choices[0].message.content)
```

### API key authentication

```bash
vllm serve MODEL --api-key KEY1 KEY2  # accepts any of the listed keys
```

Or set `VLLM_API_KEY` environment variable.

## Key Server Flags

| Flag                       | Purpose                                | Example                    |
| -------------------------- | -------------------------------------- | -------------------------- |
| `--gpu-memory-utilization` | Fraction of GPU memory to use          | `0.9`                      |
| `--max-model-len`          | Max sequence length                    | `8192`                     |
| `--tensor-parallel-size`   | Split model across N GPUs (power of 2) | `4`                        |
| `--quantization`           | Quantization method                    | `awq`, `gptq`, `fp8`       |
| `--enable-prefix-caching`  | Cache common prefixes                  | -                          |
| `--enable-chunked-prefill` | Chunk long prefills for lower TTFT     | -                          |
| `--max-num-seqs`           | Max concurrent sequences               | `512`                      |
| `--trust-remote-code`      | Required for some custom models        | -                          |
| `--attention-backend`      | Override attention backend             | `FLASH_ATTN`, `FLASHINFER` |
| `--host` / `--port`        | Bind address                           | `0.0.0.0` / `8000`         |

## Production Deployment

```bash
vllm serve meta-llama/Llama-3-8B-Instruct \
  --host 0.0.0.0 \
  --gpu-memory-utilization 0.9 \
  --enable-prefix-caching \
  --max-model-len 8192

# Large models (70B+) with quantization + tensor parallelism
vllm serve meta-llama/Llama-2-70b-hf \
  --tensor-parallel-size 4 \
  --quantization awq \
  --gpu-memory-utilization 0.9
```

### Docker

```bash
docker run --gpus all -p 8000:8000 \
  vllm/vllm-openai:latest \
  --model meta-llama/Llama-3-8B-Instruct \
  --gpu-memory-utilization 0.9
```

## Serving with LoRA

```bash
vllm serve MODEL \
  --enable-lora \
  --lora-modules my_adapter=user/my-lora-adapter \
  --max-lora-rank RANK \
  --max-num-batched-tokens TOKENS
```

`--lora-modules` format is `name=path` (HuggingFace repo or local path). Multiple adapters can be served simultaneously:

```bash
--lora-modules adapter_a=user/lora-a adapter_b=user/lora-b
```

To query a specific adapter, use its name as the `model` in the request:

```python
client.chat.completions.create(
    model="my_adapter",  # name from --lora-modules
    messages=[{"role": "user", "content": "Hello!"}],
)
```

Use the base model name to query without LoRA applied.

## Quantization

| Method   | When to use                                |
| -------- | ------------------------------------------ |
| **AWQ**  | Best for 70B models, minimal accuracy loss |
| **GPTQ** | Wide model support, good compression       |
| **FP8**  | Fastest on H100 GPUs                       |

```bash
vllm serve TheBloke/Llama-2-70B-AWQ --quantization awq
```


## Troubleshooting

### OOM during model loading

Try in order:
1. `--gpu-memory-utilization 0.7`
2. `--max-model-len 4096`
3. `--quantization awq`
4. `--tensor-parallel-size 2`

### OOM during inference

KV cache fills up. Reduce `--gpu-memory-utilization`, `--max-num-seqs`, or `max_tokens` in requests.

### High TTFT (>1s)

- Long prompts: `--enable-chunked-prefill`
- Repeated prefixes: `--enable-prefix-caching`
- Too many concurrent requests: reduce `--max-num-seqs`

### Low throughput

- Check GPU util with `nvidia-smi` (should be >80%)
- Increase `--max-num-seqs 512`
- Ensure tensor parallelism uses power-of-2 GPUs

### Model not found

- Check exact model name/capitalization on HuggingFace
- For gated models: run `huggingface-cli login` first
- For custom models: add `--trust-remote-code`

### Connection refused

```bash
curl http://localhost:8000/health  # check server is running
```

Bind to all interfaces with `--host 0.0.0.0`. Check port conflicts with `lsof -i :8000`.

### Distributed init failed (multi-node)

```bash
export NCCL_DEBUG=INFO
export NCCL_SOCKET_IFNAME=eth0  # your network interface
```

Verify `MASTER_ADDR`, `MASTER_PORT`, `RANK`, `WORLD_SIZE` are set consistently across nodes.

## Debugging

```bash
# Debug logging
export VLLM_LOGGING_LEVEL=DEBUG

# GPU monitoring
watch -n 1 nvidia-smi

# Health & model info
curl http://localhost:8000/health
curl http://localhost:8000/v1/models

# Benchmarking
vllm bench throughput --model MODEL --input-tokens 128 --output-tokens 256 --num-prompts 100
vllm bench latency --model MODEL --input-tokens 128 --output-tokens 256 --batch-size 8
```

## Resources

- Docs: https://docs.vllm.ai
- GitHub: https://github.com/vllm-project/vllm
