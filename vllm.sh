#!/bin/bash
export GLOO_SOCKET_IFNAME=ib0  # 設定 GLOO 使用 InfiniBand 網絡接口
export NCCL_IB_DISABLE=0  # 啟用 InfiniBand，讓 NCCL 使用 IB 來進行更高效的 GPU 之間通信
export NCCL_P2P_DISABLE=0 # 啟用 P2P，讓 GPU 直接溝通
export NCCL_SHM_DISABLE=0 # 啟用共享記憶體，加速 GPU 之間的通訊
export NCCL_SOCKET_IFNAME=ib0,ib1  # 設定 InfiniBand 網卡，讓 NCCL 使用 InfiniBand 網絡進行通信

ml singularity
mkdir -p /work/$(whoami)/github/hpc_vllm/home
# --swap-space 8 為每GPU補充 8G的記憶體
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
vllm serve \
--dtype=half Qwen/QwQ-32B \
--trust-remote-code \
--served-model-name "QwQ-32B" \
--gpu-memory-utilization 0.90 \
--tensor-parallel-size 2 \
--swap-space 8 \
--enforce-eager \
--host $(hostname -s) \
--port 8000 \
--max-model-len 8192 \
--api-key sk-



