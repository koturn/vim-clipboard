" ============================================================================
" FILE: clipboard.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


function! clipboard#getclip() " {{{
  if has('clipboard')
    execute 'let ' . g:clipboard#local_register . ' = ' . g:clipboard#clip_register
  else
    if executable('getclip')
      let text = s:system('getclip')
    elseif executable('pbpaste')
      let text = s:system('pbpaste')
    elseif executable('wl-paste')
      let text = s:system('wl-paste')
    elseif filereadable('/dev/clipboard')
      let text = join(readfile('/dev/clipboard'), "\n")
    else
      echoerr 'Unable to use command: GetClip'
    endif
    execute 'let ' . g:clipboard#local_register . ' = text'
  endif
endfunction " }}}

function! clipboard#putclip(...) " {{{
  if a:0 == 0
    execute 'let text = ' . g:clipboard#local_register
  else
    let text = join(a:000, '')
  endif
  if has('clipboard')
    execute 'let ' . g:clipboard#clip_register . ' = text'
  elseif executable('putclip')
     call s:system('putclip', text)
   elseif executable('pbcopy')
     call s:system('pbcopy', text)
   elseif executable('wl-copy')
     call s:system('wl-copy', text)
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
function! s:putclip_with_other_vim(text) " {{{
  let text = substitute(a:text, '\',    "\x0c", 'g')
  let text = substitute(text, "\'",     "\x01", 'g')
  let text = substitute(text, '\"',     "\x02", 'g')
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

function! s:_system_bg(cmd) " {{{
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
