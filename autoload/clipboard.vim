" ============================================================================
" FILE: clipboard.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim


function! clipboard#getclip()
  if has('clipboard')
    exec 'let ' . g:clipboard#local_register . ' = ' . g:clipboard#clip_register
  else
    if has('win32unix') || has('win16') || has('win32') || has('win64')
      call s:getclip_cygwin()
    elseif has('mac')
      call s:getclip_mac()
    else
      echoerr 'Unable to use command: GetClip'
    endif
  endif
endfunction

function! clipboard#putclip(...)
  if a:0 == 0
    exec 'let l:text = ' . g:clipboard#local_register
  else
    let l:text = ''
    for l:str in a:000
      let l:text .= l:str
    endfor
  endif
  if has('clipboard')
    exec 'let ' . g:clipboard#clip_register . ' = l:text'
  else
    if has('win32unix')
      call s:putclip_cygwin(l:text)
    elseif has('mac')
      call s:putclip_mac(l:text)
    else
      echoerr 'Unable to use command: PutClip'
    endif
  endif
endfunction


""" In Mac
if has('mac')
  function! s:getclip_mac()
    if executable('pbpaste')
      new
      setl buftype=nofile bufhidden=wipe noswapfile nobuflisted
      read !pbpaste
      silent normal! ggj0vG$hy
      bwipe
    else
      echoerr 'Unable to read from clipboard'
    endif
  endfunction

  function! s:putclip_mac(text)
    if executable('pbcopy') && executable('cat') && g:clipboard#use_tmpfile
      call s:putclip_with_tmpfile(a:text, 'pbcopy')
    elseif executable(g:clipboard#other_vim)
      call s:putclip_with_other_vim(a:text)
    else
      echoerr 'Unable to write to clipboard'
    endif
  endfunction
endif


""" In Cygwin
if has('win32unix') || has('win16') || has('win32') || has('win64')
  function! s:getclip_cygwin()
    if executable('getclip')
      new
      setl buftype=nofile bufhidden=wipe noswapfile nobuflisted
      read !getclip
      " if len(a:reg_name_list)
      "   for l:reg_name in a:reg_name_list
      "     exec 'silent normal! ggj0vG$h"' . l:reg_name . 'y'
      "   endfor
      " else
      silent normal! ggj0vG$hy
      " endif
      bwipe
    else
      echoerr 'Unable to read from clipboard'
    endif
  endfunction

  function! s:putclip_cygwin(text)
    if filewritable('/dev/clipboard')
      if writefile(split(a:text, '\n'), '/dev/clipboard') == -1
        echoerr 'Unable to write to /dev/clipboard'
      endif
    elseif executable('putclip') && executable('cat') && g:clipboard#use_tmpfile
      call s:putclip_with_tmpfile(a:text, 'putclip')
    elseif executable(g:clipboard#other_vim)
      call s:putclip_with_other_vim(a:text)
    else
      echoerr 'Unable to write to clipboard'
    endif
  endfunction
endif


function! s:putclip_with_tmpfile(text, cmd)
  let l:tmp = tempname()
  let l:str_list = split(a:text, '\n')
  if writefile(l:str_list, l:tmp) == -1
    echoerr 'Failed to make temporary file'
    return
  endif
  call s:system(0, 'cat ' . l:tmp. ' | ' . a:cmd)
  call delete(l:tmp)
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CAUTION: This function is unstable.                                         "
"   Unable to send too large text.                                            "
"   Unable to send texts which includes contorol-code.                        "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:putclip_with_other_vim(text)
  let l:text = substitute(a:text, '\',      "\x0c", 'g')
  let l:text = substitute(l:text, "\'",     "\x01", 'g')
  let l:text = substitute(l:text, '\"',     "\x02", 'g')
  let l:text = substitute(l:text, "[\n\r]", "\x0b", 'g')
  call s:system(1, g:clipboard#other_vim . ' '
        \ . g:clipboard#other_vim_opt
        \ . ' -c "let t = \"' . l:text . '\""'
        \ . ' -c "let t = substitute(t, \"\\x0c\", \"\\x5c\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x01\", \"\\x27\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x02\", \"\\x22\", \"g\")"'
        \ . ' -c "let t = substitute(t, \"\\x0b\", \"\\n\",   \"g\")"'
        \ . ' -c "let ' . g:clipboard#clip_register . ' = t"'
        \ . ' -c quitall!')
endfunction


function! s:system(is_background, cmd)
  " if exists('*vimproc#system')
  if &rtp =~# 'vimproc'
    if a:is_background
      call vimproc#system_bg(a:cmd)
    else
      call vimproc#system(a:cmd)
    endif
  else
    call system(a:cmd)
  endif
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
