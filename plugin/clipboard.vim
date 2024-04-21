" ============================================================================
" FILE: clipboard.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" ============================================================================
if exists('g:loaded_clipboard')
  finish
endif
let g:loaded_clipboard = 1
let s:save_cpo = &cpo
set cpo&vim


let g:clipboard#clipboard_register = get(g:, 'clipboard#clipboard_register', '@*')
let g:clipboard#use_other_vim      = get(g:, 'clipboard#use_other_vim', 1)
let g:clipboard#other_vim          = get(g:, 'clipboard#other_vim', 'gvim')
let g:clipboard#other_vim_opt      = get(g:, 'clipboard#other_vim_opt', '-N --noplugin -u NONE -U NONE -i NONE -n')
let g:clipboard#local_register     = get(g:, 'clipboard#local_register', '@"')
let g:clipboard#clip_register      = get(g:, 'clipboard#clip_register', '@*')
command! -bar -nargs=? -complete=var GetClip  call clipboard#getclip(<f-args>)
command! -bar -nargs=? -complete=var PutClip  call clipboard#putclip(<f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
