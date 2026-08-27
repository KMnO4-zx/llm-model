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

# 国内镜像加速：直连不通时再启用。
# 注意 hf-mirror 对部分仓库会 308 跳回 huggingface.co，huggingface_hub 1.x 会
# 拒绝这种跨域跳转（报 "Distant resource does not seem to be on huggingface.co"），
# 所以默认直连。
# export HF_ENDPOINT=https://hf-mirror.com

mkdir -p "$DIR"
uv sync  # 确保 .venv 已就绪（依赖见 pyproject.toml）

# 注意：hub 1.x 的 --include 是单值参数，空格连写只有第一个生效，必须重复传
uv run hf download "$REPO" \
  --include "*.md" \
  --include "*.json" \
  --include "*.py" \
  --include "*.jinja" \
  --include "*.txt" \
  --local-dir "$DIR"

echo "✅ 全部非权重文件已下载到：$(realpath "$DIR")"