vim9script

var has_bitshift: bool = false
try
  eval('1 << 1')
  has_bitshift = true
catch
endtry

var b64table = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
]


export def Encode(str: string): string # {{{
  return Encode_(str)
enddef # }}}


if !has_bitshift
  def Encode_(str: string): string # {{{
    var len: number = len(str)

    var rem: number = len % 3
    var nren: number = len - rem
    var b64: list<string> = repeat(['='], (len + 2) / 3 * 4)

    var i: number = 0
    var j: number = 0
    var n: number = 0
    while i < nren
      n = char2nr(strpart(str, i, 1)) * 0x10000 + char2nr(strpart(str, i + 1, 1)) * 0x100 + char2nr(strpart(str, i + 2, 1))
      b64[j] = b64table[n / 0x40000]
      b64[j + 1] = b64table[n / 0x1000 % 0x40]
      b64[j + 2] = b64table[n / 0x40 % 0x40]
      b64[j + 3] = b64table[n % 0x40]
      i += 3
      j += 4
    endwhile
    if rem == 2
      n = char2nr(strpart(str, i, 1)) * 0x10000 + char2nr(strpart(str, i + 1, 1)) * 0x100
      b64[j] = b64table[n / 0x40000]
      b64[j + 1] = b64table[n / 0x1000 % 0x40]
      b64[j + 2] = b64table[n / 0x40 % 0x40]
    elseif rem == 1
      n = char2nr(strpart(str, i, 1)) * 0x10000
      b64[j] = b64table[n / 0x40000]
      b64[j + 1] = b64table[n / 0x1000 % 0x40]
    endif
    return join(b64, '')
  enddef # }}}
  finish
endif


if has('*str2blob') && has('*blob2str')
  var nr_b64table: list<number> = map(b64table, (_, val) => char2nr(val))
  def Encode_(str: string): string # {{{
    var data: blob = str2blob(str)
    var len: number = len(data)
    var rem: number = len % 3
    var nren: number = len - rem
    var b64: blob = repeat([0z3d], (len + 2) / 3 * 4)

    var i: number = 0
    var j: number = 0
    var n: number = 0
    while i < nren
      n = or(data[i] << 16, or(data[i + 1] << 8, data[i + 2]))
      b64[j] = nr_b64table[n >> 18]
      b64[j + 1] = nr_b64table[and(n >> 12, 0x3f)]
      b64[j + 2] = nr_b64table[and(n >> 6, 0x3f)]
      b64[j + 3] = nr_b64table[and(n, 0x3f)]
      i += 3
      j += 4
    endwhile
    if rem == 2
      n = or(data[i] << 16, or(data[i + 1] << 8, data[i + 2]))
      b64[j] = nr_b64table[n >> 18]
      b64[j + 1] = nr_b64table[and(n >> 12, 0x3f)]
      b64[j + 2] = nr_b64table[and(n >> 6, 0x3f)]
    elseif rem == 1
      n = or(data[i] << 16, or(data[i + 1] << 8, data[i + 2]))
      b64[j] = nr_b64table[n >> 18]
      b64[j + 1] = nr_b64table[and(n >> 12, 0x3f)]
    endif
    return blob2str(b64)
  enddef # }}}
else
  def Encode_(str: string): string # {{{
    var len: number = len(str)

    var rem: number = len % 3
    var nren: number = len - rem
    var b64: list<string> = repeat(['='], (len + 2) / 3 * 4)

    var i: number = 0
    var j: number = 0
    var n: number = 0
    while i < nren
      n = or(char2nr(strpart(str, i, 1)) << 16, or(char2nr(strpart(str, i + 1, 1)) << 8, char2nr(strpart(str, i + 2, 1))))
      b64[j] = b64table[n >> 18]
      b64[j + 1] = b64table[and(n >> 12, 0x3f)]
      b64[j + 2] = b64table[and(n >> 6, 0x3f)]
      b64[j + 3] = b64table[and(n, 0x3f)]
      i += 3
      j += 4
    endwhile
    if rem == 2
      n = or(char2nr(strpart(str, i, 1)) << 16, char2nr(strpart(str, i + 1, 1)) << 8)
      b64[j] = b64table[n >> 18]
      b64[j + 1] = b64table[and(n >> 12, 0x3f)]
      b64[j + 2] = b64table[and(n >> 6, 0x3f)]
    elseif rem == 1
      n = char2nr(strpart(str, i, 1)) << 16
      b64[j] = b64table[n >> 18]
      b64[j + 1] = b64table[and(n >> 12, 0x3f)]
    endif
    return join(b64, '')
  enddef # }}}
endif
