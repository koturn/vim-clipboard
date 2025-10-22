local base64 = {}
local b64table = {
  [0] = 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
  'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
}


function base64.encode(str)
  local rem = #str % 3
  local nren = #str - rem
  local b64 = {}

  local j = 1
  for i = 1, nren, 3 do
    local n = str:byte(i) * 0x10000 + str:byte(i + 1) * 0x100 + str:byte(i + 2)
    b64[j] = b64table[math.floor(n / 0x40000)]
    b64[j + 1] = b64table[math.floor(n / 0x1000) % 0x40]
    b64[j + 2] = b64table[math.floor(n / 0x40) % 0x40]
    b64[j + 3] = b64table[n % 0x40]
    j = j + 4
  end
  local i = nren + 1
  if rem == 2 then
    local n = str:byte(i) * 0x10000 + str:byte(i + 1) * 0x100
    b64[j] = b64table[math.floor(n / 0x40000)]
    b64[j + 1] = b64table[math.floor(n / 0x1000) % 0x40]
    b64[j + 2] = b64table[math.floor(n / 0x40) % 0x40]
    b64[j + 3] = '='
  elseif rem == 1 then
    local n = str:byte(i) * 0x10000
    b64[j] = b64table[math.floor(n / 0x40000)]
    b64[j + 1] = b64table[math.floor(n / 0x1000) % 0x40]
    b64[j + 2] = '='
    b64[j + 3] = '='
  end

  return table.concat(b64)
end


return base64
