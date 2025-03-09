ml singularity
cd /work/$(whoami)/github/hpc_vllm/
export PATH=$PATH:$HOME/.local/bin
mkdir -p ./home
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif bash -c \
"vllm serve \
microsoft/Phi-4-multimodal-instruct \
--trust-remote-code \
--served-model-name 'Phi' \
--gpu-memory-utilization 0.90 \
--tensor-parallel-size 1 \
--swap-space 8 \
--enforce-eager \
--port 8000 \
--max-model-len 8192 \
--api-key sk-
"




