import { useEffect, useState, useCallback } from 'react';
import { wsManager, WebSocketMessage, WebSocketEventType } from '@/lib/websocket';

interface UseWebSocketOptions {
  autoConnect?: boolean;
  onMessage?: (message: WebSocketMessage) => void;
  eventTypes?: WebSocketEventType[];
}

export const useWebSocket = (options: UseWebSocketOptions = {}) => {
  const { autoConnect = true, onMessage, eventTypes } = options;
  const [isConnected, setIsConnected] = useState(false);
  const [connectionState, setConnectionState] = useState(WebSocket.CLOSED);

  // Update connection state
  useEffect(() => {
    const checkConnectionState = () => {
      const state = wsManager.getConnectionState();
      setConnectionState(state);
      setIsConnected(state === WebSocket.OPEN);
    };

    const interval = setInterval(checkConnectionState, 1000);
    checkConnectionState();

    return () => clearInterval(interval);
  }, []);

  // Handle messages
  useEffect(() => {
    if (!onMessage) return;

    const unsubscribe = wsManager.subscribe((message) => {
      // Filter by event types if specified
      if (eventTypes && !eventTypes.includes(message.type)) {
        return;
      }
      onMessage(message);
    });

    return unsubscribe;
  }, [onMessage, eventTypes]);

  // Auto-connect
  useEffect(() => {
    if (autoConnect) {
      wsManager.connect();
    }

    return () => {
      if (autoConnect) {
        wsManager.disconnect();
      }
    };
  }, [autoConnect]);

  const send = useCallback((message: WebSocketMessage) => {
    wsManager.send(message);
  }, []);

  const connect = useCallback(() => {
    wsManager.connect();
  }, []);

  const disconnect = useCallback(() => {
    wsManager.disconnect();
  }, []);

  return {
    isConnected,
    connectionState,
    send,
    connect,
    disconnect,
  };
};
