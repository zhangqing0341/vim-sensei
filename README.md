# vim-sensei

用自然语言问 vim，AI 教你地道的编辑手法。

描述一个编辑目标，vim-sensei 返回最地道的按键序列，把每个键拆开讲解，给出等效做法和举一反三的心法。对纯普通模式、可撤销的操作，还能在光标处**演示一次**（之后按 `u` 撤销）。

目标是让你「在实践中越来越会用 vim」，而不是替你按键。

```
:How 删除到行尾

Keys:  D   [normal]
  D 是 d$ 的快捷键：d(删除 operator) + $(到行尾的 motion)。
alt:   也可以显式写 d$
tip:   d 配合任何 motion 都能删除。换成 c 就是删了进插入模式；y 就是复制。
在光标处演示一次? 之后按 u 撤销 (y/n)
```

## 依赖

- Vim 8+（需要 `json_encode()` / `json_decode()`）
- `curl` 在 PATH 中
- 一个 OpenAI 兼容的 `/chat/completions` 接口（OpenAI / LiteLLM / Ollama 等）

## 安装

vim-plug：

```vim
Plug 'zhangqing0341/vim-sensei'
```

## 配置

API key 默认从环境变量读取（不硬编码、不入库）：

```sh
export SENSEI_API_KEY="sk-..."
```

vimrc（OpenAI，用默认端点）：

```vim
let g:sensei_model = 'gpt-4o-mini'
```

自建 LiteLLM 网关：

```vim
let g:sensei_endpoint = 'http://127.0.0.1:4000/v1/chat/completions'
let g:sensei_model    = 'claude-haiku-4-5'
```

本地 Ollama：

```vim
let g:sensei_endpoint = 'http://127.0.0.1:11434/v1/chat/completions'
let g:sensei_model    = 'qwen2.5-coder'
```

## 用法

| 命令 / 映射 | 作用 |
|-------------|------|
| `:How <自然语言>` | 描述编辑目标，得到按键讲解 |
| `:Sensei <自然语言>` | 同上（别名） |
| `<Leader>ah` | 普通模式弹出输入框 |

```
:How 复制当前这一整行
:How 把双引号里的内容整个替换掉
:How 选中当前段落
:How 把光标移到文件最后一行
```

## 选项

| 变量 | 默认 | 说明 |
|------|------|------|
| `g:sensei_endpoint` | OpenAI | OpenAI 兼容接口地址 |
| `g:sensei_model` | `gpt-4o-mini` | 模型名 |
| `g:sensei_api_key_env` | `SENSEI_API_KEY` | 读 key 的环境变量名 |
| `g:sensei_api_key` | — | 直接指定 key（优先于环境变量） |
| `g:sensei_language` | `中文` | 讲解语言，改成 `English` 即英文 |
| `g:sensei_demo` | `1` | 是否允许演示一次 |
| `g:sensei_map_default` | `1` | 是否创建默认映射 `<Leader>ah` |
| `g:sensei_timeout` | `30` | curl 超时秒数 |
| `g:sensei_max_tokens` | `500` | 回复最大 token |

`:help sensei` 查看完整文档。

## 工作原理

纯 Vimscript，无外部依赖（除 curl）。请求体用 `json_encode()` 写入临时文件，`curl -d @file` POST 到网关，`json_decode()` 解析。演示用 `feedkeys()`，且仅对 AI 标记为纯普通模式、可撤销（`safe_demo=true`）的按键开放，避免误触发有副作用的操作。

## License

MIT
