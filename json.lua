local json = {}

local escapes = {
  ['\b'] = '\\b',
  ['\f'] = '\\f',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
  ['\\'] = '\\\\',
  ['"'] = '\\"'
}
local function escape_str(s)
  return s:gsub("[%z\1-\31\\\"]", function(c)
    return escapes[c] or string.format("\\u%04x", c:byte())
  end)
end

function json.encode(v)
  local t = type(v)
  if t == "nil" then
    return "null"
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "string" then
    return '"' .. escape_str(v) .. '"'
  elseif t == "table" then
    local is_array = true
    local i = 1
    for k,_ in pairs(v) do
      if k ~= i then is_array = false break end
      i = i + 1
    end
    local res = {}
    if is_array then
      for i=1,#v do
        res[i] = json.encode(v[i])
      end
      return '[' .. table.concat(res, ',') .. ']'
    else
      for k,val in pairs(v) do
        res[#res+1] = json.encode(k) .. ':' .. json.encode(val)
      end
      return '{' .. table.concat(res, ',') .. '}'
    end
  else
    error('unsupported type: '..t)
  end
end

local pos
local str

local function error_at(msg)
  error(string.format('%s at position %d', msg, pos))
end

local function skip_ws()
  local _,e = str:find('^%s*', pos)
  pos = e + 1
end

local function parse_value()
  skip_ws()
  local c = str:sub(pos,pos)
  if c == '{' then
    pos = pos + 1
    local obj = {}
    skip_ws()
    if str:sub(pos,pos) == '}' then
      pos = pos + 1
      return obj
    end
    while true do
      skip_ws()
      if str:sub(pos,pos) ~= '"' then error_at('expected string for key') end
      local key = parse_string()
      skip_ws()
      if str:sub(pos,pos) ~= ':' then error_at('expected :') end
      pos = pos + 1
      obj[key] = parse_value()
      skip_ws()
      local ch = str:sub(pos,pos)
      if ch == '}' then pos = pos + 1 break
      elseif ch ~= ',' then error_at('expected , or }') end
      pos = pos + 1
    end
    return obj
  elseif c == '[' then
    pos = pos + 1
    local arr = {}
    skip_ws()
    if str:sub(pos,pos) == ']' then
      pos = pos + 1
      return arr
    end
    local i = 1
    while true do
      arr[i] = parse_value()
      i = i + 1
      skip_ws()
      local ch = str:sub(pos,pos)
      if ch == ']' then pos = pos + 1 break
      elseif ch ~= ',' then error_at('expected , or ]') end
      pos = pos + 1
    end
    return arr
  elseif c == '"' then
    return parse_string()
  elseif c == '-' or c:match('%d') then
    return parse_number()
  else
    local literals = {['true']=true,['false']=false,['null']=nil}
    for lit,val in pairs(literals) do
      if str:sub(pos,pos+#lit-1) == lit then
        pos = pos + #lit
        return val
      end
    end
  end
  error_at('unexpected character '..c)
end

function parse_string()
  local start = pos + 1
  pos = start
  local res = {}
  while true do
    local c = str:sub(pos,pos)
    if c == '' then error_at('unterminated string') end
    if c == '"' then
      res[#res+1] = str:sub(start, pos-1)
      pos = pos + 1
      return table.concat(res)
    elseif c == '\\' then
      res[#res+1] = str:sub(start,pos-1)
      local esc = str:sub(pos+1,pos+1)
      if esc == 'u' then
        local hex = str:sub(pos+2,pos+5)
        if not hex:match('%x%x%x%x') then error_at('invalid unicode escape') end
        res[#res+1] = utf8.char(tonumber(hex,16))
        pos = pos + 6
      else
          local map = {b='\\b', f='\\f', n='\\n', r='\\r', t='\\t', ['\\']='\\', ['"']='"'}
        if not map[esc] then error_at('invalid escape') end
        res[#res+1] = map[esc]
        pos = pos + 2
      end
      start = pos
    else
      pos = pos + 1
    end
  end
end

function parse_number()
  local i,j = str:find('^-?%d+%.?%d*[eE]?[%+%-]?%d*', pos)
  if not i then error_at('invalid number') end
  local num = tonumber(str:sub(i,j))
  pos = j + 1
  return num
end

function json.decode(s)
  str = s
  pos = 1
  local val = parse_value()
  skip_ws()
  if pos <= #str then error_at('trailing garbage') end
  return val
end

return json
