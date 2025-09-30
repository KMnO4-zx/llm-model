# LLM Model Analysis

这个项目用于下载和分析 Hugging Face 上的大型语言模型（LLM）代码（不包含权重文件），便于学习和研究模型架构。

## 功能特点

- 📥 自动下载 Hugging Face 模型仓库的非权重文件
- 📚 获取模型配置、Tokenizer 和推理代码
- 🔍 支持分析模型架构和实现细节
- 🚀 使用国内镜像加速下载

## 使用方法

### 运行下载脚本

```bash
bash model_code.sh
```

脚本会提示您输入要下载的模型仓库路径，例如：

- `deepseek-ai/DeepSeek-V3.2-Exp`
- `meituan-longcat/LongCat-Flash-Chat`


