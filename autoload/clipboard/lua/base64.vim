let s:save_cpo = &cpo
set cpo&vim

if !has('lua') && !(has('nvim') && exists('*luaeval') && luaeval('vim.api ~= nil'))
  throw 'This script requires lua support!'
  finish
endif

let s:FILE_DIR = expand('<sfile>:h')


lua << __EOF__
Clipboard = {}

if vim.api ~= nil then
  Clipboard.vim_eval = vim.api.nvim_eval
else
  Clipboard.vim_eval = vim.eval
end

local script_dir = Clipboard.vim_eval('s:FILE_DIR')
if _VERSION >= 'Lua 5.3' then
  Clipboard.Base64 = dofile(script_dir .. '/base64_lua53.lua')
else
  Clipboard.Base64 = dofile(script_dir .. '/base64.lua')
end
__EOF__


function! clipboard#lua#base64#encode(str) abort " {{{
  return luaeval('Clipboard.Base64.encode(Clipboard.vim_eval("a:str"))')
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
