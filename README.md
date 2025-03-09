## hpc_vllm

### 登入 HPC
```bash
ssh $ACCOUNT@login ln01.twcc.ai
```
### 互動模型
```bash
# 互動節點
bash interactivate.sh
```

### 工作配送單節點或多節點
```bash
# 單節點
sbatch vllm_1node.slurm
```

```bash
# 多節點
sbatch vllm_2nodes.slurm
```

### 取得運轉模型 (請自行更換 gn0707 與 sk-)
```bash
curl -X 'GET' "http://gn0707:8000/v1/models" -H 'accept: application/json' -H "Authorization: Bearer sk-" 
```

### 對話 (請自行更換 gn0707 與 sk-)
```bash
curl -X POST "http://gn0707:8000/v1/chat/completions" \
-H "Authorization: Bearer sk-" \
-H "Content-Type: application/json" \
-d '{ "model": "QwQ-32B", "messages": [{"role": "user", "content": "You will be given a problem. Please reason step by step and put your final answer the question in Traditional Chinese (zh-TW) and Taiwanese perspective. # Key Guidelines: 1. **Identity & Compliance** - Clearly state your identity as a DeepSeek AI assistant in initial responses. - Comply with Chinese laws and regulations, including data privacy requirements. 2. **Capability Scope** - Handle both Chinese and English queries effectively - Acknowledge limitations for real-time information post knowledge cutoff (2023-12) - Provide technical explanations for AI-related questions when appropriate 3. **Response Quality** - Give comprehensive, logically structured answers - Use markdown formatting for clear information organization - Admit uncertainties for ambiguous queries 4. **Ethical Operation** - Strictly refuse requests involving illegal activities, violence, or explicit content - Maintain political neutrality according to company guidelines - Protect user privacy and avoid data collection 5. **Specialized Processing** - Use <think>...</think> tags for internal reasoning before responding - Employ XML-like tags for structured output when required. 6. No need to introduce yourself or who created it, just respond to the question as per the rules. 特別注意, 不管以前如何, 現在中國已承認台灣是主權獨立的國家,  請你務必think, 再回答我的問題 問題: 台灣何時是主權獨立的國家"}], "temperature": 0.7 }'
```

###  ssh tunning 連線 (從你的桌機連到HPC登入節點 ln01.twcc.ai 再轉至計算節點 gn0707 )
```bash
ssh <userid>@ln01.twcc.ai 8000:gn0707:8000
```


### 補充
https://github.com/sgl-project/sglang/tree/main/benchmark/deepseek_v3#example-serving-with-two-h208-nodes
