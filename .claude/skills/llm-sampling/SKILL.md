---
name: llm-sampling
description: Use this skill every time when sampling responses (doing the inference) from an LLM.
---


## Common Rules
- When sampling from instruction-tuned models, make sure that a correct chat template is applied. Remember that when sampling locally, you need to do it yourself.
- Some thinking models (e.g. Qwen3) support also non-reasoning mode. When instructed to sample from the model with thinking disabled, you should provide `enable_thinking=False` to the `tokenizer.apply_chat_template`.
- By default, when hosting LLMs locally, use `vllm` for efficient sampling. For offline batch inference (Python `LLM`/`SamplingParams` API), look up the `vllm-reference` skill. For serving (online inference via `vllm serve`), look up the `vllm-deploy-simple` skill.


## Default Sampling Parameters

Always use these parameters unless the user specifies otherwise.

* **Temperature**: 1.0
* **Max Tokens**: 2000

## Quantization

Unless told otherwise, quantize LLMs when hosting them locally on GPU.

Quantization config:
```python
BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True,
)
```


# OpenRouter API Sampling

- By default use OpenRouter API to sample from LLMs (unless the model needs to be hosted locally).
- By default use the `https://openrouter.ai/api/v1/chat/completions` endpoint.
- If you need a different sampling strategy — such as user-turn sampling, sampling next token completions without chat formatting, or prefilling the response — use `https://openrouter.ai/api/v1/completions` endpoint and format the prompt accordingly. If using this endpoint, use the `DeepInfra` provider.
- Every sampling call should enable retries if the request fails due to an error.
- Read the API key from the `.env` file using `load_dotenv()`. Never hardcode API keys.
- Sample multiple responses concurrently.

## LLM judge
- By default sample from the LLM judge model using OpenRouter Chat API.
- By default use `google/gemini-3-flash-preview` model.
