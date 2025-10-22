let s:save_cpo = &cpo
set cpo&vim


if has('*base64_encode') && has('*str2blob')
  function! clipboard#base64#encode(str) abort " {{{
    return base64_encode(str2blob([a:str]))
  endfunction " }}}
elseif has('lua') || (has('nvim') && exists('*luaeval') && luaeval('vim.api ~= nil'))
  function! clipboard#base64#encode(str) abort " {{{
    return clipboard#lua#base64#encode(a:str)
  endfunction " }}}
elseif has('vim9script')
  function! clipboard#base64#encode(str) abort " {{{
    return clipboard#vim9#base64#Encode(a:str)
  endfunction " }}}
else
  function! clipboard#base64#encode(str) abort " {{{
    return clipboard#vim#base64#encode(a:str)
  endfunction " }}}
endif


let &cpo = s:save_cpo
unlet s:save_cpo
