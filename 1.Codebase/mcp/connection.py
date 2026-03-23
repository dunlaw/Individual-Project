import json
import socket
import logging

logger = logging.getLogger("gda1-mcp-server")

try:
    import websocket
    HAS_WEBSOCKET = True
except ImportError:
    HAS_WEBSOCKET = False
    logger.warning("websocket-client not installed, WebSocket connection unavailable")


class GameConnection:

    def __init__(self, host: str = "localhost", ws_port: int = 9876, tcp_port: int = 9877):
        self.host = host
        self.ws_port = ws_port
        self.tcp_port = tcp_port
        self.ws = None
        self.tcp_socket = None
        self.protocol = None
        self._connected = False
        self._last_state = {}

    def connect(self) -> bool:
        if HAS_WEBSOCKET:
            try:
                self.ws = websocket.create_connection(
                    f"ws://{self.host}:{self.ws_port}",
                    timeout=5
                )
                self.protocol = "websocket"
                self._connected = True
                self._receive_welcome()
                logger.info(f"Connected via WebSocket to {self.host}:{self.ws_port}")
                return True
            except Exception as e:
                logger.debug(f"WebSocket connection failed: {e}")
        try:
            self.tcp_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.tcp_socket.settimeout(5)
            self.tcp_socket.connect((self.host, self.tcp_port))
            self.protocol = "tcp"
            self._connected = True
            self._receive_welcome()
            logger.info(f"Connected via TCP to {self.host}:{self.tcp_port}")
            return True
        except Exception as e:
            logger.debug(f"TCP connection failed: {e}")
            self._connected = False
            return False

    def _receive_welcome(self) -> None:
        try:
            messages = self._receive(timeout=2.0)
            for msg in messages:
                if msg.get("type") == "observation":
                    self._last_state = msg.get("game_state", {})
        except Exception:
            pass

    def disconnect(self) -> None:
        if self.ws:
            try:
                self.ws.close()
            except Exception:
                pass
            self.ws = None
        if self.tcp_socket:
            try:
                self.tcp_socket.close()
            except Exception:
                pass
            self.tcp_socket = None
        self._connected = False

    def is_connected(self) -> bool:
        return self._connected

    def send(self, data: dict) -> None:
        json_str = json.dumps(data)
        if self.protocol == "websocket" and self.ws:
            self.ws.send(json_str)
        elif self.protocol == "tcp" and self.tcp_socket:
            self.tcp_socket.send((json_str + "\n").encode("utf-8"))

    def _receive(self, timeout: float = 2.0) -> list:
        messages = []
        if self.protocol == "websocket" and self.ws:
            self.ws.settimeout(timeout)
            try:
                data = self.ws.recv()
                if data:
                    messages.append(json.loads(data))
            except Exception:
                pass
        elif self.protocol == "tcp" and self.tcp_socket:
            self.tcp_socket.settimeout(timeout)
            try:
                data = self.tcp_socket.recv(65536).decode("utf-8")
                for line in data.split("\n"):
                    if line.strip():
                        try:
                            messages.append(json.loads(line))
                        except json.JSONDecodeError:
                            pass
            except Exception:
                pass
        return messages

    def send_and_receive(self, data: dict, timeout: float = 5.0) -> dict:
        self.send(data)
        messages = self._receive(timeout=timeout)
        for msg in messages:
            if msg.get("type") == "observation":
                self._last_state = msg.get("game_state", {})
        return messages[0] if messages else {"error": "No response from game"}

    def get_state(self) -> dict:
        if not self._connected:
            if not self.connect():
                return {"error": "Not connected to game"}
        result = self.send_and_receive({"action": "get_state"})
        if result.get("type") == "observation":
            self._last_state = result.get("game_state", {})
            return self._last_state
        return result
