# Seguente Chat 

A simple Vue.js chat application with WebSocket communication, branded with 'Seguente'.

## Features

- Real-time messaging via WebSocket
- Clean, modern UI with gradient design
- Connection status indicator
- Auto-reconnection on disconnect
- Responsive design
- Message timestamps
- User identification

## Setup

1. Install dependencies:

```bash
yarn install
```

2. Start development server:

```bash
yarn serve
```

3. Build for production:

```bash
yarn build
```

## WebSocket Integration

The app connects to WebSocket using the `/api/getwebsocketurl` endpoint to get the WebSocket URL, then connects using the same origin (`window.location.origin`).

## Project Structure

- `src/App.vue` - Main application component
- `src/components/ChatApp.vue` - Main chat interface with WebSocket logic
- `src/main.js` - Vue application entry point
- `public/index.html` - HTML template
- `.taubyte/build.sh` - Build script for Taubyte deployment

## Dependencies

- Vue 3
- Vue CLI Service
- No additional UI libraries (pure CSS styling)
