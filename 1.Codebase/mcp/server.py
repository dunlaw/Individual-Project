import sys
import logging

logging.basicConfig(level=logging.INFO, stream=sys.stderr)
logger = logging.getLogger("gda1-mcp-server")

from tools import mcp, game


def main():
    if game.connect():
        logger.info("Connected to game server on startup")
    else:
        logger.info("Game not connected. Will connect when tools are called.")
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
