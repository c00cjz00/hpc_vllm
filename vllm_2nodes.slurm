#!/bin/bash
#SBATCH --job-name=vllm02    		## 設定作業名稱
#SBATCH --nodes=2               	## 申請 2 個計算節點
#SBATCH --ntasks-per-node=1     	## 每個節點運行 1 個 srun task
#SBATCH --cpus-per-task=32      	## 每個 srun task 申請 32 個 CPU 核心
#SBATCH --gres=gpu:8            	## 每個節點申請 8 張 GPU
#SBATCH --time=00:50:00         	## 設定最長執行時間為 50 分鐘
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


# 取得計算節點名稱
nodes=$(scontrol show hostnames "$SLURM_JOB_NODELIST")
nodes_array=($nodes)

# 初始化 IP 地址陣列
nodes_ip_address_array=()

# 查詢每個節點的 IP 地址，並存入陣列
for node in "${nodes_array[@]}"; do
    ip_address=$(srun --nodes=1 --ntasks=1 -w "$node" hostname -i | awk '{print $1}')
    nodes_ip_address_array+=("$ip_address")
done

# 輸出每個節點對應的 IP 地址
for i in "${!nodes_array[@]}"; do
    echo "Node: ${nodes_array[$i]}, IP: ${nodes_ip_address_array[$i]}"
done

# 取得 Head 節點的 IP 地址
head_node=${nodes_array[0]}
head_node_ip=$(srun --nodes=1 --ntasks=1 -w "$head_node" hostname --ip-address)

# 設定 Head 節點的連接端口
port=6379
ip_head=$head_node_ip:$port
export ip_head
echo "IP Head: $ip_head"

echo "Starting HEAD at $head_node"
master_ip=${nodes_ip_address_array[0]}

# 啟動 Ray Head 節點
srun --nodes=1 --ntasks=1 -w "$head_node" \
	bash -c "export VLLM_HOST_IP=${master_ip}; \
	echo \$VLLM_HOST_IP; \
	echo cjz; \
	singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
    ray start --head --node-ip-address=\"$head_node_ip\" --port=$port \
    --dashboard-host=0.0.0.0 \
    --dashboard-port=8265 \
    --block" &

# 等待 Head 節點啟動
echo "Waiting a bit before starting worker nodes..."
sleep 10

# 啟動 Ray Worker 節點
worker_num=$((SLURM_JOB_NUM_NODES - 1))

# 從 1 開始 (0 是 Head 節點)
for ((i = 1; i <= worker_num; i++)); do
    node_i=${nodes_array[$i]}
	nodes_ip=${nodes_ip_address_array[$i]}
    echo "Starting WORKER $i at $node_i"
    srun --nodes=1 --ntasks=1 -w "$node_i" \
		bash -c "export VLLM_HOST_IP=${nodes_ip}; \
		echo \$VLLM_HOST_IP; \
		echo cjz; \
		singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
        ray start --address \"$ip_head\" \
        --block" &
    sleep 5
done

# 模型下載
#huggingface-cli download Qwen/QwQ-32B

# 啟動 vLLM 服務, 其中 --tensor-parallel-size $(nvidia-smi -L | wc -l) --pipeline-parallel-size ${SLURM_NNODES} 分別為單節點GPU數量與工作分流節點數
# --swap-space 32 為每GPU補充 32G的記憶體
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_vllm/home:$HOME /work/$(whoami)/github/hpc_vllm/vllm-openai_v0.7.3.sif \
	bash -c "export VLLM_HOST_IP=${master_ip}; \
	echo \$VLLM_HOST_IP; \
	vllm serve --dtype=half Qwen/QwQ-32B --trust-remote-code --served-model-name \"QwQ-32B\" --gpu-memory-utilization 0.90 --tensor-parallel-size $(nvidia-smi -L | wc -l) --pipeline-parallel-size ${SLURM_NNODES} --host $(hostname -s) --port 8000 --max-model-len 8192 --api-key sk- --swap-space 8 --enforce-eager"


sleep 10000

# 等待一段時間，以確保 Ray 叢集啟動完畢
echo "Waiting a bit before submitting the job..."

