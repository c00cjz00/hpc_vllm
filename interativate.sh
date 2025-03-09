ml singularity

mkdir -p /work/$(whoami)/github/hpc_vllm/home
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
vllm serve \
--dtype=half Qwen/QwQ-32B \
--trust-remote-code \
--served-model-name "QwQ-32B" \
--gpu-memory-utilization 0.90 \
--tensor-parallel-size 2 \
--swap-space 8 \
--enforce-eager \
--host $(hostname) \
--port 8000 \
--max-model-len 8192 \
--api-key sk-



