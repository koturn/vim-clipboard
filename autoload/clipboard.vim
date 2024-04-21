" ============================================================================
" FILE: clipboard.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


function! clipboard#getclip(...) abort " {{{
  if has('clipboard')
    execute 'let text = ' . g:clipboard#clip_register
  elseif executable('getclip')
    let text = s:exec_getclip('getclip')
  elseif executable('pbpaste')
    let text = s:exec_getclip('pbpaste')
  elseif executable('wl-paste')
    let text = s:exec_getclip('wl-paste')
  elseif executable('xsel')
    let text = s:exec_getclip('xsel -b')
  elseif executable('xclip')
    let text = s:exec_getclip('xclip -o')
  elseif filereadable('/dev/clipboard')
    let text = join(readfile('/dev/clipboard'), "\n")
  else
    echoerr 'Unable to use command: GetClip'
    return
  endif
  execute 'let ' . (a:0 > 0 ? a:1 : g:clipboard#local_register) . ' = text'
endfunction " }}}

function! clipboard#putclip(...) abort " {{{
  execute 'let text = ' . (a:0 > 0 ? a:1 : g:clipboard#local_register)
  if has('clipboard')
    execute 'let ' . g:clipboard#clip_register . ' = text'
  elseif executable('putclip')
    call s:exec_putclip('putclip', text)
  elseif executable('pbcopy')
    call s:exec_putclip('pbcopy', text)
  elseif executable('wl-copy')
    call s:exec_putclip('wl-copy', text)
  elseif executable('xclip')
    call s:exec_putclip('xclip -i', text)
  elseif executable('xsel')
    call s:exec_putclip('xsel -bi', text)
  elseif executable('clip.exe')
    call s:exec_putclip('clip.exe', text)
  elseif executable('/mnt/c/Windows/System32/clip.exe')
    call s:exec_putclip('/mnt/c/Window/System32/clip.exe', text)
  elseif filewritable('/dev/clipboard')
    if writefile(split(text, '\n'), '/dev/clipboard') == -1
      echoerr 'Unable to write to /dev/clipboard'
    endif
  elseif g:clipboard#use_other_vim && executable(g:clipboard#other_vim)
    call s:putclip_with_other_vim(text)
  else
    echoerr 'Unable to use command: PutClip'
  endif
endfunction " }}}


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CAUTION: This function is unstable.                                         "
"   Unable to send too large text.                                            "
"   Unable to send texts which includes contorol-code.                        "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:putclip_with_other_vim(text) abort " {{{
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

function! s:exec_getclip_with_job(cmd) abort " {{{
  let id = job_start(a:cmd, {'mode': 'raw'})
  try
    let text = ch_readraw(id)
    while job_status(id) ==# 'run'
      let text .= ch_readraw(id)
    endwhile
    return text
  finally
    call ch_close(id)
  endtry
endfunction " }}}

function! s:_exec_getclip(cmd) abort " {{{
  if has('job')
    let s:exec_getclip = function('s:exec_getclip_with_job')
    return s:exec_getclip_with_job(a:cmd)
  else
    let s:exec_getclip = s:system
    return s:system(a:cmd)
  endif
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
    call s:exec_putclip_with_job(a:cmd, a:text)
  else
    try
      call function('vimproc#popen2')
      let s:exec_putclip = function('s:exec_putclip_with_vimproc')
      call s:exec_putclip_with_vimproc(a:cmd, a:text)
    catch /^Vim(call)\=:E117: .\+: vimproc#popen2$/
      let s:exec_putclip = function('system')
      call system(a:cmd, a:text)
    endtry
  endif
endfunction " }}}
let s:exec_putclip = function('s:_exec_putclip')

function! s:_system(...) abort " {{{
  try
    let s:system = function('vimproc#system')
    return call('vimproc#system', a:000)
  catch /^Vim(call)\=:E117: .\+: vimproc#system$/
    let s:system = function('system')
    return call('system', a:000)
  endtry
endfunction " }}}
let s:system = function('s:_system')

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


let &cpo = s:save_cpo
unlet s:save_cpo
