let s:save_cpo = &cpo
set cpo&vim

let s:b64table = [
      \ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
      \ 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
      \ 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
      \ 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
      \]


function! clipboard#vim#base64#encode(str) abort " {{{
  let data = map(range(strlen(a:str)), 'char2nr(a:str[v:key])')
  let rem = len(data) % 3
  let nlen = len(data) - rem
  let b64 = repeat(['='], (len(data) + 2) / 3 * 4)

  let [i, j] = [0, 0]
  while i < nlen
    let n = data[i] * 0x10000 + data[i + 1] * 0x100 + data[i + 2]
    let b64[j] = s:b64table[n / 0x40000]
    let b64[j + 1] = s:b64table[n / 0x1000 % 0x40]
    let b64[j + 2] = s:b64table[n / 0x40 % 0x40]
    let b64[j + 3] = s:b64table[n % 0x40]
    let i += 3
    let j += 4
  endwhile
  if rem == 2
    let n = data[i] * 0x10000 + data[i + 1] * 0x100
    let b64[j] = s:b64table[n / 0x40000]
    let b64[j + 1] = s:b64table[n / 0x1000 % 0x40]
    let b64[j + 2] = s:b64table[n / 0x40 % 0x40]
  elseif rem == 1
    let n = data[i] * 0x10000
    let b64[j] = s:b64table[n / 0x40000]
    let b64[j + 1] = s:b64table[n / 0x1000 % 0x40]
  endif
  return join(b64, '')
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
