import json
import argparse
import time
import random
try:
    import websocket
    HAS_WEBSOCKET = True
except ImportError:
    HAS_WEBSOCKET = False
    print("Note: websocket-client not installed. Use --tcp for TCP mode.")
import socket
class GameAgentClient:
    
    def __init__(self, host: str = "localhost", ws_port: int = 9876, tcp_port: int = 9877):
        self.host = host
        self.ws_port = ws_port
        self.tcp_port = tcp_port
        self.ws = None
        self.tcp_socket = None
        self.protocol = None
        self.game_state = None
    def connect_websocket(self) -> bool:
        
        if not HAS_WEBSOCKET:
            print("WebSocket client not available. Install with: pip install websocket-client")
            return False
        try:
            self.ws = websocket.create_connection(f"ws://{self.host}:{self.ws_port}")
            self.protocol = "websocket"
            print(f"Connected via WebSocket to {self.host}:{self.ws_port}")
            return True
        except Exception as e:
            print(f"WebSocket connection failed: {e}")
            return False
    def connect_tcp(self) -> bool:
        
        try:
            self.tcp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.tcp_socket.connect((self.host, self.tcp_port))
            self.tcp_socket.setblocking(False)
            self.protocol = "tcp"
            print(f"Connected via TCP to {self.host}:{self.tcp_port}")
            return True
        except Exception as e:
            print(f"TCP connection failed: {e}")
            return False
    def send(self, data: dict) -> None:
        
        json_str = json.dumps(data)
        if self.protocol == "websocket" and self.ws:
            self.ws.send(json_str)
        elif self.protocol == "tcp" and self.tcp_socket:
            self.tcp_socket.send((json_str + "\n").encode("utf-8"))
    def receive(self, timeout: float = 1.0) -> list:
        
        messages = []
        if self.protocol == "websocket" and self.ws:
            self.ws.settimeout(timeout)
            try:
                data = self.ws.recv()
                if data:
                    messages.append(json.loads(data))
            except websocket.WebSocketTimeoutException:
                pass
            except Exception as e:
                print(f"WebSocket receive error: {e}")
        elif self.protocol == "tcp" and self.tcp_socket:
            start = time.time()
            buffer = ""
            while time.time() - start < timeout:
                try:
                    data = self.tcp_socket.recv(4096).decode("utf-8")
                    buffer += data
                except BlockingIOError:
                    time.sleep(0.01)
                    continue
                except Exception:
                    break
            for line in buffer.split("\n"):
                if line.strip():
                    try:
                        messages.append(json.loads(line))
                    except json.JSONDecodeError:
                        pass
        return messages
    def close(self) -> None:
        
        if self.ws:
            self.ws.close()
        if self.tcp_socket:
            self.tcp_socket.close()
        print("Connection closed")
    def get_state(self) -> dict:
        
        self.send({"action": "get_state"})
        messages = self.receive(timeout=2.0)
        for msg in messages:
            if msg.get("type") == "observation":
                self.game_state = msg.get("game_state", {})
                return self.game_state
        return {}
    def select_choice(self, choice_id: int) -> dict:
        
        self.send({
            "action": "select_choice",
            "params": {"choice_id": choice_id}
        })
        return self.receive(timeout=2.0)
    def start_mission(self) -> dict:
        
        self.send({"action": "start_mission"})
        return self.receive(timeout=5.0)
    def set_auto_mode(self, enabled: bool, delay_ms: int = 2000) -> dict:
        
        self.send({
            "action": "set_auto_mode",
            "params": {"enabled": enabled, "delay_ms": delay_ms}
        })
        return self.receive(timeout=2.0)
def print_game_state(state: dict) -> None:
    
    print("\n" + "=" * 50)
    print("GAME STATE")
    print("=" * 50)
    print(f"\nScene: {state.get('current_scene', 'unknown')}")
    print(f"Waiting for input: {state.get('waiting_for_action', False)}")
    print(f"AI generating: {state.get('is_generating', False)}")
    mission = state.get("mission", {})
    if mission:
        print(f"\nMission #{mission.get('mission_number', 0)}: {mission.get('mission_title', 'N/A')}")
    stats = state.get("stats", {})
    print(f"\nStats:")
    print(f"  Reality Score:   {stats.get('reality_score', 50)}")
    print(f"  Positive Energy: {stats.get('positive_energy', 50)}")
    print(f"  Entropy Level:   {stats.get('entropy_level', 0)}")
    story = state.get("story_text", "")
    if story:
        print(f"\nStory (first 200 chars):")
        print(f"  {story[:200]}...")
    choices = state.get("available_choices", [])
    if choices:
        print(f"\nAvailable Choices ({len(choices)}):")
        for choice in choices:
            print(f"  [{choice['id']}] ({choice['archetype']}) {choice['text'][:50]}...")
    else:
        print("\nNo choices available")
    print("=" * 50)
def interactive_mode(client: GameAgentClient) -> None:
    
    print("\nInteractive Mode - Commands:")
    print("  s - Get current state")
    print("  c <id> - Select choice by ID")
    print("  m - Start new mission")
    print("  a - Toggle auto-mode")
    print("  q - Quit")
    auto_mode = False
    while True:
        try:
            cmd = input("\n> ").strip().lower()
            if cmd == "q":
                break
            elif cmd == "s":
                state = client.get_state()
                print_game_state(state)
            elif cmd.startswith("c "):
                try:
                    choice_id = int(cmd.split()[1])
                    result = client.select_choice(choice_id)
                    print(f"Result: {json.dumps(result, indent=2)}")
                except (ValueError, IndexError):
                    print("Usage: c <choice_id>")
            elif cmd == "m":
                result = client.start_mission()
                print(f"Result: {json.dumps(result, indent=2)}")
            elif cmd == "a":
                auto_mode = not auto_mode
                result = client.set_auto_mode(auto_mode, 3000)
                print(f"Auto-mode: {'ON' if auto_mode else 'OFF'}")
                print(f"Result: {json.dumps(result, indent=2)}")
            else:
                print("Unknown command. Use 's', 'c <id>', 'm', 'a', or 'q'")
        except KeyboardInterrupt:
            print("\nExiting...")
            break
def demo_mode(client: GameAgentClient) -> None:
    
    print("\nDemo Mode - Will make random choices automatically")
    print("Press Ctrl+C to stop\n")
    try:
        while True:
            state = client.get_state()
            print_game_state(state)
            choices = state.get("available_choices", [])
            if choices and state.get("waiting_for_action"):
                preferred = [c for c in choices if c["archetype"] in ("cautious", "balanced")]
                if preferred:
                    choice = random.choice(preferred)
                else:
                    choice = random.choice(choices)
                print(f"\n>>> Selecting choice {choice['id']}: {choice['text'][:50]}...")
                client.select_choice(choice["id"])
            time.sleep(3)
    except KeyboardInterrupt:
        print("\nDemo stopped")
def main():
    parser = argparse.ArgumentParser(description="GDA1 AI Agent Test Client")
    parser.add_argument("--tcp", action="store_true", help="Use TCP instead of WebSocket")
    parser.add_argument("--host", default="localhost", help="Server host")
    parser.add_argument("--demo", action="store_true", help="Run in demo mode (auto-play)")
    args = parser.parse_args()
    client = GameAgentClient(host=args.host)
    if args.tcp:
        if not client.connect_tcp():
            return
    else:
        if not client.connect_websocket():
            print("Falling back to TCP...")
            if not client.connect_tcp():
                return
    try:
        print("\nWaiting for welcome message...")
        messages = client.receive(timeout=3.0)
        for msg in messages:
            if msg.get("type") == "welcome":
                print(f"Connected to: {msg.get('game', 'Unknown')}")
                print(f"Protocol version: {msg.get('protocol_version', 'Unknown')}")
                print(f"Available actions: {msg.get('available_actions', [])}")
            elif msg.get("type") == "observation":
                client.game_state = msg.get("game_state", {})
        if args.demo:
            demo_mode(client)
        else:
            interactive_mode(client)
    finally:
        client.close()
if __name__ == "__main__":
    main()
