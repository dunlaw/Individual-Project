# GDA1 MCP Server

MCP (Model Context Protocol) server for **Glorious Deliverance Agency 1**. This allows Claude Desktop and other MCP-compatible AI clients to observe and control the game.

## Quick Setup

### 1. Install uv (Python package manager)

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**macOS/Linux:**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 2. Configure Claude Desktop

Open Claude Desktop config file:

**Windows:**
```powershell
code $env:AppData\Claude\claude_desktop_config.json
```

**macOS:**
```bash
code ~/Library/Application\ Support/Claude/claude_desktop_config.json
```

Add this configuration (replace the path with your actual path):

```json
{
  "mcpServers": {
    "gda1-game": {
      "command": "uv",
      "args": [
        "--directory",
        "C:\\Users\\YOUR_USERNAME\\path\\to\\Individual-Project\\1.Codebase\\mcp",
        "run",
        "gda1_server.py"
      ]
    }
  }
}
```

> **Note:** On Windows, use double backslashes (`\\`) in the path.

### 3. Start the Game

1. Launch GDA1 in Godot
2. Go to **Settings** → Enable **AI Agent Server**
3. Restart Claude Desktop

### 4. Use in Claude Desktop

Once configured, you can ask Claude to:

- "What's happening in the game?"
- "Select choice 0"
- "Start a new mission"
- "Enable auto-play mode"

## Available Tools

### Game Flow

| Tool | Description |
|------|-------------|
| `get_game_state` | Get current game state (story, choices, stats) |
| `select_choice` | Select a dialogue choice by ID |
| `start_mission` | Start a new mission |
| `start_new_game` | Start a brand new game |
| `continue_game` | Load and continue a saved game |
| `save_game` | Save the current game |
| `go_to_menu` | Return to the main menu |
| `skip_intro` | Skip the intro sequence |
| `skip_dialogue` | Skip the current dialogue |

### Story & Interaction

| Tool | Description |
|------|-------------|
| `submit_prayer` | Submit a prayer text |
| `get_story_history` | Get the last 10 story history entries |
| `set_auto_mode` | Enable/disable auto-play (with optional delay in ms) |

### Overlays & UI

| Tool | Description |
|------|-------------|
| `open_journal` | Open the in-game journal |
| `close_overlay` | Close the current overlay |
| `confirm_overlay` | Confirm/accept the current overlay prompt |

### Stats & Debug

| Tool | Description |
|------|-------------|
| `set_stat` | Set a game stat (e.g. `reality_score`, `positive_energy`, `entropy_level`) to a specific value |

### AI Configuration

| Tool | Description |
|------|-------------|
| `get_ai_config` | Get the current AI provider and model configuration |
| `set_ai_provider` | Switch the active AI provider |
| `set_ai_model` | Set the model for a given provider |
| `set_api_key` | Set the API key for a given provider |

### Connection

| Tool | Description |
|------|-------------|
| `connect_to_game` | Connect (or reconnect) to the game server |

## Troubleshooting

### Server not showing in Claude Desktop

1. Check the config file path is absolute
2. Make sure `uv` is installed and in PATH
3. Restart Claude Desktop completely (quit from system tray)

### Connection failed

1. Make sure the game is running
2. Enable "AI Agent Server" in game settings
3. Check the default ports (WebSocket: 9876, TCP: 9877)

### Check logs

**Windows:**
```powershell
Get-Content $env:AppData\Claude\logs\mcp*.log -Tail 20
```

**macOS:**
```bash
tail -n 20 -f ~/Library/Logs/Claude/mcp*.log
```

## Manual Testing

You can also test the MCP server directly:

```bash
cd mcp
uv run gda1_server.py
```

This will start the server in STDIO mode for testing.
