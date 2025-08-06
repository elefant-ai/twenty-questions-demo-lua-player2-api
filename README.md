# Twenty Questions Demo

Command line Lua implementation of a 20 Questions game using the Player2 API.

This simple game shows how to authenticate users for your game and make basic
calls using the Player2 Web API.

## Dependencies

This project requires the following Lua libraries:

- **LuaSocket** - For HTTP/HTTPS requests
- **LuaSec** - For HTTPS/SSL support (optional, but recommended)

Install with LuaRocks:

```sh
luarocks install luasocket
luarocks install luasec  # Optional but recommended for HTTPS support
```

## Running

```sh
P2_CLIENT_ID=<your-client-id> lua main.lua
```

## Authentication

The first run starts a device authorization flow and saves the resulting API key to `api_key.txt` for future sessions. In a real game the key should be stored somewhere safely - for example encrypted.

**Automatic 401 Handling**: If authentication expires during gameplay (401 response), the game will:

1. Automatically stop the current game
2. Remove the expired API key
3. Restart the authentication flow
4. Return you to the main menu once re-authenticated

This ensures seamless gameplay even when API key is revoked.
