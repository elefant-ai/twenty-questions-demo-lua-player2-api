local json = require('json')
local http = require('socket.http')
local ltn12 = require('ltn12')
local url_parse = require('socket.url')

-- Try to load ssl support, but don't fail if not available
local https_available, https = pcall(require, 'ssl.https')

local util = {}

function util.read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local data = f:read('*a')
  f:close()
  return data
end

function util.write_file(path, data)
  local f = assert(io.open(path, 'w'))
  f:write(data)
  f:close()
end

function util.http_post(url, tbl, headers)
  headers = headers or {}

  -- Encode the request body
  local body = json.encode(tbl)

  -- Set up headers
  local request_headers = {}
  for k, v in pairs(headers) do
    request_headers[k] = v
  end

  -- Set content-length if not provided
  if not request_headers['Content-Length'] then
    request_headers['Content-Length'] = tostring(#body)
  end

  -- Response table to collect the response
  local response_body = {}

  -- Parse URL to determine if HTTPS is needed
  local parsed_url = url_parse.parse(url)
  local is_https = parsed_url.scheme == 'https'

  -- Choose the appropriate HTTP library
  local http_lib = http
  if is_https then
    if https_available then
      http_lib = https
    else
      error("HTTPS URL provided but ssl.https not available. Please install LuaSec: luarocks install luasec")
    end
  end

    -- Make the request
  local result, status, response_headers = http_lib.request{
    url = url,
    method = 'POST',
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body),
    headers = request_headers
  }

  -- Check for errors
  if not result then
    error("HTTP request failed: " .. tostring(status))
  end

  -- Return the response body and status code
  local response_text = table.concat(response_body)
  return response_text, status
end

return util
