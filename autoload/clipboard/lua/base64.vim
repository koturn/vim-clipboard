let s:save_cpo = &cpo
set cpo&vim

if !has('lua') && !(has('nvim') && exists('*luaeval') && luaeval('vim.api ~= nil'))
  throw 'This script requires lua support!'
  finish
endif

let s:FILE_DIR = expand('<sfile>:h')


lua << __EOF__
Clipboard = {}
if _VERSION >= 'Lua 5.3' then
  Clipboard.Base64 = dofile(vim.eval('s:FILE_DIR') .. '/base64_lua53.lua')
else
  Clipboard.Base64 = dofile(vim.eval('s:FILE_DIR') .. '/base64.lua')
end
__EOF__


function! clipboard#lua#base64#encode(str) abort " {{{
  return luaeval('Clipboard.Base64.encode(vim.eval("a:str"))')
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
