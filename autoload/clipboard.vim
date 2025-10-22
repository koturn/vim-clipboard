" ============================================================================
" FILE: clipboard.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


function! clipboard#getclip(...) abort " {{{
  let method = get(g:, 'clipboard#getclip_method', '')
  if method ==# ''
    let g:clipboard#getclip_method = s:identify_getclip_method()
    let method = g:clipboard#getclip_method
  endif
  execute 'let' (a:0 > 0 ? a:1 : g:clipboard#local_register) '= s:getclip_method_dict[method]()'
endfunction " }}}

function! clipboard#putclip(...) abort " {{{
  let method = get(g:, 'clipboard#putclip_method', '')
  if method ==# ''
    let g:clipboard#putclip_method = s:identify_putclip_method()
    let method = g:clipboard#putclip_method
  endif
  execute 'let text =' (a:0 > 0 ? a:1 : g:clipboard#local_register)
  call s:putclip_method_dict[method](text)
endfunction " }}}


function! s:identify_getclip_method() abort " {{{
  if has('clipboard')
    return 'register'
  elseif executable('getclip')
    return 'getclip'
  elseif executable('pbpaste')
    return 'pbpaste'
  elseif executable('wl-paste')
    return 'wl-paste'
  elseif executable('xsel')
    return 'xsel'
  elseif executable('xclip')
    return 'xclip'
  elseif filereadable('/dev/clipboard')
    return 'dev_clipboard'
  endif
  throw '[vim-clipboard] Not available any of getclip method'
endfunction " }}}

function! s:getclip_register() abort " {{{
  return eval(g:clipboard#clip_register)
endfunction " }}}

function! s:getclip_getclip() abort " {{{
  return s:exec_getclip('getclip')
endfunction " }}}

function! s:getclip_pbpaste() abort " {{{
  return s:exec_getclip('pbpaste')
endfunction " }}}

function! s:getclip_wlpaste() abort " {{{
  return s:exec_getclip('wl-paste')
endfunction " }}}

function! s:getclip_xsel() abort " {{{
  return s:exec_getclip('xsel -b')
endfunction " }}}

function! s:getclip_xclip() abort " {{{
  return s:exec_getclip('xclip -o')
endfunction " }}}

function! s:getclip_dev_clipboard() abort " {{{
  return join(readfile('/dev/clipboard'), "\n")
endfunction " }}}

function! s:identify_putclip_method() abort " {{{
  if has('clipboard')
    return 'register'
  elseif executable('putclip')
    return 'putclip'
  elseif executable('pbcopy')
    return 'pbcopy'
  elseif executable('wl-copy')
    return 'wlcopy'
  elseif executable('xsel')
    return 'xsel'
  elseif executable('xclip')
    return 'xclip'
  elseif s:get_clipexe_path() !=# ''
    return 'clip'
  elseif filewritable('/dev/clipboard')
    return 'dev_clipboard'
  elseif has('*echoraw') || has('*chansend') || filewritable('/dev/tty') || filewritable('/dev/fd/1')
    return 'osc52'
  elseif executable(g:clipboard#other_vim)
    return 'gvim_server'
  endif
  throw '[vim-clipboard] Not available any of putclip method'
endfunction " }}}

function! s:putclip_register(text) abort " {{{
  execute 'let' g:clipboard#clip_register '= a:text'
endfunction " }}}

function! s:putclip_putclip(text) abort " {{{
  call s:exec_putclip('putclip', a:text)
endfunction " }}}

function! s:putclip_pbcopy(text) abort " {{{
  call s:exec_putclip('pbcopy', a:text)
endfunction " }}}

function! s:putclip_wlcopy(text) abort " {{{
  call s:exec_putclip('wl-copy', a:text)
endfunction " }}}

function! s:putclip_xsel(text) abort " {{{
  call s:exec_putclip('xsel -bi', a:text)
endfunction " }}}

function! s:putclip_xclip(text) abort " {{{
  call s:exec_putclip('xclip -i', a:text)
endfunction " }}}

function! s:putclip_clip(text) abort " {{{
  call s:exec_putclip(s:get_clipexe_path(), a:text)
endfunction " }}}

function! s:putclip_osc52(text) abort " {{{
  call s:write_to_stdout(printf("\e]52;c;%s\e\\", clipboard#base64#encode(a:text)))
endfunction " }}}

function! s:putclip_dev_clipboard(text) abort " {{{
  if writefile(split(text, "\n"), '/dev/clipboard') == -1
    throw '[vim-clipboard] Failed to write to /dev/clipboard'
  endif
endfunction " }}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CAUTION: This function is unstable.                                         "
"   Unable to send too large text.                                            "
"   Unable to send texts which includes contorol-code.                        "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:putclip_gvim_server(text) abort " {{{
  let text = substitute(a:text, '\', "\x0c", 'g')
  let text = substitute(text, "\'", "\x01", 'g')
  let text = substitute(text, '\"', "\x02", 'g')
  let text = substitute(text, "[\n\r]", "\x0b", 'g')
  call s:system_bg(g:clipboard#other_vim . ' '
        \ . g:clipboard#other_vim_opt
        \ . ' -c "let t = \"' . text . '\""'
        \ . ' -c "let t = substitute(t, \"\\x0c\", \"\\x5c\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x01\", \"\\x27\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x02\", \"\\x22\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x0b\", \"\\n\",   \"g\")"'
        \ . ' -c "let ' . g:clipboard#clip_register . ' = t"'
        \ . ' -c quitall!')
endfunction " }}}

let s:getclip_method_dict = extend({
      \ 'register': function('s:getclip_register'),
      \ 'getclip': function('s:getclip_getclip'),
      \ 'pbpaste': function('s:getclip_pbpaste'),
      \ 'wlpaste': function('s:getclip_wlpaste'),
      \ 'xsel': function('s:getclip_xsel'),
      \ 'xclip': function('s:getclip_xclip'),
      \ 'dev_clipboard': function('s:getclip_dev_clipboard'),
      \}, get(g:, 'clipboard#getclip_method_dict', {}))

let s:putclip_method_dict = extend({
      \ 'register': function('s:putclip_register'),
      \ 'putclip': function('s:putclip_putclip'),
      \ 'pbcopy': function('s:putclip_pbcopy'),
      \ 'wlcopy': function('s:putclip_wlcopy'),
      \ 'xsel': function('s:putclip_xsel'),
      \ 'xclip': function('s:putclip_xclip'),
      \ 'clip': function('s:putclip_clip'),
      \ 'dev_clipboard': function('s:putclip_dev_clipboard'),
      \ 'osc52': function('s:putclip_osc52'),
      \ 'gvim_server': function('s:putclip_gvim_server')
      \}, get(g:, 'clipboard#putclip_method_dict', {}))

let s:clipexe_path = ''
function! s:get_clipexe_path() abort " {{{
  if s:clipexe_path !=# ''
    return s:clipexe_path
  endif
  for cmd in ['clip.exe', '/mnt/c/Windows/System32/clip.exe', '/c/Windows/System32/clip.exe']
    let s:clipexe_path = cmd
  endfor
  return s:clipexe_path
endfunction " }}}

function! s:exec_getclip_with_job(cmd) abort " {{{
  let id = job_start(a:cmd, {'mode': 'raw'})
  try
    let text = ch_readraw(id)
    while job_status(id) ==# 'run'
      sleep 1m
      let text .= ch_readraw(id)
    endwhile
  finally
    call ch_close(id)
  endtry
  return text
endfunction " }}}

function! s:exec_getclip_with_vimproc(cmd) abort " {{{
  let handle = vimproc#popen2(a:cmd)
  try
    let text = handle.stdout.read()
    while !handle.stdout.eof
      let text .= handle.stdout.read()
    endwhile
    return text
  finally
    call vimproc#kill(handle, g:vimproc#SIGKILL)
  endtry
endfunction " }}}

function! s:_exec_getclip(cmd) abort " {{{
  if has('job')
    let s:exec_getclip = function('s:exec_getclip_with_job')
  else
    try
      let s:exec_getclip = function('s:exec_getclip_with_vimproc')
    catch /^Vim(call)\=:E117: .\+: vimproc#popen2$/
      let s:exec_getclip = function('system')
    endtry
  endif
  call s:exec_getclip(a:cmd)
endfunction " }}}
let s:exec_getclip = function('s:_exec_getclip')

function! s:exec_putclip_with_job(cmd, text) abort " {{{
  let id = job_start(a:cmd)
  try
    call ch_sendraw(id, a:text)
  finally
    call ch_close(id)
  endtry
endfunction " }}}

function! s:exec_putclip_with_vimproc(cmd, text) abort " {{{
  let handle = vimproc#popen2(a:cmd)
  try
    call handle.stdin.write(a:text)
    call handle.stdin.close()
  catch
    call vimproc#kill(handle, g:vimproc#SIGKILL)
  endtry
endfunction " }}}

function! s:_exec_putclip(cmd, text) abort " {{{
  if has('job')
    let s:exec_putclip = function('s:exec_putclip_with_job')
  else
    try
      let s:exec_putclip = function('s:exec_putclip_with_vimproc')
    catch /^Vim(call)\=:E117: .\+: vimproc#popen2$/
      let s:exec_putclip = function('system')
    endtry
  endif
  call s:exec_putclip(a:cmd, a:text)
endfunction " }}}
let s:exec_putclip = function('s:_exec_putclip')

function! s:_system_bg(cmd) abort " {{{
  if &rtp =~# 'vimproc'
    let s:system_bg = function('vimproc#system_bg')
    return vimproc#system_bg(a:cmd)
  else
    let s:system_bg = function('system')
    return system(a:cmd)
  endif
endfunction " }}}
let s:system_bg = function('s:_system_bg')

function! s:_write_to_stdout(text) abort " {{{
  if has('*echoraw')
    let s:write_to_stdout = function('s:_write_to_stdout_echoraw')
  elseif has('*chansend')
    let s:write_to_stdout = function('s:_write_to_stdout_chansend')
  elseif filewritable('/dev/tty')
    let s:write_to_stdout = function('s:_write_to_stdout_dev_tty')
  elseif filewritable('/dev/fd/1')
    let s:write_to_stdout = function('s:_write_to_stdout_dev_fd1')
  else
    throw '[vim-clipboard] Writing to stdout is unsupported'
  endif
  call s:write_to_stdout(a:text)
endfunction " }}}
let s:write_to_stdout = function('s:_write_to_stdout')

" For Vim.
function! s:_write_to_stdout_echoraw(text) abort " {{{
  call echoraw(a:text)
endfunction " }}}

" For neovim.
function! s:_write_to_stdout_chansend(text) abort " {{{
  if chansend(v:stdout, a:text) <= 0
    throw '[vim-clipboard] chansend() failed'
  endif
endfunction " }}}

function! s:_write_to_stdout_dev_tty(text) abort " {{{
  if writefile([a:text], '/dev/tty', 'ab') == -1
    throw '[vim-clipboard] Failed to write to /dev/tty'
  endif
endfunction " }}}

function! s:_write_to_stdout_dev_fd1(text) abort " {{{
  if writefile([a:text], '/dev/fd/1', 'ab') == -1
    throw '[vim-clipboard] Failed to write to /dev/fd/1'
  endif
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
