type WebSocketEventType = 'extraction_complete' | 'extraction_failed' | 'document_updated';

interface WebSocketMessage {
  type: WebSocketEventType;
  data: any;
}

type MessageHandler = (message: WebSocketMessage) => void;

class WebSocketManager {
  private ws: WebSocket | null = null;
  private handlers: Set<MessageHandler> = new Set();
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private url: string;
  private isIntentionallyClosed = false;

  constructor(url: string) {
    this.url = url;
  }

  connect() {
    if (this.ws?.readyState === WebSocket.OPEN) {
      return;
    }

    this.isIntentionallyClosed = false;

    try {
      this.ws = new WebSocket(this.url);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        this.reconnectAttempts = 0;
      };

      this.ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          this.handlers.forEach(handler => handler(message));
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
      };

      this.ws.onclose = () => {
        console.log('WebSocket disconnected');
        if (!this.isIntentionallyClosed) {
          this.attemptReconnect();
        }
      };
    } catch (error) {
      console.error('Failed to create WebSocket connection:', error);
      this.attemptReconnect();
    }
  }

  private attemptReconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnection attempts reached');
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    console.log(`Attempting to reconnect in ${delay}ms (attempt ${this.reconnectAttempts})`);

    setTimeout(() => {
      this.connect();
    }, delay);
  }

  disconnect() {
    this.isIntentionallyClosed = true;
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  subscribe(handler: MessageHandler) {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  send(message: WebSocketMessage) {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(message));
    } else {
      console.warn('WebSocket is not connected');
    }
  }

  getConnectionState(): number {
    return this.ws?.readyState ?? WebSocket.CLOSED;
  }
}

// Create singleton instance
const WS_URL = import.meta.env.VITE_WS_URL ||
  `ws://${window.location.hostname}:${import.meta.env.VITE_API_PORT || '8000'}/ws`;

export const wsManager = new WebSocketManager(WS_URL);

export type { WebSocketMessage, WebSocketEventType };
