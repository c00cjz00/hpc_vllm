#!/bin/bash
#SBATCH --job-name=qwq32b    		## 設定作業名稱
#SBATCH --nodes=1                	## 申請 1 個計算節點
#SBATCH --ntasks-per-node=1      	## 每個節點運行 1 個 srun task
#SBATCH --cpus-per-task=32        	## 每個 srun task 申請 32 個 CPU 核心
#SBATCH --gres=gpu:8             	## 每個節點申請 8 張 GPU
##SBATCH --time=01:00:00          	## 設定最長執行時間為 60 分鐘
#SBATCH --account="GOV113021"   	## 指定計畫 ID，費用將依此 ID 計算
#SBATCH --partition=gp4d        	## 選擇計算資源的 queue (gp4d 最長執行 4 天)
#SBATCH --output=logs/job-%j.out    ## 設定標準輸出檔案 (%j 代表作業 ID)
#SBATCH --error=logs/job-%j.err     ## 設定錯誤輸出檔案 (%j 代表作業 ID)
#SBATCH --mail-type=END,FAIL        ## 設定郵件通知類型 (作業結束或失敗時通知)
#SBATCH --mail-user=summerhill001@gmail.com  ## 設定接收通知的信箱

set -ex  ## 使腳本在執行錯誤時立即終止，並顯示執行的命令
echo "SLURM_JOB_ID: $SLURM_JOB_ID"
echo "SLURM_JOB_NODELIST: $SLURM_JOB_NODELIST"

export GLOO_SOCKET_IFNAME=ib0  # 設定 GLOO 使用 InfiniBand 網絡接口
export NCCL_IB_DISABLE=0  # 啟用 InfiniBand，讓 NCCL 使用 IB 來進行更高效的 GPU 之間通信
export NCCL_P2P_DISABLE=0 # 啟用 P2P，讓 GPU 直接溝通
export NCCL_SHM_DISABLE=0 # 啟用共享記憶體，加速 GPU 之間的通訊
export NCCL_SOCKET_IFNAME=ib0,ib1,ib2,ib3  # 設定 InfiniBand 網卡，讓 NCCL 使用 InfiniBand 網絡進行通信

mkdir -p /work/$(whoami)/github/hpc_vllm/home
export PATH=$HOME/.local/bin:$PATH
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
vllm serve --dtype=half unsloth/QwQ-32B \
--trust-remote-code --served-model-name "unsloth/QwQ-32B" \
--gpu-memory-utilization 0.95 --tensor-parallel-size 4 --pipeline-parallel-size 2 \
--host $(hostname -s) --port 8000 --max-model-len 8192 \
--api-key sk1234 --swap-space 8 --enforce-eager

