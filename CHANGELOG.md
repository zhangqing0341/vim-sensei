# Changelog

All notable changes to vim-sensei are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-07-22

First public release. 🎉

Ask vim in plain language — the AI teaches you the idiomatic keystrokes, breaks
down what each key does, and can demo safe operations at your cursor.

### Added
- **`:How` / `:Sensei` command** — describe an editing goal in plain language
  (e.g. `:How delete to end of line`) and get the idiomatic key sequence with a
  per-key breakdown, an equivalent alternative, and a takeaway tip.
- **One-time demo** — for pure normal-mode, undoable operations the plugin can
  run the keys at your cursor so you see the effect (undo with `u`). Operations
  that enter insert mode or have side effects are never auto-run.
- **`:SenseiSetup` wizard** — interactive setup with no vimrc editing: pick a
  backend (local Ollama / OpenAI / custom gateway), enter a key, choose where to
  store it, and pick the explanation language. Config is saved to `~/.sensei.vim`
  and auto-loaded on startup.
- **Zero-config local Ollama** — if no key is set and you're on the default
  endpoint, the plugin auto-detects `localhost:11434` and uses it key-free.
- **Bilingual explanations** — English by default; switch to Chinese in the
  wizard or via `let g:sensei_language = '中文'`.
- **Backend-agnostic** — works with any OpenAI-compatible `/chat/completions`
  endpoint (OpenAI, LiteLLM, Ollama, self-hosted).
- `<Leader>ah` default mapping and `<Plug>(sensei-how)` for custom maps.
- `:help sensei` documentation and bilingual READMEs.

### Security
- API keys are never hardcoded — read from an environment variable
  (`SENSEI_API_KEY`) or the wizard-managed config file. The wizard warns before
  writing a key in plaintext and offers an environment-variable option instead;
  on *nix the config file is `chmod 600`.

[0.1.0]: https://github.com/zhangqing0341/vim-sensei/releases/tag/v0.1.0
