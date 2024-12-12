import { Socket } from "phoenix"

export const initChat = () => {
  const socket = new Socket("/socket", {})
  socket.connect()

  // Chat room functionality
  const roomId = document.querySelector('#chat-container')?.dataset.roomId
  if (!roomId) return

  const username = localStorage.getItem('chat_username') || 
    prompt("Please enter your username:", "User_" + Math.random().toString(36).substr(2, 5))
  localStorage.setItem('chat_username', username)

  // Join the room channel
  const roomChannel = socket.channel(`room:${roomId}`, {})
  
  roomChannel.join()
    .receive("ok", response => {
      console.log("Joined room successfully", response)
      displayExistingMessages(response.messages)
    })
    .receive("error", resp => console.log("Unable to join room", resp))

  // Handle new messages
  roomChannel.on("new_message", payload => {
    appendMessage(payload)
  })

  // Send message functionality
  const messageForm = document.getElementById('message-form')
  const messageInput = document.getElementById('message-input')

  messageForm?.addEventListener('submit', (e) => {
    e.preventDefault()
    const content = messageInput.value.trim()
    if (content === '') return

    roomChannel.push("new_message", {
      content: content,
      username: username
    })
      .receive("ok", () => {
        messageInput.value = ''
      })
      .receive("error", (errors) => {
        console.error("Failed to send message", errors)
      })
  })
}

function displayExistingMessages(messages) {
  const container = document.getElementById('messages-container')
  if (!container) return

  messages.forEach(message => {
    appendMessage(message)
  })
  scrollToBottom()
}

function appendMessage(message) {
  const container = document.getElementById('messages-container')
  if (!container) return

  const messageDiv = document.createElement('div')
  messageDiv.className = 'message'
  messageDiv.innerHTML = `
    <span class="username">${escapeHtml(message.username)}:</span>
    <span class="content">${escapeHtml(message.content)}</span>
    <span class="timestamp">${formatTimestamp(message.inserted_at)}</span>
  `
  container.appendChild(messageDiv)
  scrollToBottom()
}

function scrollToBottom() {
  const container = document.getElementById('messages-container')
  if (container) {
    container.scrollTop = container.scrollHeight
  }
}

function formatTimestamp(timestamp) {
  return new Date(timestamp).toLocaleTimeString()
}

function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
}
