#!/usr/bin/env bash
# save as: download_longcat_meta.sh
set -e

# 提示用户输入REPO名称
echo "请输入要下载的仓库路径 (例如: deepseek-ai/DeepSeek-V3.2-Exp):"
read -r REPO

# 验证输入是否为空
if [ -z "$REPO" ]; then
    echo "错误: 仓库名称不能为空"
    exit 1
fi

DIR="${REPO#*/}"

# 国内镜像加速，如需请取消下一行注释
export HF_ENDPOINT=https://hf-mirror.com

mkdir -p "$DIR"
# pip install -U huggingface_hub  # 确保版本最新

huggingface-cli download "$REPO" \
  --include "*.md" "*.json" "*.py" \
  --local-dir "$DIR" \
  --local-dir-use-symlinks=False

echo "✅ 全部非权重文件已下载到：$(realpath "$DIR")"