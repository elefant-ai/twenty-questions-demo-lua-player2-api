local M = {}

local function play_user_questions(chat)
  print('I am thinking of something. Ask your yes/no questions!')
  local messages = {
    {role='system', content='You are a playful AI playing 20 Questions. Think of an object but do not reveal it. Answer user questions with yes or no. If the user guesses correctly, acknowledge it clearly by saying "Yes, that\'s correct!" or "You got it!" After 20 questions, reveal the object.'}
  }
  for i=1,20 do
    io.write('Question '..i..': ')
    local q = io.read()
    table.insert(messages, {role='user', content=q})
    local ans = chat.complete(messages)
    print('AI: '..ans)
    table.insert(messages, {role='assistant', content=ans})
    -- Check if user guessed correctly - look for clear confirmation patterns
    if ans:lower():match('you got it') or ans:lower():match('that\'s correct') or
       ans:lower():match('yes.*correct') or ans:lower():match('correct.*yes') then
      print('Congratulations! You won!')
      return true
    end
  end
  table.insert(messages, {role='user', content='I give up. What was it?'})
  local reveal = chat.complete(messages)
  print('AI: '..reveal)
  return false
end

local function play_ai_guesses(chat)
  io.write('Think of something and type it here so I know when I am correct: ')
  local secret = io.read()
  local messages = {
    {role='system', content='You are a playful AI playing 20 Questions. The user has an object in mind. Ask yes or no questions to guess it. When ready to make your final guess, ask "Is it a [specific object]?" Be specific with your guess - not just "Is it a place?" but "Is it the Eiffel Tower?" You have 20 questions.'},
    {role='user', content='I have an object in mind.'}
  }
  for i=1,20 do
    local q = chat.complete(messages)
    print('AI: '..q)
    table.insert(messages, {role='assistant', content=q})
    io.write('Answer: ')
    local a = io.read()
    table.insert(messages, {role='user', content=a})

    -- Check if this is a specific object guess and the answer is yes
    -- Look for pattern "Is it a/an [specific object]?" or "Is it [specific object]?"
    -- But exclude vague questions like "Is it a place?" "Is it an animal?" etc.
    local is_specific_guess = false
    if q:lower():match('^is it') and a:lower():match('^yes') then
      -- Extract what comes after "is it" to check if it's specific
      local guess_part = q:lower():match('^is it a?n? (.+)%?') or q:lower():match('^is it (.+)%?')
      if guess_part then
        -- Check if it's NOT a vague category question
        local vague_patterns = {
          'place', 'animal', 'person', 'thing', 'object', 'food', 'drink',
          'tool', 'machine', 'vehicle', 'building', 'plant', 'fruit',
          'vegetable', 'color', 'shape', 'material', 'metal', 'liquid',
          'gas', 'solid', 'living', 'dead', 'natural', 'artificial',
          'big', 'small', 'round', 'square', 'heavy', 'light'
        }
        local is_vague = false
        for _, pattern in ipairs(vague_patterns) do
          if guess_part:match(pattern) and not guess_part:match('%w+%s+' .. pattern) then
            is_vague = true
            break
          end
        end
        if not is_vague then
          is_specific_guess = true
        end
      end
    end

    if is_specific_guess then
      print('I guessed it! The answer was: ' .. secret)
      return true
    end
  end
  table.insert(messages, {role='assistant', content='I have asked 20 questions.'})
  table.insert(messages, {role='user', content='What is your final guess?'})
  local guess = chat.complete(messages)
  print('AI final guess: '..guess)
  print('Your object was: '..secret)
  return false
end

function M.start(chat)
  while true do
    print('\n=== Welcome to 20 Questions! ===')
    print('Choose a mode:')
    print('1) You guess the AI\'s object')
    print('2) AI guesses your object')
    print('3) Quit')
    io.write('Mode: ')
    local choice = io.read()

    if choice == '3' or choice:lower() == 'quit' then
      print('Thanks for playing!')
      break
    elseif choice == '2' then
      local success, err = pcall(play_ai_guesses, chat)
      if not success then
        if string.find(err, 'AUTH_FAILED') then
          error('AUTH_FAILED')  -- Propagate auth failure to main loop
        else
          print('Game error: ' .. tostring(err))
          -- Continue to menu instead of crashing
        end
      end
    elseif choice == '1' then
      local success, err = pcall(play_user_questions, chat)
      if not success then
        if string.find(err, 'AUTH_FAILED') then
          error('AUTH_FAILED')  -- Propagate auth failure to main loop
        else
          print('Game error: ' .. tostring(err))
          -- Continue to menu instead of crashing
        end
      end
    else
      print('Invalid choice. Please select 1, 2, or 3.')
    end

    print('\nGame over! Press Enter to return to main menu...')
    io.read()
  end
end

return M
