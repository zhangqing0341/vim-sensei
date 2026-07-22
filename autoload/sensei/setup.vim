" ============================================================================
" vim-sensei —— :SenseiSetup 交互式配置向导
" ============================================================================
" 引导用户选服务商 -> 填 key -> 把配置写进 g:sensei_config_file (默认 ~/.sensei.vim)。
" 该文件在启动时被 plugin/sensei.vim 自动 source。key 以明文存盘, 会明确告知用户。

function! s:cfg_path() abort
  return expand(get(g:, 'sensei_config_file', '~/.sensei.vim'))
endfunction

function! s:say(msg) abort
  echohl Title | echo a:msg | echohl None
endfunction

" 把配置写入配置文件 (覆盖)。lines: vimscript 行列表。
function! s:write_config(lines) abort
  let l:path = s:cfg_path()
  let l:header = [
    \ '" vim-sensei 配置 —— 由 :SenseiSetup 生成',
    \ '" 注意: 此文件可能含明文 API key, 已加入 gitignore 思路, 请勿提交到版本库。',
    \ '']
  call writefile(l:header + a:lines, l:path)
  " *nix 下收紧权限 (Windows 无 chmod, 忽略)
  if !has('win32') && exists('*setfperm')
    call setfperm(l:path, 'rw-------')
  endif
  return l:path
endfunction

" 立即把配置生效 (免得用户重启 vim)
function! s:apply(dict) abort
  for [l:k, l:v] in items(a:dict)
    execute 'let g:sensei_' . l:k . ' = ' . string(l:v)
  endfor
endfunction

" 选项 A: 本地 Ollama (免 key)
function! s:setup_ollama() abort
  let l:url = input('Ollama 地址 (默认 http://127.0.0.1:11434): ')
  if empty(l:url) | let l:url = 'http://127.0.0.1:11434' | endif
  let l:model = input('模型名 (默认 qwen2.5-coder): ')
  if empty(l:model) | let l:model = 'qwen2.5-coder' | endif
  redraw
  echo '正在探测 Ollama...'
  let g:sensei_ollama_url = l:url
  let s:probe = system('curl -s -m 3 -o ' . (has('win32') ? 'NUL' : '/dev/null')
    \ . ' ' . shellescape(l:url . '/api/tags'))
  if v:shell_error != 0
    echohl WarningMsg
    echo '⚠ 连不上 Ollama。请确认已安装并运行 (ollama serve), 且拉取过模型 (ollama pull ' . l:model . ')。'
    echo '  配置仍会写入, 等 Ollama 起来后即可用。'
    echohl None
  endif
  let l:cfg = {
    \ 'endpoint': l:url . '/v1/chat/completions',
    \ 'model': l:model}
  call s:apply(l:cfg)
  return [
    \ 'let g:sensei_endpoint = ' . string(l:cfg.endpoint),
    \ 'let g:sensei_model    = ' . string(l:cfg.model)]
endfunction

" 选项 B: OpenAI
function! s:setup_openai() abort
  let l:model = input('模型名 (默认 gpt-4o-mini): ')
  if empty(l:model) | let l:model = 'gpt-4o-mini' | endif
  let l:key = inputsecret('OpenAI API key (sk-...): ')
  if empty(l:key)
    echohl WarningMsg | echo '未输入 key, 取消。' | echohl None
    return []
  endif
  let l:cfg = {'endpoint': 'https://api.openai.com/v1/chat/completions', 'model': l:model}
  call s:apply(l:cfg)
  let g:sensei_api_key = l:key
  return s:key_storage_lines(l:key) + [
    \ 'let g:sensei_endpoint = ' . string(l:cfg.endpoint),
    \ 'let g:sensei_model    = ' . string(l:cfg.model)]
endfunction

" 选项 C: 自建 OpenAI 兼容网关 (LiteLLM 等)
function! s:setup_custom() abort
  let l:ep = input('网关地址 (完整 /chat/completions URL): ')
  if empty(l:ep)
    echohl WarningMsg | echo '未输入地址, 取消。' | echohl None
    return []
  endif
  let l:model = input('模型名: ')
  let l:key = inputsecret('API key (没有就直接回车): ')
  let l:cfg = {'endpoint': l:ep, 'model': l:model}
  call s:apply(l:cfg)
  let l:lines = [
    \ 'let g:sensei_endpoint = ' . string(l:ep),
    \ 'let g:sensei_model    = ' . string(l:model)]
  if !empty(l:key)
    let g:sensei_api_key = l:key
    let l:lines = s:key_storage_lines(l:key) + l:lines
  endif
  return l:lines
endfunction

" 询问 key 存哪: 存文件(明文) 或 提示用环境变量
function! s:key_storage_lines(key) abort
  redraw
  call s:say('key 存哪里?')
  echo '  1) 存进配置文件 (明文, 省事, 但别把该文件提交到 git)'
  echo '  2) 我自己设环境变量 (更安全, 需要你自行 export ' . get(g:, 'sensei_api_key_env', 'SENSEI_API_KEY') . ')'
  let l:c = input('选择 (1/2, 默认 1): ')
  if l:c ==# '2'
    redraw
    echohl MoreMsg
    echo '好的。请在 shell 里设置环境变量, 例如:'
    if has('win32')
      echo '  setx ' . get(g:, 'sensei_api_key_env', 'SENSEI_API_KEY') . ' "' . a:key . '"'
      echo '  (设完需重开终端/重启 vim 生效)'
    else
      echo '  export ' . get(g:, 'sensei_api_key_env', 'SENSEI_API_KEY') . '="' . a:key . '"'
      echo '  (写进 ~/.bashrc 或 ~/.zshrc 以持久化)'
    endif
    echohl None
    return []
  endif
  echohl WarningMsg
  echo '⚠ key 将以明文写入 ' . s:cfg_path() . ' —— 请勿提交到版本库。'
  echohl None
  return ['let g:sensei_api_key  = ' . string(a:key)]
endfunction

function! sensei#setup#run() abort
  redraw
  call s:say('=== vim-sensei 配置向导 ===')
  echo '选择你的 AI 后端:'
  echo '  1) 本地 Ollama    —— 免费、离线、免 key (需先装 Ollama)'
  echo '  2) OpenAI         —— 需要 API key'
  echo '  3) 自建网关       —— LiteLLM / 兼容 OpenAI 的任意接口'
  " 若探测到 Ollama 在跑, 提示一下
  if sensei#ollama_running()
    echohl MoreMsg | echo '(检测到本地 Ollama 正在运行, 选 1 可直接用)' | echohl None
  endif
  let l:choice = input('选择 (1/2/3): ')
  redraw

  if l:choice ==# '1'
    let l:lines = s:setup_ollama()
  elseif l:choice ==# '2'
    let l:lines = s:setup_openai()
  elseif l:choice ==# '3'
    let l:lines = s:setup_custom()
  else
    echohl WarningMsg | echo '无效选择, 已取消。' | echohl None
    return
  endif

  if empty(l:lines)
    return
  endif

  let l:path = s:write_config(l:lines)
  redraw
  echohl Title | echo '✓ 配置已保存到 ' . l:path | echohl None
  echo '现在就能用了, 试试:  :How 删除到行尾'
endfunction
