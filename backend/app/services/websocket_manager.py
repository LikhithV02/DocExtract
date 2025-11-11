"""
WebSocket manager for real-time document updates
"""
from fastapi import WebSocket
from typing import List, Dict, Any
import logging
import json
from datetime import datetime

logger = logging.getLogger(__name__)


class WebSocketManager:
    """Manages WebSocket connections for real-time updates"""

    def __init__(self):
        # Store active connections
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        """
        Accept a new WebSocket connection

        Args:
            websocket: WebSocket connection to accept
        """
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"WebSocket connected. Total connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        """
        Remove a WebSocket connection

        Args:
            websocket: WebSocket connection to remove
        """
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
            logger.info(
                f"WebSocket disconnected. Total connections: {len(self.active_connections)}"
            )

    async def broadcast(self, event_type: str, data: Dict[str, Any]):
        """
        Broadcast a message to all connected clients

        Args:
            event_type: Type of event (INSERT, UPDATE, DELETE)
            data: Event data to broadcast
        """
        message = {
            "type": event_type,
            "timestamp": datetime.utcnow().isoformat(),
            "data": data,
        }

        # Convert message to JSON
        message_json = json.dumps(message)

        # Send to all connected clients
        disconnected = []

        for connection in self.active_connections:
            try:
                await connection.send_text(message_json)
            except Exception as e:
                logger.error(f"Error sending to WebSocket: {e}")
                disconnected.append(connection)

        # Remove disconnected clients
        for connection in disconnected:
            self.disconnect(connection)

        logger.info(
            f"Broadcasted {event_type} event to {len(self.active_connections)} clients"
        )

    async def send_personal_message(self, message: str, websocket: WebSocket):
        """
        Send a message to a specific client

        Args:
            message: Message to send
            websocket: Target WebSocket connection
        """
        try:
            await websocket.send_text(message)
        except Exception as e:
            logger.error(f"Error sending personal message: {e}")
            self.disconnect(websocket)


# Global WebSocket manager instance
ws_manager = WebSocketManager()
