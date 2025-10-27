<template>
  <div class="chat-container">
    <!-- Username Prompt Modal -->
    <div v-if="!username" class="username-modal">
      <div class="username-modal-content">
        <h2>Welcome to Seguente Chat</h2>
        <p>Please enter your username to start chatting:</p>
        <input
          v-model="tempUsername"
          @keypress.enter="setUsername"
          placeholder="Enter your username..."
          maxlength="20"
        />
        <button @click="setUsername" :disabled="!tempUsername.trim()">
          Join Chat
        </button>
      </div>
    </div>

    <div class="chat-header">
      <h1>Seguente Chat</h1>
      <div class="user-info">
        <span class="username">{{ username }}</span>
        <div
          class="connection-status"
          :class="{ connected: isConnected, disconnected: !isConnected }"
        >
          {{ isConnected ? "Connected" : "Disconnected" }}
        </div>
      </div>
    </div>

    <div class="chat-messages" ref="messagesContainer">
      <div
        v-for="message in messages"
        :key="message.id"
        class="message"
        :class="{ 'own-message': message.isOwn }"
      >
        <div class="message-content">
          {{ message.text }}
        </div>
        <div class="message-time">
          {{ formatTime(message.timestamp) }}
        </div>
      </div>
    </div>

    <div class="chat-input">
      <input
        v-model="newMessage"
        @keypress.enter="sendMessage"
        placeholder="Type your message..."
        :disabled="!isConnected"
      />
      <button
        @click="sendMessage"
        :disabled="!isConnected || !newMessage.trim()"
      >
        Send
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: "ChatApp",
  data() {
    return {
      websocket: null,
      isConnected: false,
      messages: [],
      newMessage: "",
      username: "",
      tempUsername: "",
    };
  },
  async mounted() {
    await this.connectWebSocket();
  },
  beforeUnmount() {
    if (this.websocket) {
      this.websocket.close();
    }
  },
  methods: {
    async connectWebSocket() {
      try {
        // Get WebSocket URL from the API endpoint
        const response = await fetch(
          `${window.location.origin}/api/getwebsocketurl`
        );

        let wsUrl;
        if (response.ok) {
          try {
            // Try to get the URL from response text first (since API returns plain text)
            const text = await response.text();
            wsUrl = text.trim();
          } catch (textError) {
            try {
              // If text parsing fails, try JSON as fallback
              const data = await response.json();
              wsUrl = data.url;
            } catch (jsonError) {
              console.error(
                "Failed to parse response as text or JSON:",
                jsonError
              );
            }
          }
        }

        // If no URL from API, construct it based on current protocol
        if (!wsUrl) {
          const protocol =
            window.location.protocol === "https:" ? "wss:" : "ws:";
          wsUrl = `${protocol}//${window.location.host}/ws`;
        }

        // Ensure we use the correct protocol for secure connections
        if (window.location.protocol === "https:" && wsUrl.startsWith("ws:")) {
          wsUrl = wsUrl.replace("ws:", "wss:");
        }

        console.log("Connecting to WebSocket:", wsUrl);
        console.log("Current protocol:", window.location.protocol);
        console.log("Current host:", window.location.host);

        this.websocket = new WebSocket(wsUrl);

        this.websocket.onopen = () => {
          this.isConnected = true;
          console.log("WebSocket connected");
        };

        this.websocket.onmessage = async (event) => {
          try {
            let messageData;

            // Handle blob data
            if (event.data instanceof Blob) {
              const text = await event.data.text();
              messageData = text;
            } else {
              messageData = event.data;
            }

            // Try to parse as JSON first
            try {
              const data = JSON.parse(messageData);
              this.addMessage(
                data.message || data.text,
                false,
                data.username || "Anonymous"
              );
            } catch (jsonError) {
              // Handle plain text messages
              this.addMessage(messageData, false, "System");
            }
          } catch (error) {
            console.error("Error processing WebSocket message:", error);
            this.addMessage("Error processing message", false, "System");
          }
        };

        this.websocket.onclose = () => {
          this.isConnected = false;
          console.log("WebSocket disconnected");
          // Attempt to reconnect after 3 seconds
          setTimeout(() => {
            this.connectWebSocket();
          }, 3000);
        };

        this.websocket.onerror = (error) => {
          console.error("WebSocket error:", error);
          console.error("WebSocket URL that failed:", wsUrl);
          this.isConnected = false;

          // If it's a security error, try with the same origin
          if (error.message && error.message.includes("insecure")) {
            console.log("Attempting fallback connection to same origin...");
            setTimeout(() => {
              this.connectWebSocketFallback();
            }, 1000);
          }
        };
      } catch (error) {
        console.error("Failed to get WebSocket URL:", error);
        // Fallback to direct WebSocket connection with correct protocol
        const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
        const wsUrl = `${protocol}//${window.location.host}/ws`;
        console.log("Using fallback WebSocket URL:", wsUrl);
        this.websocket = new WebSocket(wsUrl);

        this.websocket.onopen = () => {
          this.isConnected = true;
          console.log("WebSocket connected (fallback)");
        };

        this.websocket.onmessage = async (event) => {
          try {
            let messageData;

            // Handle blob data
            if (event.data instanceof Blob) {
              const text = await event.data.text();
              messageData = text;
            } else {
              messageData = event.data;
            }

            // Try to parse as JSON first
            try {
              const data = JSON.parse(messageData);
              this.addMessage(
                data.message || data.text,
                false,
                data.username || "Anonymous"
              );
            } catch (jsonError) {
              // Handle plain text messages
              this.addMessage(messageData, false, "System");
            }
          } catch (error) {
            console.error("Error processing WebSocket message:", error);
            this.addMessage("Error processing message", false, "System");
          }
        };

        this.websocket.onclose = () => {
          this.isConnected = false;
          console.log("WebSocket disconnected (fallback)");
          // Attempt to reconnect after 3 seconds
          setTimeout(() => {
            this.connectWebSocket();
          }, 3000);
        };

        this.websocket.onerror = (error) => {
          console.error("WebSocket error (fallback):", error);
          this.isConnected = false;
        };
      }
    },

    connectWebSocketFallback() {
      try {
        const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
        const wsUrl = `${protocol}//${window.location.host}/ws`;
        console.log("Attempting fallback WebSocket connection:", wsUrl);

        this.websocket = new WebSocket(wsUrl);

        this.websocket.onopen = () => {
          this.isConnected = true;
          console.log("WebSocket connected (fallback)");
        };

        this.websocket.onmessage = async (event) => {
          try {
            let messageData;

            // Handle blob data
            if (event.data instanceof Blob) {
              const text = await event.data.text();
              messageData = text;
            } else {
              messageData = event.data;
            }

            // Try to parse as JSON first
            try {
              const data = JSON.parse(messageData);
              this.addMessage(
                data.message || data.text,
                false,
                data.username || "Anonymous"
              );
            } catch (jsonError) {
              // Handle plain text messages
              this.addMessage(messageData, false, "System");
            }
          } catch (error) {
            console.error("Error processing WebSocket message:", error);
            this.addMessage("Error processing message", false, "System");
          }
        };

        this.websocket.onclose = () => {
          this.isConnected = false;
          console.log("WebSocket disconnected (fallback)");
          // Attempt to reconnect after 3 seconds
          setTimeout(() => {
            this.connectWebSocket();
          }, 3000);
        };

        this.websocket.onerror = (error) => {
          console.error("WebSocket error (fallback):", error);
          this.isConnected = false;
        };
      } catch (error) {
        console.error("Fallback WebSocket connection failed:", error);
      }
    },

    setUsername() {
      if (this.tempUsername.trim()) {
        this.username = this.tempUsername.trim();
        this.tempUsername = "";
      }
    },

    sendMessage() {
      if (!this.newMessage.trim() || !this.isConnected || !this.username)
        return;

      const message = {
        text: this.newMessage,
        username: this.username,
        timestamp: new Date(),
      };

      // Send message through WebSocket
      if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
        this.websocket.send(JSON.stringify(message));
      }

      // Add message to local messages array
      this.addMessage(this.newMessage, true, this.username);

      // Clear input
      this.newMessage = "";
    },

    addMessage(text, isOwn, username) {
      const message = {
        id: Date.now() + Math.random(),
        text,
        isOwn,
        username,
        timestamp: new Date(),
      };

      this.messages.push(message);

      // Scroll to bottom
      this.$nextTick(() => {
        const container = this.$refs.messagesContainer;
        container.scrollTop = container.scrollHeight;
      });
    },

    formatTime(timestamp) {
      return timestamp.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      });
    },
  },
};
</script>

<style scoped>
.chat-container {
  width: 100%;
  max-width: 800px;
  height: 600px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

/* Username Modal */
.username-modal {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  border-radius: 12px;
}

.username-modal-content {
  background: white;
  padding: 40px;
  border-radius: 16px;
  text-align: center;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
  max-width: 400px;
  width: 90%;
}

.username-modal-content h2 {
  color: #333;
  margin-bottom: 16px;
  font-size: 24px;
  font-weight: 600;
}

.username-modal-content p {
  color: #666;
  margin-bottom: 24px;
  font-size: 16px;
}

.username-modal-content input {
  width: 100%;
  padding: 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  font-size: 16px;
  margin-bottom: 20px;
  outline: none;
  transition: border-color 0.2s;
}

.username-modal-content input:focus {
  border-color: #667eea;
}

.username-modal-content button {
  width: 100%;
  padding: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s, opacity 0.2s;
}

.username-modal-content button:hover:not(:disabled) {
  transform: translateY(-2px);
}

.username-modal-content button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.chat-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-header h1 {
  font-size: 24px;
  font-weight: 600;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.username {
  font-size: 14px;
  font-weight: 500;
  background: rgba(255, 255, 255, 0.2);
  padding: 6px 12px;
  border-radius: 16px;
}

.connection-status {
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}

.connection-status.connected {
  background: rgba(76, 175, 80, 0.2);
  color: #4caf50;
}

.connection-status.disconnected {
  background: rgba(244, 67, 54, 0.2);
  color: #f44336;
}

.chat-messages {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  background: #fafafa;
}

.message {
  margin-bottom: 16px;
  display: flex;
  flex-direction: column;
}

.message.own-message {
  align-items: flex-end;
}

.message-content {
  max-width: 70%;
  padding: 12px 16px;
  border-radius: 18px;
  word-wrap: break-word;
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.own-message .message-content {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.message-time {
  font-size: 11px;
  color: #666;
  margin-top: 4px;
  padding: 0 8px;
}

.chat-input {
  padding: 20px;
  background: white;
  border-top: 1px solid #eee;
  display: flex;
  gap: 12px;
}

.chat-input input {
  flex: 1;
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 24px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.chat-input input:focus {
  border-color: #667eea;
}

.chat-input input:disabled {
  background: #f5f5f5;
  color: #999;
}

.chat-input button {
  padding: 12px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 24px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: transform 0.2s, opacity 0.2s;
}

.chat-input button:hover:not(:disabled) {
  transform: translateY(-1px);
}

.chat-input button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* Scrollbar styling */
.chat-messages::-webkit-scrollbar {
  width: 6px;
}

.chat-messages::-webkit-scrollbar-track {
  background: #f1f1f1;
}

.chat-messages::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style>
