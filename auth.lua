local util = require('util')
local json = require('json')

local M = {}

local BASE_URL = 'https://api.player2.game/v1'
local KEY_PATH = 'api_key.txt'
local CLIENT_ID = os.getenv('P2_CLIENT_ID') or 'your-client-id'

local function load_key()
  return util.read_file(KEY_PATH)
end

local function save_key(k)
  util.write_file(KEY_PATH, k)
end

local function device_flow()
  local body = {client_id = CLIENT_ID}
  local res, status = util.http_post(BASE_URL .. '/login/device/new', body, {['Content-Type']='application/json'})

  -- Check for any authentication issues during device flow initialization
  if status ~= 200 then
    error('Failed to start device flow: HTTP ' .. status)
  end

  local data = json.decode(res)
  print('Visit '..data.verificationUri..' and enter code '..data.userCode)
  print('Or open '..data.verificationUriComplete)
  local interval = data.interval or 5
  local expires = os.time() + (data.expiresIn or 600)
  while os.time() < expires do
    os.execute('sleep '..interval)
    local poll_body = {
      client_id = CLIENT_ID,
      device_code = data.deviceCode,
      grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
    }
    local resp, poll_status = util.http_post(BASE_URL .. '/login/device/token', poll_body, {['Content-Type']='application/json'})

    -- Only process successful responses, ignore pending/error states during polling
    if poll_status == 200 then
      local tok = json.decode(resp)
      if tok and tok.p2Key then
        print('Authentication successful')
        save_key(tok.p2Key)
        return tok.p2Key
      end
    end
  end
  error('Authentication timed out')
end

function M.get_key()
  local key = load_key()
  if key then return key end
  return device_flow()
end

function M.remove_key()
  os.remove(KEY_PATH)
  print('API key removed due to authentication failure.')
end

function M.refresh_key()
  M.remove_key()
  return device_flow()
end

return M
