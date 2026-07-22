" ============================================================================
" vim-sensei —— autoload core
" 用自然语言问 vim: 描述一个编辑目标, AI 教你地道的按键手法。
" ============================================================================
" 所有配置项 (g:sensei_*) 在 plugin/sensei.vim 里给默认值。
" API key 从环境变量读取 (g:sensei_api_key_env, 默认 SENSEI_API_KEY), 绝不硬编码。

let s:prompt = join([
  \ '你是一位 Vim/vi 编辑教练, 面向想练熟 vim 的用户。用户会用自然语言描述一个编辑目标',
  \ '(如: 删到行尾、复制一段、把光标移到函数末尾、把双引号换成单引号、大写一个单词)。',
  \ '你要教他"地道且高效"的按键序列, 强调 operator + motion / text-object 的组合思路, 而不是笨办法。',
  \ '只返回一个 JSON 对象, 不要代码块, 不要多余文字, 严格如下字段:',
  \ '{',
  \ '  "keys": "<最推荐的一串按键, 用户在普通模式直接敲, 如 dw / ci\" / y4j / ggVG>",',
  \ '  "mode": "<normal 或 insert 或 visual —— 敲这串键前应处于的模式, 一般 normal>",',
  \ '  "explain": "<把按键逐段拆开讲: 每个字母/符号是什么含义, 为什么这样组合>",',
  \ '  "alt": "<1-2 个等效或相关做法, 一句话, 没有就空串>",',
  \ '  "tip": "<一句举一反三的心法, 如: 换成 c 就是删了进插入模式, 换 motion 就能作用到别处>",',
  \ '  "safe_demo": <true 仅当这串键是纯普通模式、可被 u 撤销、不进插入模式、不需要用户补输入; 否则 false>',
  \ '}',
  \ '按键里出现的双引号要转义。keys 用真实 vim 记号 (<Esc> 就写 <Esc>, 空格就写空格)。'
  \ ], "\n")

function! s:err(msg) abort
  echohl ErrorMsg | echom 'sensei: ' . a:msg | echohl None
endfunction

function! s:strip(s) abort
  " 去掉可能的 ```json / ``` 代码块包裹和首尾空白
  let l:t = substitute(a:s, '```json', '', 'g')
  let l:t = substitute(l:t, '```', '', 'g')
  return trim(l:t)
endfunction

" 取语言指令: 让讲解用用户设定的语言 (默认中文)
function! s:lang_clause() abort
  let l:lang = get(g:, 'sensei_language', '中文')
  return "\n始终用" . l:lang . '讲解 (keys 字段保持原样按键)。'
endfunction

" 调 OpenAI 兼容网关, 返回 assistant 文本; 出错返回空串并已报错。
function! sensei#chat(user) abort
  let l:key = ''
  let l:envname = get(g:, 'sensei_api_key_env', 'SENSEI_API_KEY')
  if !empty(get(g:, 'sensei_api_key', ''))
    let l:key = g:sensei_api_key
  elseif !empty($SENSEI_API_KEY) && l:envname ==# 'SENSEI_API_KEY'
    let l:key = $SENSEI_API_KEY
  else
    let l:key = eval('$' . l:envname)
  endif
  if empty(l:key)
    call s:err('未设置 API key。请 export ' . l:envname . '=... 或在 vimrc 里 let g:sensei_api_key = "..."')
    return ''
  endif

  if !executable('curl')
    call s:err('找不到 curl, 请先安装 curl 并加入 PATH')
    return ''
  endif

  let l:payload = {
    \ 'model': g:sensei_model,
    \ 'temperature': 0,
    \ 'max_tokens': get(g:, 'sensei_max_tokens', 500),
    \ 'messages': [
    \   {'role': 'system', 'content': s:prompt . s:lang_clause()},
    \   {'role': 'user', 'content': a:user},
    \ ]}
  let l:tmp = tempname()
  call writefile([json_encode(l:payload)], l:tmp)

  " 用字符串命令 + shellescape: 跨平台由各自 shell 处理 (Windows cmd.exe / *nix sh)
  let l:cmd = 'curl -s -m ' . get(g:, 'sensei_timeout', 30) . ' '
    \ . shellescape(g:sensei_endpoint)
    \ . ' -H ' . shellescape('Content-Type: application/json')
    \ . ' -H ' . shellescape('Authorization: Bearer ' . l:key)
    \ . ' -d @' . shellescape(l:tmp)
  let l:raw = system(l:cmd)
  call delete(l:tmp)

  if v:shell_error != 0 || empty(l:raw)
    call s:err('网关请求失败 (检查 g:sensei_endpoint 是否可达)')
    return ''
  endif
  try
    let l:resp = json_decode(l:raw)
    return s:strip(l:resp.choices[0].message.content)
  catch
    call s:err('无法解析网关返回: ' . l:raw[0:200])
    return ''
  endtry
endfunction

" 按屏宽输出带标签的多行文本
function! s:echo_block(label, text, hl) abort
  if empty(a:text) | return | endif
  execute 'echohl ' . a:hl
  for l:line in split(a:text, "\n")
    echo a:label . l:line
  endfor
  echohl None
endfunction

" 主入口: :Sensei / :How <自然语言>
function! sensei#how(request) abort
  if empty(trim(a:request))
    call s:err('描述一个编辑目标, 比如 "删除到行尾" 或 "复制这个函数"')
    return
  endif
  echo 'sensei 思考中...'
  let l:content = sensei#chat(a:request)
  if empty(l:content) | return | endif
  try
    let l:t = json_decode(l:content)
  catch
    call s:err('无法解析返回: ' . l:content[0:200])
    return
  endtry

  redraw
  echohl Title | echo 'Keys:  ' . get(l:t, 'keys', '') . '   [' . get(l:t, 'mode', 'normal') . ']' | echohl None
  call s:echo_block('  ', get(l:t, 'explain', ''), 'Normal')
  call s:echo_block('alt:   ', get(l:t, 'alt', ''), 'Comment')
  call s:echo_block('tip:   ', get(l:t, 'tip', ''), 'MoreMsg')

  " 纯普通模式 + 可撤销 + 允许演示 => 提供 demo (feedkeys, 之后 u 撤销)
  if get(g:, 'sensei_demo', 1)
        \ && get(l:t, 'safe_demo', v:false) is v:true
        \ && get(l:t, 'mode', 'normal') ==# 'normal'
        \ && !empty(get(l:t, 'keys', ''))
    echo ''
    let l:yn = input('在光标处演示一次? 之后按 u 撤销 (y/n) ')
    if l:yn ==? 'y'
      redraw
      call feedkeys(l:t.keys, 'n')
    else
      redraw | echo '自己敲一遍最记得住 :)'
    endif
  endif
endfunction
