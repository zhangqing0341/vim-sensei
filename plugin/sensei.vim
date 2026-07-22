" ============================================================================
" vim-sensei —— 用自然语言问 vim, AI 教你地道的编辑手法
" https://github.com/zhangqing0341/vim-sensei
" ============================================================================

if exists('g:loaded_sensei')
  finish
endif
let g:loaded_sensei = 1

" ---- 配置默认值 (在 vimrc 里覆盖) ----
" 网关地址 (任意 OpenAI 兼容 /chat/completions 接口: OpenAI / LiteLLM / Ollama 等)
if !exists('g:sensei_endpoint')
  let g:sensei_endpoint = 'https://api.openai.com/v1/chat/completions'
endif
" 模型名
if !exists('g:sensei_model')
  let g:sensei_model = 'gpt-4o-mini'
endif
" 读 API key 的环境变量名 (绝不硬编码 key)。也可直接 let g:sensei_api_key = '...'
if !exists('g:sensei_api_key_env')
  let g:sensei_api_key_env = 'SENSEI_API_KEY'
endif
" 讲解语言
if !exists('g:sensei_language')
  let g:sensei_language = '中文'
endif
" 是否允许"演示一次" (纯普通模式且可撤销的按键)
if !exists('g:sensei_demo')
  let g:sensei_demo = 1
endif
" 是否创建默认映射 <Leader>ah
if !exists('g:sensei_map_default')
  let g:sensei_map_default = 1
endif

" ---- 命令 ----
command! -nargs=+ Sensei call sensei#how(<q-args>)
command! -nargs=+ How    call sensei#how(<q-args>)

" ---- 默认映射 (<Plug> 可自定义) ----
nnoremap <silent> <Plug>(sensei-how) :call sensei#how(input('怎么操作> '))<CR>
if g:sensei_map_default && !hasmapto('<Plug>(sensei-how)') && empty(maparg('<Leader>ah', 'n'))
  nmap <Leader>ah <Plug>(sensei-how)
endif
