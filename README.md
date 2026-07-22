# vim-sensei

**English** | [简体中文](README.zh-CN.md)

Ask vim in plain language — the AI teaches you the idiomatic keystrokes.

Describe an editing goal and vim-sensei returns the most idiomatic key sequence, breaks down what each key does, and offers related tricks plus a takeaway. For pure normal-mode, undoable operations it can even **demo it once** at your cursor (undo with `u`).

The goal is to make you *better at vim through practice* — not to press the keys for you.

```
:How delete to end of line

Keys:  D   [normal]
  D is shorthand for d$: d (delete operator) + $ (motion to end of line).
alt:   d$ spells it out explicitly
tip:   d pairs with any motion. Swap in c to delete-and-insert; y to yank.
Demo it once at the cursor? undo with u afterwards (y/n)
```

## Requirements

- Vim 8+ (needs `json_encode()` / `json_decode()`)
- `curl` on your `PATH`
- An OpenAI-compatible `/chat/completions` endpoint (OpenAI / LiteLLM / Ollama / ...)

## Installation

vim-plug:

```vim
Plug 'zhangqing0341/vim-sensei'
```

## Configuration

The easiest way — run the setup wizard after installing. It's fully interactive and writes the config for you:

```vim
:SenseiSetup
```

The wizard offers three choices: **local Ollama** (free, offline, no key), **OpenAI** (paste a key), or a **custom gateway** (LiteLLM, etc.). Config is saved to `~/.sensei.vim` and auto-loaded on the next launch — no need to touch your vimrc.

### True zero-config: local Ollama

If you have [Ollama](https://ollama.com) installed and a model pulled:

```sh
ollama pull qwen2.5-coder
```

vim-sensei **auto-detects** `localhost:11434` — nothing to configure, `:How` just works, no key, fully offline.

### Manual configuration

You can also set it in your vimrc directly. Prefer an environment variable for the API key (keeps it out of version control):

```sh
export SENSEI_API_KEY="sk-..."
```

```vim
" OpenAI (uses the default endpoint)
let g:sensei_model = 'gpt-4o-mini'

" Self-hosted LiteLLM gateway
let g:sensei_endpoint = 'http://127.0.0.1:4000/v1/chat/completions'
let g:sensei_model    = 'claude-haiku-4-5'

" Local Ollama
let g:sensei_endpoint = 'http://127.0.0.1:11434/v1/chat/completions'
let g:sensei_model    = 'qwen2.5-coder'
```

## Usage

| Command / mapping | What it does |
|-------------------|--------------|
| `:How <plain language>` | Describe an editing goal, get a keystroke breakdown |
| `:Sensei <plain language>` | Same thing (alias) |
| `:SenseiSetup` | Interactive setup wizard |
| `<Leader>ah` | Prompt for a goal in normal mode |

```
:How yank this whole line
:How replace everything inside the double quotes
:How select the current paragraph
:How move the cursor to the last line of the file
```

## Options

| Variable | Default | Description |
|----------|---------|-------------|
| `g:sensei_endpoint` | OpenAI | OpenAI-compatible endpoint URL |
| `g:sensei_model` | `gpt-4o-mini` | Model name |
| `g:sensei_api_key_env` | `SENSEI_API_KEY` | Env var name to read the key from |
| `g:sensei_api_key` | — | Key set directly (takes precedence over env var) |
| `g:sensei_language` | `English` | Explanation language; set to `中文` for Chinese. `:SenseiSetup` asks this too |
| `g:sensei_demo` | `1` | Whether to offer the one-time demo |
| `g:sensei_map_default` | `1` | Whether to create the `<Leader>ah` mapping |
| `g:sensei_config_file` | `~/.sensei.vim` | File the wizard writes / that's auto-loaded on startup |
| `g:sensei_ollama_url` | `http://127.0.0.1:11434` | Local Ollama address (for auto-detection) |
| `g:sensei_ollama_model` | `qwen2.5-coder` | Fallback model when using Ollama |
| `g:sensei_timeout` | `30` | curl timeout in seconds |
| `g:sensei_max_tokens` | `500` | Max tokens in the reply |

Run `:help sensei` for the full documentation.

## How it works

Pure Vimscript, no dependencies beyond curl. The request body is written to a temp file with `json_encode()`, POSTed to the gateway via `curl -d @file`, and parsed with `json_decode()`. The demo uses `feedkeys()` and is only offered for keys the AI marks as pure normal-mode and undoable (`safe_demo=true`), so operations with side effects are never triggered automatically.

If no key is configured and you're still on the default OpenAI endpoint, the plugin probes for a local Ollama instance and uses it key-free when found; otherwise it points you to `:SenseiSetup`.

## License

MIT
