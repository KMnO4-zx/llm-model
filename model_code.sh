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

# ---------- 模型代码回退 ----------
# HF 仓库自带 .py（trust_remote_code 风格）时上面已经下载完；
# 若没有（如 Qwen3.8-Flash-Next 依赖 transformers 内置实现），
# 则按 config.json 的 model_type 去 transformers 主干拉对应模块。
if ! compgen -G "$DIR/*.py" >/dev/null; then
    MODEL_TYPE=$(uv run python -c "import json;print(json.load(open('$DIR/config.json'))['model_type'])" 2>/dev/null || true)
    if [ -z "$MODEL_TYPE" ]; then
        echo "⚠️  HF 仓库不含 .py，且 config.json 中无 model_type，跳过代码回退"
    else
        TF_SHA=$(git ls-remote https://github.com/huggingface/transformers.git refs/heads/main | cut -f1)
        TF_BASE="https://raw.githubusercontent.com/huggingface/transformers/$TF_SHA/src/transformers/models/$MODEL_TYPE"
        if [ "$(curl -s -o /dev/null -w '%{http_code}' "$TF_BASE/configuration_$MODEL_TYPE.py")" = "200" ]; then
            echo "🔍 HF 仓库不含模型代码，从 transformers@$TF_SHA 下载 $MODEL_TYPE 实现"
            for f in \
                __init__.py \
                configuration_$MODEL_TYPE.py \
                modeling_$MODEL_TYPE.py \
                modular_$MODEL_TYPE.py \
                processing_$MODEL_TYPE.py \
                image_processing_$MODEL_TYPE.py \
                image_processing_${MODEL_TYPE}_fast.py \
                video_processing_$MODEL_TYPE.py \
                tokenization_$MODEL_TYPE.py; do
                code=$(curl -s -o /dev/null -w '%{http_code}' "$TF_BASE/$f")
                if [ "$code" = "200" ]; then
                    curl -sL -f -o "$DIR/$f" "$TF_BASE/$f" && echo "  ↓ $f"
                fi
            done
            {
                echo "# 代码来源"
                echo
                echo "HF 仓库 $REPO 本身不含 .py 文件，以下代码取自 transformers 主干："
                echo "- 来源: https://github.com/huggingface/transformers/tree/$TF_SHA/src/transformers/models/$MODEL_TYPE"
                echo "- 拉取日期: $(date +%F), commit $TF_SHA"
            } > "$DIR/SOURCE.md"
        else
            echo "⚠️  transformers 主干未收录 model_type=$MODEL_TYPE（可能尚未合入或需要自定义代码）"
        fi
    fi
fi

echo "✅ 全部非权重文件已下载到：$(realpath "$DIR")"
