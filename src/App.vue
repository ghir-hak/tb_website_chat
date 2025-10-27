<template>
  <div id="app">
    <ChatApp />
  </div>
</template>

<script>
import ChatApp from './components/ChatApp.vue'

export default {
  name: 'App',
  components: {
    ChatApp
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background-color: #f5f5f5;
}

#app {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
