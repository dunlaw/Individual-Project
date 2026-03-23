import time
from mcp.server.fastmcp import FastMCP
from connection import GameConnection

mcp = FastMCP("gda1-game")
game = GameConnection()

def _format_game_state(state: dict) -> str:
    if "error" in state:
        return f"Error: {state['error']}"
    lines = []
    lines.append("=" * 50)
    lines.append("GAME STATE")
    lines.append("=" * 50)
    lines.append(f"\nScene: {state.get('current_scene', 'unknown')}")
    lines.append(f"Waiting for input: {state.get('waiting_for_action', False)}")
    lines.append(f"AI generating: {state.get('is_generating', False)}")
    ai_error = state.get("ai_error", {})
    if ai_error.get("has_error"):
        lines.append(f"\n{'!' * 50}")
        lines.append("  AI ERROR:")
        lines.append(f"  {ai_error.get('message', 'Unknown error')}")
        seconds_ago = ai_error.get("seconds_ago", 0)
        if seconds_ago > 0:
            lines.append(f"  (occurred {seconds_ago:.1f} seconds ago)")
        lines.append('!' * 50)
    mission = state.get("mission", {})
    if mission:
        lines.append(f"\nMission #{mission.get('mission_number', 0)}: {mission.get('mission_title', 'N/A')}")
        lines.append(f"Turn count: {mission.get('turn_count', 0)}")
    stats = state.get("stats", {})
    lines.append(f"\nStats:")
    lines.append(f"  Reality Score:   {stats.get('reality_score', 50)}")
    lines.append(f"  Positive Energy: {stats.get('positive_energy', 50)}")
    lines.append(f"  Entropy Level:   {stats.get('entropy_level', 0)}")
    story = state.get("story_text", "")
    if story:
        lines.append(f"\nStory:")
        if len(story) > 500:
            lines.append(f"  {story[:500]}...")
        else:
            lines.append(f"  {story}")
    choices = state.get("available_choices", [])
    if choices:
        lines.append(f"\nAvailable Choices ({len(choices)}):")
        for choice in choices:
            text = choice.get('text', '')
            if len(text) > 80:
                text = text[:80] + "..."
            lines.append(f"  [{choice['id']}] ({choice.get('archetype', 'unknown')}) {text}")
    else:
        lines.append("\nNo choices available")
    lines.append("=" * 50)
    return "\n".join(lines)

def _ensure_connected() -> str | None:
    if not game.is_connected():
        if not game.connect():
            return (
                "Not connected to game. Please ensure:\n"
                "1. The game is running\n"
                "2. Agent Server is enabled in Settings\n"
                "3. Use connect_to_game tool to connect"
            )
    return None

@mcp.tool()
def get_game_state() -> str:
    error = _ensure_connected()
    if error:
        return error
    state = game.get_state()
    return _format_game_state(state)

@mcp.tool()
def select_choice(choice_id: int) -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({
        "action": "select_choice",
        "params": {"choice_id": choice_id}
    })
    if result.get("type") == "ack" and result.get("success"):
        time.sleep(0.5)
        state = game.get_state()
        return f"Selected choice {choice_id}.\n\n{_format_game_state(state)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to select choice: {error_msg}"

@mcp.tool()
def start_mission() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "start_mission"})
    if result.get("type") == "ack" and result.get("success"):
        return "Mission started. Use get_game_state to see the new mission."
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to start mission: {error_msg}"

@mcp.tool()
def start_new_game() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "start_new_game"})
    if result.get("type") == "ack" and result.get("success"):
        time.sleep(2)
        state = game.get_state()
        return f"New game started!\n\n{_format_game_state(state)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to start new game: {error_msg}"

@mcp.tool()
def continue_game() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "continue_game"})
    if result.get("type") == "ack" and result.get("success"):
        time.sleep(2)
        state = game.get_state()
        return f"Game loaded!\n\n{_format_game_state(state)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to continue game: {error_msg}"

@mcp.tool()
def submit_prayer(text: str) -> str:
    error = _ensure_connected()
    if error:
        return error
    if not text:
        return "Prayer text is required"
    result = game.send_and_receive({
        "action": "submit_prayer",
        "params": {"text": text}
    })
    if result.get("type") == "ack" and result.get("success"):
        return f"Prayer submitted: {text}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to submit prayer: {error_msg}"

@mcp.tool()
def set_auto_mode(enabled: bool, delay_ms: int = 2000) -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({
        "action": "set_auto_mode",
        "params": {"enabled": enabled, "delay_ms": delay_ms}
    })
    if result.get("type") == "ack" and result.get("success"):
        status = "enabled" if enabled else "disabled"
        return f"Auto-play mode {status} (delay: {delay_ms}ms)"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to set auto mode: {error_msg}"

@mcp.tool()
def connect_to_game(host: str = "localhost") -> str:
    game.host = host
    game.disconnect()
    if game.connect():
        return f"Successfully connected to game at {host}"
    else:
        return (
            f"Failed to connect to game at {host}.\n"
            "Make sure the game is running and Agent Server is enabled in settings."
        )

@mcp.tool()
def go_to_menu() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "go_to_menu"})
    if result.get("type") == "ack" and result.get("success"):
        return "Returning to main menu..."
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to go to menu: {error_msg}"

@mcp.tool()
def save_game() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "save_game"})
    if result.get("type") == "ack" and result.get("success"):
        return "Game saved successfully!"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to save game: {error_msg}"

@mcp.tool()
def set_stat(stat: str, value: int) -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({
        "action": "set_stat",
        "params": {"stat": stat, "value": value}
    })
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        return f"Set {data.get('stat', stat)} to {data.get('value', value)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to set stat: {error_msg}"

@mcp.tool()
def get_story_history() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "get_story_history"})
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        history = data.get("history", [])
        count = data.get("count", 0)
        if not history:
            return "No story history available yet."
        output = [f"Story History ({count} entries):"]
        for i, entry in enumerate(history[-10:]):
            if isinstance(entry, dict):
                text = entry.get("text", entry.get("content", str(entry)))
            else:
                text = str(entry)
            if len(text) > 200:
                text = text[:200] + "..."
            output.append(f"\n[{i+1}] {text}")
        return "\n".join(output)
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to get history: {error_msg}"

@mcp.tool()
def skip_dialogue() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "skip_dialogue"})
    if result.get("type") == "ack" and result.get("success"):
        return "Dialogue skipped."
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to skip dialogue: {error_msg}"

@mcp.tool()
def open_journal() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "open_journal"})
    if result.get("type") == "ack" and result.get("success"):
        return "Journal opened."
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to open journal: {error_msg}"

@mcp.tool()
def close_overlay() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "close_overlay"})
    if result.get("type") == "ack" and result.get("success"):
        return "Overlay closed."
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to close overlay: {error_msg}"

@mcp.tool()
def confirm_overlay() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "confirm_overlay"})
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        return data.get("message", "Overlay confirmed.")
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to confirm overlay: {error_msg}"

@mcp.tool()
def get_ai_config() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "get_ai_config"})
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        lines = ["=== AI Configuration ==="]
        lines.append(f"\nCurrent Provider: {data.get('current_provider', 'unknown')}")
        lines.append(f"\nAvailable Providers: {', '.join(data.get('available_providers', []))}")
        for provider in ["gemini", "openrouter", "ollama", "openai", "claude", "lmstudio", "ai_router"]:
            if provider in data:
                info = data[provider]
                lines.append(f"\n{provider.upper()}:")
                lines.append(f"  Model: {info.get('model', 'not set')}")
                if "has_api_key" in info:
                    lines.append(f"  API Key: {'configured' if info['has_api_key'] else 'NOT SET'}")
                if "host" in info:
                    lines.append(f"  Host: {info.get('host')}:{info.get('port')}")
        return "\n".join(lines)
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to get AI config: {error_msg}"

@mcp.tool()
def set_ai_provider(provider: str) -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({
        "action": "set_ai_provider",
        "params": {"provider": provider}
    })
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        return f"AI provider set to: {data.get('provider', provider)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to set provider: {error_msg}"

@mcp.tool()
def set_ai_model(model: str, provider: str = "") -> str:
    error = _ensure_connected()
    if error:
        return error
    params = {"model": model}
    if provider:
        params["provider"] = provider
    result = game.send_and_receive({
        "action": "set_ai_model",
        "params": params
    })
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        return f"Model set to '{data.get('model')}' for provider '{data.get('provider')}'"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to set model: {error_msg}"

@mcp.tool()
def set_api_key(provider: str, api_key: str) -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({
        "action": "set_api_key",
        "params": {"provider": provider, "api_key": api_key}
    })
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        return f"API key set for {data.get('provider')}. Preview: {data.get('key_preview')}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to set API key: {error_msg}"

@mcp.tool()
def skip_intro() -> str:
    error = _ensure_connected()
    if error:
        return error
    result = game.send_and_receive({"action": "skip_intro"})
    if result.get("type") == "ack" and result.get("success"):
        data = result.get("data", {})
        time.sleep(2)
        state = game.get_state()
        return f"{data.get('message', 'Intro skipped.')}\n\n{_format_game_state(state)}"
    else:
        error_msg = result.get("message", "Unknown error")
        return f"Failed to skip intro: {error_msg}"
