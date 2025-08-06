package.path = './?.lua;' .. package.path

local auth = require('auth')
local chatmod = require('chat')
local game = require('game')

-- Main loop that handles authentication failures
while true do
  local key_success, key_or_err = pcall(auth.get_key)
  if not key_success then
    print('Failed to authenticate: ' .. tostring(key_or_err))
    print('Please check your P2_CLIENT_ID environment variable and try again.')
    break
  end

  local key = key_or_err
  local chat = chatmod.new(key)

  local success, err = pcall(game.start, chat)

  if success then
    -- Game completed normally, exit
    break
  elseif string.find(err, 'AUTH_FAILED') then
    -- Authentication failed during gameplay, remove key and retry
    print('\n=== Authentication Failed ===')
    print('Your authentication session has expired.')
    auth.remove_key()
    print('Restarting authentication process...\n')
    -- Continue loop to re-authenticate and restart game
  else
    -- Some other error occurred, propagate it
    print('Unexpected error: ' .. tostring(err))
    break
  end
end
