local util = require('util')
local json = require('json')

local M = {}
local BASE_URL = 'https://api.player2.game/v1'

function M.new(api_key)
  local obj = {}
  function obj.complete(messages)
    local body = {messages = messages, stream = false}
    local res, status = util.http_post(BASE_URL .. '/chat/completions', body, {
      ['Content-Type'] = 'application/json',
      ['Authorization'] = 'Bearer ' .. api_key
    })

    -- Check for authentication failure
    if status == 401 then
      error('AUTH_FAILED')  -- Special error that main loop will catch
    end

    local data = json.decode(res)
    if data and data.choices and data.choices[1] and data.choices[1].message then
      return data.choices[1].message.content
    end
    return ''
  end
  return obj
end

return M
